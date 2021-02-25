#! /bin/sh
#
# rc.K 		This file is executed by init when it goes into runlevel
#		1, which is the administrative state. It kills all
#		daemons and then puts the system into single user mode.
#		Note that the file systems are kept mounted.
#
# Version:	@(#)/etc/rc.d/rc.K	3.1415 Sat Jan 13 13:37:26 PST 2001
#
# Author:	Miquel van Smoorenburg <miquels@drinkel.nl.mugnet.org>
# Modified by:  Patrick J. Volkerding <volkerdi@slackware.com>
#

# Set the path.
PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin

# Load a custom screen font if the user has an rc.font script.
if [ -x /etc/rc.d/rc.font ]; then
  /etc/rc.d/rc.font
fi

# Load any needed keyboard mappings:
if [ -x /etc/rc.d/rc.keymap ]; then
  /etc/rc.d/rc.keymap
fi

# If there are SystemV init scripts for this runlevel, run them.
if [ -x /etc/rc.d/rc.sysvinit ]; then
  /etc/rc.d/rc.sysvinit
fi

# Try to turn off quota:
if grep -q quota /etc/fstab ; then
  if [ -x /sbin/quotaoff ]; then
    echo "Turning off filesystem quotas."
    /sbin/quotaoff -a
  fi
fi

# Try to turn off accounting:
if [ -x /sbin/accton -a -r /var/log/pacct ]; then
  /sbin/accton off
fi

# Run any local shutdown scripts:
if [ -x /etc/rc.d/rc.local_shutdown ]; then
  /etc/rc.d/rc.local_shutdown stop
fi

# Stop the Apache web server:
if [ -x /etc/rc.d/rc.httpd ]; then
  /etc/rc.d/rc.httpd stop
fi

# Stop the Samba server:
if [ -x /etc/rc.d/rc.samba ]; then
  /etc/rc.d/rc.samba stop
fi

# Shut down the NFS server:
if [ -x /etc/rc.d/rc.nfsd ]; then
  /etc/rc.d/rc.nfsd stop
fi

# Kill any processes (typically gam) that would otherwise prevent
# unmounting NFS volumes:
unset FUSER_DELAY
for dir in $(/bin/mount | grep -e 'type nfs ' -e 'type nfs4 ' | sed -e 's|.* on ||g' | cut -d ' ' -f 1) ; do
  echo "Killing processes holding NFS mount $dir open..."
  # Background this to prevent fuser from also blocking shutdown:
  /usr/bin/fuser -k -M -m "$dir" &
  FUSER_DELAY=5
done
# If fuser was run, let it have some delay:
if [ ! -z "$FUSER_DELAY" ]; then
  sleep $FUSER_DELAY
fi

# Unmount any NFS, SMB, or CIFS filesystems:
echo "Unmounting remote filesystems:"
/bin/umount -v -a -l -f -r -t nfs,nfs4,smbfs,cifs | tr -d ' ' | grep successfully | sed "s/:successfullyunmounted/ has been successfully unmounted./g"

# Shut down PCMCIA devices:
if [ -x /etc/rc.d/rc.pcmcia ] ; then
  /etc/rc.d/rc.pcmcia stop
  # The cards might need a little extra time here to deactivate:
  sleep 5
fi

# Terminate acpid before syslog:
if [ -x /etc/rc.d/rc.acpid -a -r /var/run/acpid.pid ]; then # quit
  /etc/rc.d/rc.acpid stop
fi

# Kill all processes.
OMITPIDS="$(for p in $(pgrep mdmon); do echo -o $p; done)" # Don't kill mdmon
echo
echo "Sending all processes the SIGHUP signal."
killall5 -1 $OMITPIDS
echo -n "Waiting for processes to hang up"
for loop in 0 1 2 3 4 5 ; do
  sleep 1
  echo -n "."
done
echo
echo "Sending all processes the SIGTERM signal."
killall5 -15 $OMITPIDS
echo -n "Waiting for processes to terminate"
for loop in 0 1 2 3 4 5 ; do
  sleep 1
  echo -n "."
done
echo
echo "Sending all processes the SIGKILL signal."
killall5 -9 $OMITPIDS
echo -n "Waiting for processes to exit"
for loop in 0 1 2 3 4 5 ; do
  sleep 1
  echo -n "."
done
echo

# Now go to the single user level
echo "Going to single user mode..."
/sbin/telinit -t 1 1

