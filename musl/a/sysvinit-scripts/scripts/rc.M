#!/bin/sh
#
# rc.M		This file is executed by init(8) when the system is being
#		initialized for one of the "multi user" run levels (i.e.
#		levels 1 through 6).  It usually does mounting of file
#		systems et al.
#
# Version:	@(#)/etc/rc.d/rc.M	2.23	Wed Feb 26 19:20:58 PST 2003
#
# Author:	Fred N. van Kempen, <waltje@uwalt.nl.mugnet.org>
#		Heavily modified by Patrick Volkerding <volkerdi@slackware.com>
#

# Tell the viewers what's going to happen.
echo "Going multiuser..."

# Update all the shared library links:
if [ -x /sbin/ldconfig ]; then
  echo "Updating shared library links:  /sbin/ldconfig &"
  /sbin/ldconfig &
fi

# Call the setterm init script to set screen blanking and power management
# defaults:
if [ -x /etc/rc.d/rc.setterm ]; then
  /etc/rc.d/rc.setterm
fi

# Set the hostname.
if [ -r /etc/HOSTNAME ]; then
  /bin/hostname $(cat /etc/HOSTNAME)
else
  # fall back on this old default:
  echo "darkstar.example.net" > /etc/HOSTNAME
  /bin/hostname $(cat /etc/HOSTNAME)
fi

# Set the permissions on /var/log/dmesg according to whether the kernel
# permits non-root users to access kernel dmesg information:
if [ -r /proc/sys/kernel/dmesg_restrict ]; then
  if [ $(cat /proc/sys/kernel/dmesg_restrict) = 1 ]; then
    touch /var/log/dmesg
    chmod 640 /var/log/dmesg
  fi
else
  touch /var/log/dmesg
  chmod 644 /var/log/dmesg
fi
# Save the contents of 'dmesg':
/bin/dmesg -s 65536 > /var/log/dmesg

# Initialize PCMCIA devices:
#
# NOTE: This used to be started near the top of rc.S so that PCMCIA devices
# could be fsck'ed along with the other drives.  This had some unfortunate
# side effects, however, since root isn't yet read-write, and /var might not
# even be mounted the .pid files can't be correctly written in /var/run and
# the pcmcia system can't be correctly shut down.  If you want some PCMCIA
# partition to be mounted at boot (or when the card is inserted) then add
# the appropriate lines to /etc/pcmcia/scsi.opts.
#
# Note that the stuff in /etc/pcmcia/ is only for 2.4.x kernels using
# 16-bit PCMCIA cards (not 32-bit Cardbus cards!).  For example, with a
# wireless card you might need to set options in /etc/pcmcia OR in
# /etc/rc.d/rc.wireless.conf, or even in /etc/rc.d/rc.inet1.conf (with
# extra options if needed for the encryption key, ESSID, etc.)
#
# Hopefully this situation will be unified in the future, but for now
# that's how it is...
#
if [ -x /etc/rc.d/rc.pcmcia ]; then
  /etc/rc.d/rc.pcmcia start
  # The cards might need a little extra time here to initialize.
  sleep 5
fi

# Start the system logger.
if [ -x /etc/rc.d/rc.syslog ]; then
  /etc/rc.d/rc.syslog start
fi

# Update the X font indexes:
if [ -x /usr/bin/fc-cache ]; then
  echo "Updating X font indexes:  /usr/bin/fc-cache -f &"
  /usr/bin/fc-cache -f &
fi

# Run rc.udev again.  This will start udev if it is not already running
# (for example, upon return from runlevel 1), otherwise it will trigger it
# to look for device changes and to generate persistent rules if needed.
if grep -wq sysfs /proc/mounts && grep -q devtmpfs /proc/filesystems ; then
  if ! grep -wq nohotplug /proc/cmdline ; then
    if [ -x /etc/rc.d/rc.udev ]; then
      /etc/rc.d/rc.udev start
    fi
  fi
fi

# Start the haveged entropy daemon:
if [ -x /etc/rc.d/rc.haveged ]; then
  /etc/rc.d/rc.haveged start
fi

# Start the rngd entropy daemon:
if [ -x /etc/rc.d/rc.rngd ]; then
  /etc/rc.d/rc.rngd start
fi

# Initialize the networking hardware.
if [ -x /etc/rc.d/rc.inet1 ]; then
  /etc/rc.d/rc.inet1
fi

# Start D-Bus:
if [ -x /etc/rc.d/rc.messagebus ]; then
  /etc/rc.d/rc.messagebus start
fi

# Start the session/seat daemon:
if [ -x /etc/rc.d/rc.elogind -a -x /bin/loginctl ]; then
  /etc/rc.d/rc.elogind start
elif [ -x /etc/rc.d/rc.consolekit -a -x /usr/sbin/console-kit-daemon ]; then
  /etc/rc.d/rc.consolekit start
fi

# Start Bluetooth:
if [ -x /etc/rc.d/rc.bluetooth ]; then
  /etc/rc.d/rc.bluetooth start
fi

# Start wicd or networkmanager:
if [ -x /etc/rc.d/rc.wicd -a -x /usr/sbin/wicd ]; then
  /etc/rc.d/rc.wicd start
elif [ -x /etc/rc.d/rc.networkmanager ]; then
  /etc/rc.d/rc.networkmanager start
fi

# Start networking daemons:
if [ -x /etc/rc.d/rc.inet2 ]; then
  /etc/rc.d/rc.inet2
fi

# Mount any additional filesystem types that haven't already been mounted:
mount -a -v 2> /dev/null | grep -v -e "already mounted" -e "ignored" | cut -f 1 -d : | tr -d ' ' | while read dev ; do mount | grep "${dev} " ; done

# Start the Control Script for automounter:
if [ -x /etc/rc.d/rc.autofs ]; then
  /etc/rc.d/rc.autofs start
fi

# Start the Network Time Protocol daemon:
if [ -x /etc/rc.d/rc.ntpd ]; then
  /etc/rc.d/rc.ntpd start
fi

# Remove stale locks and junk files (must be done after mount -a!)
/bin/rm -f /var/lock/* /var/spool/uucp/LCK..* /tmp/.X*lock /tmp/.X11-unix/* 2> /dev/null

# Remove stale hunt sockets so the game can start.
if [ -r /tmp/hunt -o -r /tmp/hunt.stats ]; then
  echo "Removing your stale hunt sockets from /tmp."
  /bin/rm -f /tmp/hunt*
fi

# Ensure basic filesystem permissions sanity.
chmod 755 / 2> /dev/null
chmod 1777 /tmp /var/tmp

# Start ACPI daemon.
if [ -x /etc/rc.d/rc.acpid ]; then
  /etc/rc.d/rc.acpid start
fi

# Enable CPU frequency scaling:
if [ -x /etc/rc.d/rc.cpufreq ]; then
  /etc/rc.d/rc.cpufreq start
fi

# Update any existing icon cache files:
if find /usr/share/icons -maxdepth 2 2> /dev/null | grep -q icon-theme.cache ; then
  for theme_dir in /usr/share/icons/* ; do
    if [ -r ${theme_dir}/icon-theme.cache ]; then
      echo "Updating icon-theme.cache in ${theme_dir}..."
      /usr/bin/gtk-update-icon-cache -t -f ${theme_dir} 1> /dev/null 2> /dev/null &
    fi
  done
  # This would be a large file and probably shouldn't be there.
  if [ -r /usr/share/icons/icon-theme.cache ]; then
    echo "Deleting icon-theme.cache in /usr/share/icons..."
    #/usr/bin/gtk-update-icon-cache -t -f /usr/share/icons 1> /dev/null 2> /dev/null &
    rm -f /usr/share/icons/icon-theme.cache
  fi
fi

# Update mime database:
if [ -x /usr/bin/update-mime-database -a -d /usr/share/mime ]; then
  echo "Updating MIME database:  /usr/bin/update-mime-database /usr/share/mime &"
  /usr/bin/update-mime-database /usr/share/mime 1> /dev/null 2> /dev/null &
fi

# Start HAL:
if [ -x /etc/rc.d/rc.hald ]; then
  /etc/rc.d/rc.hald start
fi

# Start system-wide PulseAudio daemon (not recommended, nor required in
# order to use PulseAudio -- see the script for details):
if [ -x /etc/rc.d/rc.pulseaudio ]; then
  /etc/rc.d/rc.pulseaudio start
fi

# These GTK+/pango files need to be kept up to date for
# proper input method, pixbuf loaders, and font support.
if [ -x /usr/bin/update-gtk-immodules ]; then
  echo "Updating gtk.immodules:"
  echo "  /usr/bin/update-gtk-immodules &"
  /usr/bin/update-gtk-immodules > /dev/null 2>&1 &
fi
if [ -x /usr/bin/update-gdk-pixbuf-loaders ]; then
  echo "Updating gdk-pixbuf.loaders:"
  echo "  /usr/bin/update-gdk-pixbuf-loaders &"
  HOME=/root /usr/bin/update-gdk-pixbuf-loaders > /dev/null 2>&1 &
fi
if [ -x /usr/bin/update-pango-querymodules ]; then
  echo "Updating pango.modules:"
  echo "  /usr/bin/update-pango-querymodules &"
  /usr/bin/update-pango-querymodules > /dev/null 2>&1 &
fi
if [ -x /usr/bin/glib-compile-schemas ]; then
  echo "Compiling GSettings XML schema files:"
  echo "  /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas &"
  /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas >/dev/null 2>&1 &
fi

# Start dnsmasq, a simple DHCP/DNS server:
if [ -x /etc/rc.d/rc.dnsmasq ]; then
  /etc/rc.d/rc.dnsmasq start
fi

# Start snmpd:
if [ -x /etc/rc.d/rc.snmpd ]; then
  /etc/rc.d/rc.snmpd start
fi

# Start the print spooling system.  This will usually be LPRng (lpd) or CUPS.
if [ -x /etc/rc.d/rc.cups ]; then
  # Start CUPS:
  /etc/rc.d/rc.cups start
elif [ -x /etc/rc.d/rc.lprng ]; then
  # Start LPRng (lpd):
  /etc/rc.d/rc.lprng start
fi

# Start netatalk. (a file/print server for Macs using Appletalk)
if [ -x /etc/rc.d/rc.atalk ]; then
  /etc/rc.d/rc.atalk start
fi

# Start smartd, which monitors the status of S.M.A.R.T. compatible
# hard drives and reports any problems:
if [ -x /etc/rc.d/rc.smartd ]; then
  /etc/rc.d/rc.smartd start
fi

# Monitor the UPS with genpowerd.
# To use this, uncomment this section and edit your settings in
# /etc/genpowerd.conf (serial device, UPS type, etc).  For more information,
# see "man genpowerd" or the extensive documentation in the
# /usr/doc/genpower-*/ directory.
# You'll also need to configure a similar block in /etc/rc.d/rc.6 if you want
# support for stopping the UPS's inverter after the machine halts.
#if [ -x /sbin/genpowerd ]; then
#  echo "Starting genpowerd daemon..."
#  /sbin/genpowerd
#fi

# Turn on process accounting.  To enable process accounting, make sure the
# option for BSD process accounting is enabled in your kernel, and then
# create the file /var/log/pacct (touch /var/log/pacct).  By default, process
# accounting is not enabled (since /var/log/pacct does not exist).  This is
# because the log file can get VERY large.
if [ -x /sbin/accton -a -r /var/log/pacct ]; then
  chmod 640 /var/log/pacct
  /sbin/accton /var/log/pacct
fi

# Start crond (Dillon's crond):
if [ -x /etc/rc.d/rc.crond ]; then
  /etc/rc.d/rc.crond start
fi

# Start atd (manages jobs scheduled with 'at'):
if [ -x /etc/rc.d/rc.atd ]; then
  /etc/rc.d/rc.atd start
fi

# Slackware-Mini-Quota-HOWTO:
# To really activate quotas, you'll need to add 'usrquota' and/or 'grpquota' to
# the appropriate partitions as listed in /etc/fstab.  Here's an example:
#
# /dev/hda2      /home      ext3     defaults,usrquota      1   1
#
# You'll then need to setup initial quota files at the top of the partitions
# to support quota, like this:
# touch /home/aquota.user /home/aquota.group
# chmod 600 /home/aquota.user /home/aquota.group
#
# Then, reboot to activate the system.
# To edit user quotas, use 'edquota'.  See 'man edquota'.  Also, the
# official Quota Mini-HOWTO has lots of useful information.  That can be found
# here:  /usr/doc/Linux-HOWTOs/Quota

# Check quotas and then turn quota system on:
if grep -q quota /etc/fstab ; then
  for quotafs in $(awk '/quota/ {print $2}' /etc/fstab) ; do
    /bin/rm -f $quotafs/{a,}quota.{group,user}.new
  done
  if [ -x /sbin/quotacheck ]; then
    echo "Checking filesystem quotas:  /sbin/quotacheck -avugm"
    /sbin/quotacheck -avugm
  fi
  if [ -x /sbin/quotaon ]; then
    echo "Activating filesystem quotas:  /sbin/quotaon -avug"
    /sbin/quotaon -avug
  fi
fi

# Start the SASL authentication server.  This provides SASL
# authentication services for sendmail/postfix:
if [ -x /etc/rc.d/rc.saslauthd ]; then
  /etc/rc.d/rc.saslauthd start
fi

# Start the mail server. Try the rc.sendmail script first, then try rc.postfix.
if [ -x /etc/rc.d/rc.sendmail -a -x usr/sbin/makemap ]; then
  /etc/rc.d/rc.sendmail start
elif [ -x /etc/rc.d/rc.postfix -a -x usr/sbin/postdrop ]; then
  /etc/rc.d/rc.postfix start
fi

# Load ALSA (sound) defaults:
if [ -x /etc/rc.d/rc.alsa ]; then
  /etc/rc.d/rc.alsa
fi

# Load a custom screen font if the user has an rc.font script.
if [ -x /etc/rc.d/rc.font ]; then
  /etc/rc.d/rc.font
fi

# Load a custom keymap if the user has an rc.keymap script.
if [ -x /etc/rc.d/rc.keymap ]; then
  /etc/rc.d/rc.keymap
fi

# Start the MySQL database:
if [ -x /etc/rc.d/rc.mysqld ]; then
  /etc/rc.d/rc.mysqld start
fi

# Start Apache web server:
if [ -x /etc/rc.d/rc.httpd ]; then
  /etc/rc.d/rc.httpd start
fi

# Start OpenLDAP:
if [ -x /etc/rc.d/rc.openldap ]; then
  /etc/rc.d/rc.openldap start
fi

# Start local LDAP name service daemon (from nss-pam-ldapd):
if [ -x /etc/rc.d/rc.nslcd ]; then
  /etc/rc.d/rc.nslcd start
fi

# Start Dovecot:
if [ -x /etc/rc.d/rc.dovecot ]; then
  /etc/rc.d/rc.dovecot start
fi

# Start Samba (a file/print server for Win95/NT machines).
# Samba can be started in /etc/inetd.conf instead.
if [ -x /etc/rc.d/rc.samba ]; then
  /etc/rc.d/rc.samba start
fi

# Start the GPM mouse server:
if [ -x /etc/rc.d/rc.gpm ]; then
  /etc/rc.d/rc.gpm start
fi

# Start the Icecream scheduler. This needs to run on only one machine that is
# part of the compile cluster:
if [ -x /etc/rc.d/rc.icecc-scheduler ]; then
  /etc/rc.d/rc.icecc-scheduler start
fi

# Start the Icecream daemon. This needs to run on every machine that will be
# part of the compile cluster (including the machine running the scheduler):
if [ -x /etc/rc.d/rc.iceccd ]; then
  /etc/rc.d/rc.iceccd start
fi

# If there are SystemV init scripts for this runlevel, run them.
if [ -x /etc/rc.d/rc.sysvinit ]; then
  /etc/rc.d/rc.sysvinit
fi

# Start the local setup procedure.
if [ -x /etc/rc.d/rc.local ]; then
  /etc/rc.d/rc.local
fi

# All done.
