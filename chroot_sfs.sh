#!/bin/bash
#######################  chroot_sfs.sh #########################################
#
# Copyright 2018, 2019,2020,2021  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018, 2019,2020,2021  "nobodino", Bordeaux, FRANCE
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#--------------------------------------------------------------------------
#
# Note: Much of this script is inspired from the LFS manual chapter 5
#       Copyright © 1999-2019 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
#
#	Above july 2018, revisions made through github project: 
#   https://github.com/nobodino/slackware-from-scratch 
#
#**********************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#**********************************
# chown from sfs:sfs to root:root
#**********************************
cd .. && chown -fR root:root "$SFS"/tools
chown -fR root:root $SFS/source
#**********************************
mkdir -pv "$SFS"/{dev,proc,sys,run}
#**********************************
# When the kernel boots the system, it requires the presence of
# a few device nodes, in particular the console and null
# devices. The device nodes must be created on the hard
# disk so that they are available before udevd has been
# started, and additionally when Linux is started with
# init=/bin/bash. Create the devices by running the following commands:
#**********************************
mknod -m 600 "$SFS"/dev/console c 5 1
mknod -m 666 "$SFS"/dev/null c 1 3
#**********************************
# Mounting and Populating /dev ('cause udev ain't yet!)
#**********************************
mount -v --bind /dev "$SFS"/dev
#**********************************
# Now mount the remaining virtual kernel filesystems:
#**********************************
mount -v --bind /dev/pts "$SFS"/dev/pts -o gid=5,mode=620
mount -vt proc proc "$SFS"/proc
mount -vt sysfs sysfs "$SFS"/sys
mount -vt tmpfs tmpfs "$SFS"/run
#**********************************
# In some host systems, /dev/shm is a symbolic link to /run/shm.
# The /run tmpfs was mounted above so in this case only a directory
# needs to be created.
#**********************************
if [ -h "$SFS"/dev/shm ]; then
  mkdir -pv "$SFS"/"$(readlink "$SFS"/dev/shm)"
fi
#**********************************
echo
echo "The SFS directory is now ready for building."
echo
echo "From now, you are on the $SFS side."
echo "Be sure you are ready before doing anything."
echo "You will enter the /sources directory, and establish links between:"
echo
echo "	- /tools/bin and /bin"
echo "	- /tools/lib and /usr/lib:"
echo
echo "You can execute now the following instructions."
echo
echo -e "$YELLOW" "cd /scripts && source link_tools" "$NORMAL" 
echo
#**********************************
# and finally, enter the chroot environment.
#**********************************
chroot "$SFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
#**********************************
