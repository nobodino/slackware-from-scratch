#!/bin/sh
#
# /etc/rc.d/rc.S:  System initialization script.
#
# Mostly written by:  Patrick J. Volkerding, <volkerdi@slackware.com>
#

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin

# Try to mount /proc:
/sbin/mount -v proc /proc -n -t proc 2> /dev/null

# Mount sysfs next, if the kernel supports it:
if [ -d /sys ]; then
  if grep -wq sysfs /proc/filesystems ; then
    if ! grep -wq sysfs /proc/mounts ; then
      /sbin/mount -v sysfs /sys -n -t sysfs
    fi
  fi
fi

# If /run exists, mount a tmpfs on it (unless the
# initrd has already done so):
if [ -d /run ]; then
  if ! grep -wq "tmpfs /run tmpfs" /proc/mounts ; then
    /sbin/mount -v -n -t tmpfs tmpfs /run -o mode=0755,size=32M,nodev,nosuid,noexec
  fi
  # Make sure that mounts below /run are visible in both /run and /var/run:
  /sbin/mount --make-shared /run
fi

# Load the loop device kernel module:
if [ -x /etc/rc.d/rc.loop ]; then
  /etc/rc.d/rc.loop start
fi

# Initialize udev to manage /dev entries and hotplugging.
# You may turn off udev by making the /etc/rc.d/rc.udev file non-executable
# or giving the "nohotplug" option at boot, but realize that if you turn off
# udev that you will have to load all the kernel modules that you need
# yourself (possibly in /etc/rc.d/rc.modules.local), and make any additional
# device nodes that you need in the /dev directory.  Even USB and IEEE1394
# devices will need to have the modules loaded by hand if udev is not used.
# So use it.  :-)
if grep -wq sysfs /proc/mounts && grep -q devtmpfs /proc/filesystems ; then
  if ! grep -wq nohotplug /proc/cmdline ; then
    if [ -x /etc/rc.d/rc.udev ]; then
      /etc/rc.d/rc.udev start
    fi
  fi
fi

# Mount Control Groups filesystem interface:
if grep -wq cgroup /proc/filesystems ; then
  if [ -d /sys/fs/cgroup ]; then
    # See linux-*/Documentation/cgroups/cgroups.txt (section 1.6)
    # Check if we have some tools to autodetect the available cgroup controllers
    if [ -x /bin/cut -a -x /bin/tail ]; then
      # Mount a tmpfs as the cgroup filesystem root
      mount -t tmpfs -o mode=0755,size=8M cgroup_root /sys/fs/cgroup
      # Autodetect available controllers and mount them in subfolders
      controllers="$(/bin/cut -f 1 /proc/cgroups | /bin/tail -n +2)"
      for i in $controllers; do
        mkdir /sys/fs/cgroup/$i
        mount -t cgroup -o $i $i /sys/fs/cgroup/$i
      done
      unset i controllers
    else
      # We can't use autodetection so fall back mounting them all together
      mount -t cgroup cgroup /sys/fs/cgroup
    fi
  else
    mkdir -p /dev/cgroup
    mount -t cgroup cgroup /dev/cgroup
  fi
fi

# Initialize the Logical Volume Manager.
# This won't start unless we find /etc/lvmtab (LVM1) or
# /etc/lvm/backup/ (LVM2).  This is created by /sbin/vgscan, so to
# use LVM you must run /sbin/vgscan yourself the first time (and
# create some VGs and LVs).
# Create LVM lock/run directories:
mkdir -p -m 0700 /run/lvm /run/lock /run/lock/lvm
if [ -r /etc/lvmtab -o -d /etc/lvm/backup ]; then
  echo "Initializing LVM (Logical Volume Manager):"
  # Check for device-mapper support.
  if ! grep -wq device-mapper /proc/devices ; then
    # Try to load a device-mapper kernel module:
    /sbin/modprobe -q dm-mod
  fi
  # Scan for new volume groups:
  /sbin/vgscan --mknodes --ignorelockingfailure 2> /dev/null
  if [ $? = 0 ]; then
    # Make volume groups available to the kernel.
    # This should also make logical volumes available.
    /sbin/vgchange -ay --ignorelockingfailure
  fi
fi

# Open any volumes created by cryptsetup.
#
# Some notes on /etc/crypttab in Slackware:
# Only LUKS formatted volumes are supported (except for swap)
# crypttab follows the following format:
# <luks_name> <device> <password> <options>
#
# <luks_name>:  This is the name of your LUKS volume.
# For example:  crypt-home
#
# <device>:  This is the device containing your LUKS volume.
# For example:  /dev/sda2
#
# <password>:  This is either the volume password in plain text, or the name of
# a key file.  Use 'none' to interactively enter password on boot.
#
# <options>:  Comma-separated list of options.  Note that there must be a
# password field for any options to be picked up (use a password of 'none' to
# get a password prompt at boot).  The following options are supported:
#
# discard -- this will cause --allow-discards to be passed to the cryptsetup
# program while opening the LUKS volume.
#
# ro -- this will cause --readonly to be passed to the cryptsetup program while
# opening the LUKS volume.
#
# swap -- this option cannot be used with other options.  The device given will
# be formatted as a new encrypted volume with a random key on boot, and used as
# swap.
#
if [ -f /etc/crypttab -a -x /sbin/cryptsetup ]; then
  # First, check for device-mapper support.
  if ! grep -wq device-mapper /proc/devices ; then
    # If device-mapper exists as a module, try to load it.
    # Try to load a device-mapper kernel module:
    /sbin/modprobe -q dm-mod
  fi
  # NOTE: we only support LUKS formatted volumes (except for swap)!
  cat /etc/crypttab | grep -v "^#" | grep -v "^$" | while read line; do
    eval LUKSARRAY=( $line )
    LUKS="${LUKSARRAY[0]}"
    DEV="${LUKSARRAY[1]}"
    PASS="${LUKSARRAY[2]}"
    OPTS="${LUKSARRAY[3]}"
    LUKSOPTS=""
    if echo $OPTS | grep -wq ro ; then LUKSOPTS="${LUKSOPTS} --readonly" ; fi
    if echo $OPTS | grep -wq discard ; then LUKSOPTS="${LUKSOPTS} --allow-discards" ; fi
    # Skip LUKS volumes that were already unlocked (in the initrd):
    /sbin/cryptsetup status $LUKS 2>/dev/null | head -n 1 | grep -q "is active" && continue
    if /sbin/cryptsetup isLuks $DEV 2>/dev/null ; then
      if [ -z "${LUKSOPTS}" ]; then
        echo "Unlocking LUKS encrypted volume '${LUKS}' on device '$DEV':"
      else
        echo "Unlocking LUKS encrypted volume '${LUKS}' on device '$DEV' with options '${LUKSOPTS}':"
      fi
      if [ -n "${PASS}" -a "${PASS}" != "none" ]; then
        if [ -f "${PASS}" ]; then
          # A password was given a key-file filename
          /sbin/cryptsetup ${LUKSOPTS} --key-file=${PASS} luksOpen $DEV $LUKS
        else
          # A password was provided in plain text
          echo "${PASS}" | /sbin/cryptsetup ${LUKSOPTS} luksOpen $DEV $LUKS
        fi
      else
        # No password was given, or a password of 'none' was given
        /sbin/cryptsetup ${LUKSOPTS} luksOpen $DEV $LUKS </dev/tty0 >/dev/tty0 2>&1
      fi
    elif echo $OPTS | grep -wq swap ; then
      # If any of the volumes is to be used as encrypted swap,
      # then encrypt it using a random key and run mkswap:
      echo "Creating encrypted swap volume '${LUKS}' on device '$DEV':"
      /sbin/cryptsetup --cipher=aes --key-file=/dev/urandom --key-size=256 create $LUKS $DEV
      mkswap /dev/mapper/$LUKS
    fi
  done
fi

# Enable swapping:
/sbin/swapon -a 2> /dev/null

# Set the tick and frequency for the system clock.
# Default values are: TICK=10000 and FREQ=0
TICK=10000
FREQ=0
# If there's a /etc/default/adjtimex config file, source it to override
# the default TICK and FREQ:
if [ -r /etc/default/adjtimex ]; then
  . /etc/default/adjtimex
fi
if /sbin/adjtimex --tick $TICK --frequency $FREQ; then
  echo "Setting the system clock rate:  /sbin/adjtimex --tick $TICK --frequency $FREQ"
else
  echo "Failed to set system clock with adjtimex, possibly invalid parameters? (TICK=$TICK FREQ=$FREQ)"
fi

# Set the system time from the hardware clock using hwclock --hctosys.
if [ -x /sbin/hwclock ]; then
  # Check for a broken motherboard RTC clock (where ioports for rtc are
  # unknown) to prevent hwclock causing a hang:
  if ! grep -q " : rtc" /proc/ioports ; then
    CLOCK_OPT="--directisa"
  fi
  if [ /etc/adjtime -nt /etc/hardwareclock ]; then
    if grep -q "^LOCAL" /etc/adjtime ; then
      echo -n "Setting system time from the hardware clock (localtime):  "
    else
      echo -n "Setting system time from the hardware clock (UTC):  "
    fi
    /sbin/hwclock $CLOCK_OPT --hctosys
  elif grep -wq "^localtime" /etc/hardwareclock 2> /dev/null ; then
    echo -n "Setting system time from the hardware clock (localtime):  "
    /sbin/hwclock $CLOCK_OPT --localtime --hctosys
  else
    echo -n "Setting system time from the hardware clock (UTC):  "
    /sbin/hwclock $CLOCK_OPT --utc --hctosys
  fi
  date
fi

# Test to see if the root partition is read-only, like it ought to be.
READWRITE=no
if touch /fsrwtestfile 2>/dev/null; then
  rm -f /fsrwtestfile
  READWRITE=yes
else
  echo "Testing root filesystem status:  read-only filesystem"
fi

# See if a forced filesystem check was requested at shutdown:
if [ -r /etc/forcefsck ]; then
  FORCEFSCK="-f"
fi

# If we're using F2FS for the root filesystem, don't check it as it doesn't
# allow checking a read-only filesystem:
if grep -q ' / f2fs ' /proc/mounts ; then
  echo "Remounting root device with read-write enabled."
  /sbin/mount -w -v -n -o remount /
elif [ ! $READWRITE = yes ]; then
  # Check the root filesystem:
  RETVAL=0
  if [ ! -r /etc/fastboot ]; then
    echo "Checking root filesystem:"
    /sbin/fsck $FORCEFSCK -C -a /
    RETVAL=$?
  fi
  # An error code of 2 or higher will require a reboot.
  if [ $RETVAL -ge 2 ]; then
    # An error code equal to or greater than 4 means that some errors
    # could not be corrected.  This requires manual attention, so we
    # offer a chance to try to fix the problem in single-user mode:
    if [ $RETVAL -ge 4 ]; then
      echo
      echo "***********************************************************"
      echo "*** An error occurred during the root filesystem check. ***"
      echo "*** You will now be given a chance to log into the      ***"
      echo "*** system in single-user mode to fix the problem.      ***"
      echo "***                                                     ***"
      echo "*** If you are using the ext2 filesystem, running       ***"
      echo "*** 'e2fsck -v -y <partition>' might help.              ***"
      echo "***********************************************************"
      echo
      echo "Once you exit the single-user shell, the system will reboot."
      echo
      PS1="(Repair filesystem) \#"; export PS1
      sulogin
    else # With an error code of 2 or 3, reboot the machine automatically:
      echo
      echo "***********************************"
      echo "*** The filesystem was changed. ***"
      echo "*** The system will now reboot. ***"
      echo "***********************************"
      echo
    fi
    echo "Unmounting file systems."
    /sbin/umount -a -r
    /sbin/mount -n -o remount,ro /
    echo "Rebooting system."
    reboot -f
  fi
  # Remount the root filesystem in read-write mode
  echo "Remounting root device with read-write enabled."
  /sbin/mount -w -v -n -o remount /
  if [ $? -gt 0 ] ; then
    echo "FATAL:  Attempt to remount root device as read-write failed!  This is going to"
    echo "cause serious problems."
  fi
else
  echo "Testing root filesystem status:  read-write filesystem"
  echo
  echo "ERROR: Root partition has already been mounted read-write. Cannot check!"
  echo
  echo "For filesystem checking to work properly, your system must initially mount"
  echo "the root partition as read only.  If you're booting with LILO, add a line:"
  echo
  echo "   read-only"
  echo
  echo "to the Linux section in your /etc/lilo.conf and type 'lilo' to reinstall it."
fi # Done checking root filesystem

# If /etc/mtab is a symlink (probably to /proc/mounts) then we don't want to mess with it.
if [ ! -L /etc/mtab -o ! -r /etc/mtab ]; then
  # /etc/mtab is a file (or doesn't exist), so we'll handle it the old way:
  # Any /etc/mtab that exists here is old, so we start with a new one:
  /bin/rm -f /etc/mtab{,~,.tmp} && /bin/touch /etc/mtab
  # Add /, /proc, /sys, and /dev/shm mounts to /etc/mtab:
  /sbin/mount -f -w /
  if [ -d /proc/sys ]; then
    /sbin/mount -f -t proc proc /proc
  fi
  if [ -d /sys/bus ]; then
    /sbin/mount -f -t sysfs sysfs /sys
  fi
  if grep -q '^[^ ]\+ /dev/shm ' /proc/mounts 2> /dev/null ; then
    /sbin/mount -f -t tmpfs tmpfs /dev/shm
  fi
fi

# Configure ISA Plug-and-Play devices:
if [ -r /etc/isapnp.conf ]; then
  if [ -x /sbin/isapnp ]; then
    /sbin/isapnp /etc/isapnp.conf
  fi
fi

# Run the kernel module script.  This updates the module dependencies and
# also supports manually loading kernel modules through rc.modules.local.
if [ -x /etc/rc.d/rc.modules ]; then
  /etc/rc.d/rc.modules
fi

# Configure kernel parameters:
if [ -x /sbin/sysctl -a -r /etc/sysctl.conf ]; then
  echo "Configuring kernel parameters:  /sbin/sysctl -e --system"
  /sbin/sysctl -e --system
elif [ -x /sbin/sysctl  ]; then
  echo "Configuring kernel parameters:  /sbin/sysctl -e --system"
  # Don't say "Applying /etc/sysctl.conf" or complain if the file doesn't exist
  /sbin/sysctl -e --system 2> /dev/null | grep -v "Applying /etc/sysctl.conf"
fi

# Check all the non-root filesystems:
if [ ! -r /etc/fastboot ]; then
  echo "Checking non-root filesystems:"
  /sbin/fsck $FORCEFSCK -C -R -A -a
fi

# Mount usbfs only if it is found in /etc/fstab:
if grep -wq usbfs /proc/filesystems; then
  if ! grep -wq usbfs /proc/mounts ; then
    if grep -wq usbfs /etc/fstab; then
      /sbin/mount -v /proc/bus/usb
    fi
  fi
fi

# Mount non-root file systems in fstab, but not NFS or SMB 
# because TCP/IP is not yet configured, and not proc or sysfs
# because those have already been mounted.  Also check that
# devpts is not already mounted before attempting to mount
# it.  With a 2.6.x or newer kernel udev mounts devpts.
echo "Mounting non-root local filesystems:"
if /bin/grep -wq devpts /proc/mounts ; then
  # This pipe after the mount command is just to convert the new
  # mount verbose output back to the old format that contained
  # more useful information:
  /sbin/mount -a -v -t nonfs,nosmbfs,nocifs,noproc,nosysfs,nodevpts | grep successfully | cut -f 1 -d : | tr -d ' ' | while read dev ; do mount | grep " ${dev} " ; done
else
  /sbin/mount -a -v -t nonfs,nosmbfs,nocifs,noproc,nosysfs | grep successfully | cut -f 1 -d : | tr -d ' ' | while read dev ; do mount | grep " ${dev} " ; done
fi

# This should be empty as it's just a mountpoint now:
rm -rf /var/run/*
# Bind mount /run to /var/run:
mount -o bind /run /var/run

# Enable swapping again.  This is needed in case a swapfile is used,
# as it can't be enabled until the filesystem it resides on has been
# mounted read-write.
/sbin/swapon -a 2> /dev/null

# Start libcgroup services:
if [ -x /etc/rc.d/rc.cgconfig -a -x /etc/rc.d/rc.cgred -a -d /sys/fs/cgroup ]; then
  /etc/rc.d/rc.cgconfig start ; echo " /usr/sbin/cgconfigparser -l /etc/cgconfig.conf"
  /etc/rc.d/rc.cgred start
fi

# Clean up some temporary files:
rm -f /etc/nologin /etc/dhcpc/*.pid /etc/forcefsck /etc/fastboot \
  /var/state/saslauthd/saslauthd.pid /tmp/.Xauth* 1> /dev/null 2> /dev/null
rm -rf /tmp/{kde-[a-zA-Z]*,ksocket-[a-zA-Z]*,hsperfdata_[a-zA-Z]*,plugtmp*}
if [ -d /var/lib/pkgtools/setup/tmp ]; then
  ( cd /var/lib/pkgtools/setup/tmp && rm -rf * )
elif [ -d /var/log/setup/tmp ]; then
  ( cd /var/log/setup/tmp && rm -rf * )
fi

# Clear /var/lock/subsys:
if [ -d /var/lock/subsys ]; then
  rm -f /var/lock/subsys/*
fi

# Create /tmp/{.ICE-unix,.X11-unix} if they are not present:
if [ ! -e /tmp/.ICE-unix ]; then
  mkdir -p /tmp/.ICE-unix
  chmod 1777 /tmp/.ICE-unix
fi
if [ ! -e /tmp/.X11-unix ]; then
  mkdir -p /tmp/.X11-unix
  chmod 1777 /tmp/.X11-unix
fi

# Create a fresh utmp file:
touch /var/run/utmp
chown root:utmp /var/run/utmp
chmod 664 /var/run/utmp

# In case pam_faillock(8) is being used, create the tally directory:
mkdir -p /var/run/faillock

# Update the current kernel level in the /etc/motd (Message Of The Day) file,
# if the first line of that file begins with the word 'Linux'.
# You are free to modify the rest of the file as you see fit.
if [ -x /bin/sed ]; then
  /bin/sed -i "{1s/^Linux.*/$(/bin/uname -sr)\./}" /etc/motd
fi

# If there are SystemV init scripts for this runlevel, run them.
if [ -x /etc/rc.d/rc.sysvinit ]; then
  /etc/rc.d/rc.sysvinit
fi

# Run serial port setup script:
# CAREFUL!  This can make some systems hang if the rc.serial script isn't
# set up correctly.  If this happens, you may have to edit the file from a
# boot disk, and/or set it as non-executable:
if [ -x /etc/rc.d/rc.serial ]; then
  /etc/rc.d/rc.serial start
fi

# Carry an entropy pool between reboots to improve randomness.
if [ -f /etc/random-seed ]; then
  echo "Using /etc/random-seed to initialize /dev/urandom."
  cat /etc/random-seed > /dev/urandom
fi
# Use the pool size from /proc, or 4096 bits:
if [ -r /proc/sys/kernel/random/poolsize ]; then
  dd if=/dev/urandom of=/etc/random-seed count=1 bs=$(expr $(cat /proc/sys/kernel/random/poolsize) / 8) 2> /dev/null
else
  dd if=/dev/urandom of=/etc/random-seed count=1 bs=512 2> /dev/null
fi
chmod 600 /etc/random-seed
