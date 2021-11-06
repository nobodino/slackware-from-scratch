#!/bin/sh
#
# NetworkManager:   NetworkManager daemon
#
# description:  This is a daemon for automatically switching network \
#               connections to the best available connection. \
#
# processname: NetworkManager
# pidfile: /var/run/NetworkManager/NetworkManager.pid
#

prefix=/usr
exec_prefix=/usr
sbindir=${exec_prefix}/sbin

NETWORKMANAGER_BIN=${sbindir}/NetworkManager

# Sanity checks.
[ -x $NETWORKMANAGER_BIN ] || exit 0

PIDFILE=/var/run/NetworkManager/NetworkManager.pid

nm_start()
{
  if [ "`pgrep dbus-daemon`" = "" ]; then
    echo "D-BUS must be running to start NetworkManager"
    return
  fi
  
  # Just in case the pidfile is still there, we may need to nuke it.
  if [ -e "$PIDFILE" ]; then
    rm -f $PIDFILE
  fi

  echo "Starting NetworkManager daemon:  $NETWORKMANAGER_BIN"
  XDG_CACHE_HOME=/root/.cache $NETWORKMANAGER_BIN
}

nm_status()
{
  local pidlist=`cat $PIDFILE 2>/dev/null`
  if [ -z "$pidlist" ]; then
    return 1
  fi
  local command=`ps -p $pidlist -o comm=`
  if [ "$command" != 'NetworkManager' ]; then
    return 1
  fi
}

nm_stop()
{
  echo -en "Stopping NetworkManager: "
  # Shut down any DHCP connections, otherwise the processes will be orphaned
  # and the connections will not come up when NetworkManager restarts.
  if ps ax | grep /sbin/dhcpcd | grep -q libexec/nm-dhcp ; then
    ps ax | grep /sbin/dhcpcd | grep libexec/nm-dhcp | while read line ; do
      kill -HUP $(echo $line | cut -b 1-5)
    done
  fi
  if ps ax | grep /sbin/dhclient | grep -q /var/lib/NetworkManager ; then
    ps ax | grep /sbin/dhclient | grep /var/lib/NetworkManager | while read line ; do
      kill -HUP $(echo $line | cut -b 1-5)
    done
  fi
  local pidlist=`cat $PIDFILE 2>/dev/null`
  if [ ! -z "$pidlist" ]; then
    kill $pidlist &>/dev/null
    sleep 3
    rm -f $PIDFILE &>/dev/null
  fi
  # If wpa_supplicant is running here, it needs to be shut down as well.
  # Since you're asking for NetworkManager to shut down, we have to assume
  # that wpa_supplicant was started by it.
  if [ -r /var/run/wpa_supplicant.pid ]; then
    kill $(cat /var/run/wpa_supplicant.pid)
  elif [ -r /run/wpa_supplicant.pid ]; then
    kill $(cat /run/wpa_supplicant.pid)
  fi
  echo "stopped";
  sleep 3
}

nm_restart()
{
  nm_stop
  nm_start
}

case "$1" in
'start')
  if ( ! nm_status ); then
    nm_start
  else
    echo "NetworkManager is already running (will not start it twice)."
  fi
		;;
'stop')
  nm_stop
		;;
'restart')
  nm_restart
		;;
'status')
  if ( nm_status ); then
    echo "NetworkManager is currently running"
  else
    echo "NetworkManager is not running."
  fi
		;;
*)
  echo "usage $0 start|stop|status|restart"
esac
