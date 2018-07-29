#***********************************************************
#!/bin/bash
#*********************************************************#
#
# myprofile.sh
#
# This script creates several files under /etc
#
# Revision 0			20150918				J. E. Garrott Sr
# Revision 1			02052016				nobodino
#		-script made of procedures
# Revision 2			04042017				nobodino
#		-added ntp.conf
#		-added SyncClock.sh
#
#*********************************************************
#set -x
#*********************************************************
# personal settings to be adjusted to your own convenients
#*********************************************************

localtime () {
#***************************************************
cp /usr/share/zoneinfo/Europe/Paris /etc/localtime
}

resolv_conf () {
#***************************************************
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
search free.fr
nameserver 192.168.11.100
# End /etc/resolv.conf
EOF
}

ntp_conf () {
#***************************************************
cat > /etc/ntp.conf << "EOF"
# Begin /etc/ntp.conf
# /etc/ntp.conf

driftfile /etc/ntp/drift
logfile /var/log/ntp.log

server 0.fr.pool.ntp.org
server 1.fr.pool.ntp.org
server 2.fr.pool.ntp.org
server 3.fr.pool.ntp.org

server 192.168.2.1 

server 127.127.1.0 
fudge 127.127.1.0 stratum 10 

restrict default ignore 
restrict 127.0.0.1 mask 255.0.0.0 
restrict 192.168.2.1 mask 255.255.255.255

statsdir /var/log/ntp/
statistics loopstats
filegen loopstats file loops type day link enable

# End /etc/ntp.conf
EOF
}

sync_clock () {
#***************************************************
cat > /root/scripts/SyncClock.sh << "EOF"
#!/usr/bin/bash
 
echo "Clock is syncing to NTP, please wait..."
 
sudo /usr/sbin/ntpdate 0.pool.ntp.org
sudo /sbin/hwclock --systohc
EOF
}

rc_keymap () {
#***************************************************
cat > /etc/rc.d/rc.keymap << "EOF"
#!/bin/sh
# Load the keyboard map.  More maps are in /usr/share/kbd/keymaps.
if [ -x /usr/bin/loadkeys ]; then
 /usr/bin/loadkeys fr-latin9.map
fi
EOF
chmod +x /etc/rc.d/rc.keymap
}

root_profile () {
#***************************************************
cat > /root/.profile << "EOF"
#!/bin/sh
setxkbmap -model pc104 -layout fr
TZ='Europe/Paris' ; export TZ
EOF
}

root_bashrc () {
#***************************************************
cat > /root/.bashrc << "EOF"
#!/bin/sh
set -o vi
source /etc/profile
source /root/.profile
LANGUAGE=fr_FR.UTF-8
LC_MESSAGES=fr_FR.UTF-8
LC_ALL=fr_FR.UTF-8
LANG=fr_FR.UTF-8
LESSCHARSET=latin1
export LC_CTYPE LANGUAGE LC_MESSAGES LC_ALL LANG LESSCHARSET
alias q="cd .."
alias ll="ls --color=auto -a -N -l"
alias d="ls --color=auto -a -N"
alias indent="indent -kr"
EOF
}

root_vimrc () {
#***************************************************
cat > /root/.vimrc << "EOF"
" Begin /etc/vimrc
set nocompatible
set backspace=2
set tabstop=4
syntax on
set background=dark
endif
" End /root/.vimrc
EOF
}

#************************************************************
# end of personal settings
#***********************************************************
localtime
resolv_conf
ntp_conf
touch /etc/rc.d/rc.ntpd
chmod +x /etc/rc.d/rc.ntpd
touch /var/log/ntp
chown ntp /var/log/ntp
mkdir -pv /root/scripts
sync_clock
chmod +x /root/scripts/SyncClock.sh
rc_keymap
root_profile
root_bashrc
root_vimrc
#**********************************
cat >> /etc/profile << "EOF"
export LANG=fr_FR.UTF8
EOF
#**********************************
echo
echo "passwd: change password for root."
echo "Exit, and umount every thing."
echo
