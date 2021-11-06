#######################  sfsinit.sh #############################
#!/bin/bash
###########################################################################
# set -x

#*******************************************************************
# VARIABLES to be set by the user
#*******************************************************************
# the directory where will be built slackware from scratch
#*******************************************************************
export SFS=/mnt/sfs
#*******************************************************************
# the directory where are stored everything else slackware (gnuada, SBo..)
#*******************************************************************
export DNDIR=/mnt/ext4/sda4/sfs/others
#export DNDIR=/home/sfs/others
#*******************************************************************
# the directory where are stored dlackware SlackBuilds
# git cloned from https://github.com/Dlackware
# just the necessary packages to build (see README-sfsd for the list)
#*******************************************************************
export DLDIR=/mnt/ext4/sda4/sfs/dlackware
#export DLDIR=/home/sfs/dlackware
#*******************************************************************
# the directory where is stored the resynced slackware sources
#*******************************************************************
export RDIR1=/mnt/ext4/sda4/home/ftp/pub/Linux/Slackware/slackware-current/source
export RDIR2=/mnt/ext4/sda4/home/ftp/pub/Linux/Slackware/slackware-14.2/source
#export RDIR1=/mnt/ext4/sda11/home/ftp/pub/Linux/Slackware/slackware-current/source
#export RDIR2=/mnt/ext4/sda11/home/ftp/pub/Linux/Slackware/slackware-14.2/source
#export RDIR=/home/sfs/source
#*******************************************************************
# the directory where will be copied the slackware sources from RDIR
#*******************************************************************
export SRCDIR=$SFS/slacksrc
#*******************************************************************
# the directory where you store your scripts and build.list
#*******************************************************************
export PATDIR=/mnt/ext4/sda4/sfs
#export PATDIR=/home/sfs
#*******************************************************************
# the directory where will be stored the patches
#*******************************************************************
export PATCHDIR=$SFS/sources/patches
#*******************************************************************


generate_etc_fstab () {
#*******************************************************************
mkdir -pv $SFS/etc
cat > $SFS/etc/fstab << "EOF"
/dev/sdc5       swap             swap        defaults         0   0
/dev/sdc9        /                ext4        defaults         1   1
devpts           /dev/pts         devpts      gid=5,mode=620   0   0
proc             /proc            proc        defaults         0   0
tmpfs            /dev/shm         tmpfs       defaults         0   0
# End /fstab
EOF
}

generate_dhcp_systemd () {
#***************************************************
mkdir -pv $SFS/etc/systemd/network/
cat >  $SFS/etc/systemd/network/10-eth0-dhcp.network << "EOF"
[Match]
Name=eth0
[Network]
DHCP=ipv4
EOF
}

generate_screen_clearing () {
#***************************************************
mkdir -pv $SFS/etc/systemd/system/getty@tty1.service.d/
cat > $SFS/etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF
}

generate_etc_vconsole () {
#***************************************************
mkdir -pv $SFS/etc/
cat > $SFS/etc/vconsole.conf << "EOF"
KEYMAP=fr-latin9
FONT=Lat2-Terminus16
EOF
}

generate_etc_adjtime () {
#***************************************************
mkdir -pv $SFS/etc/
cat > $SFS/etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF
}

#*******************************************************************
# End of VARIABLES to be set by the user
#*******************************************************************




arch_selector () {
#**********************************
# architecture selector selector
#**********************************
PS3="Your choice:"
select build_arch in x86 x86_64 quit
do
	if [[ "$build_arch" = "x86" ]]
	then
		if [[ "$distribution" = "slackware" ]]
		then
			tools_dir='tools' && test_tools_32
			echo "You choose $tools_dir"
			break
		elif [[ "$distribution" = "dlackware" ]]
		then
			tools_dir='tools' && test_tools_32
			echo "You choose $tools_dir"
			break
		elif [[ "$distribution" = "slackware_14_2" ]]
		then
			tools_dir='tools_14_2' && test_tools_32
			echo "You choose $tools_dir"
			break
		fi
		break
	elif [[ "$build_arch" = "x86_64" ]]
	then
		if [[ "$distribution" = "slackware" ]]
		then
			tools_dir='tools_64' && test_tools_64
			echo "You choose $tools_dir"
			break
		elif [[ "$distribution" = "dlackware" ]]
		then
			tools_dir='tools_64' && test_tools_64
			echo "You choose $tools_dir"
			break
		elif [[ "$distribution" = "slackware_14_2" ]]
		then
			tools_dir='tools_64_14_2' && test_tools_64
			echo "You choose $tools_dir"
			break
		fi
		break
	elif [[ "$build_arch" = "quit" ]]
	then
		echo "You have decided to quit. Goodbye." && exit 1
	fi
done
echo "You choose $build_arch."
}

chroot_sfs () {
#**********************************
mkdir -pv $SFS/{dev,proc,sys,run}
#**********************************
# When the kernel boots the system, it requires the presence of
# a few device nodes, in particular the console and null
# devices. The device nodes must be created on the hard
# disk so that they are available before udevd has been
# started, and additionally when Linux is started with
# init=/bin/bash. Create the devices by running the following commands:
#**********************************
mknod -m 600 $SFS/dev/console c 5 1
mknod -m 666 $SFS/dev/null c 1 3
#**********************************
# Mounting and Populating /dev ('cause udev ain't yet!)
#**********************************
mount -v --bind /dev $SFS/dev
#**********************************
# Now mount the remaining virtual kernel filesystems:
#**********************************
mount -vt devpts devpts $SFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $SFS/proc
mount -vt sysfs sysfs $SFS/sys
mount -vt tmpfs tmpfs $SFS/run
#**********************************
# In some host systems, /dev/shm is a symbolic link to /run/shm.
# The /run tmpfs was mounted above so in this case only a directory
# needs to be created.
#**********************************
if [ -h $SFS/dev/shm ]; then
  mkdir -pv $SFS/$(readlink $SFS/dev/shm)
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
echo "cd /sources && ./sfsbuild1.sh link.list"
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
}

clean_sfs () {
#**********************************
# Clear $SFS
#**********************************
cd $SFS
mount -l -t proc |grep sfs >/dev/null
if [ $? == 0 ]; then
	umount -v $SFS/dev/pts
	umount -v $SFS/dev
	umount -v $SFS/proc
	umount -v $SFS/sys
	umount -v $SFS/run
fi

[ -d $SFS/proc ] && rm -rf bin boot dev etc jre home lib media mnt \
	lib64 opt proc root run sbin sfspacks srv sys tmp tools usr var font*

#**********************************
# Copy the tools.tar.gz to $SFS and extract it.
#**********************************
[ -d $SFS/$tools_dir ] && rm -rf $SFS/$tools_dir
cp -v $PATDIR/$tools_dir/tools.tar.gz $SFS
cd $SFS && tar xf tools.tar.gz && rm tools.tar.gz
chown -R root:root $SFS/tools

#**********************************
# ensure /tools link points correctly:
#**********************************
rm -fv /tools
ln -sv $SFS/tools /
}

distribution_selector () {
#**********************************
# distribution selector
#**********************************
PS3="Your choice:"
select distribution in slackware slackware_14_2 dlackware quit
do
	if [[ "$distribution" != "quit" ]]
	then
		break
	fi
	echo "You have decided to quit. Goodbye." && exit 1
done
echo "You choose $distribution."
export $distribution
if [[ "$distribution" = "slackware" ]]
	then
		export RDIR="$RDIR1"
	elif [[ "$distribution" = "dlackware" ]]
	then
		export RDIR="$RDIR1"
	elif [[ "$distribution" = "slackware_14_2" ]]
	then
		export RDIR="$RDIR2"
fi
echo $RDIR

}


dlackware_dir () {
#**********************************
# create dlackware directory and copy every package
#**********************************
mkdir -pv $SFS/slacksrc/dlackware
cp -r $DLDIR/* $SFS/slacksrc/dlackware
}

etc_group () {
#***************************************************
mkdir -pv $SFS/etc
cat > $SFS/etc/group << "EOF"
root:x:0:root
EOF
chmod 644 $SFS/etc/group
}

etc_passwd () {
#***************************************************
cat > $SFS/etc/passwd << "EOF"
root:x:0:0::/root:/bin/bash
EOF
chmod 644 $SFS/etc/passwd
}

sfsprep () {
#***********************************************************
# package management: copy tools from slackware source:
#***********************************************************
mkdir -pv $SFS/sbin
cp $SFS/slacksrc/a/pkgtools/scripts/makepkg $SFS/sbin/makepkg
cp $SFS/slacksrc/a/pkgtools/scripts/installpkg $SFS/sbin/installpkg
chmod 755 $SFS/sbin/makepkg $SFS/sbin/installpkg
}

upgrade_src () {
#*************************************
# Upgrade the sources
#*************************************
echo "Removing old slacksrc."
[ -d $SRCDIR ] && rm -rf $SRCDIR
echo "Installing new sources."
cp -r --preserve=timestamps $RDIR $SRCDIR
#**********************************
# create directory for other packages than slackware
#**********************************
mkdir -pv $SRCDIR/others

#**********************************
# copy every package other packages
#**********************************
cp -rv --preserve=timestamps $DNDIR/* $SRCDIR/others
#**********************************
}

upgrade_src_new () {
#*************************************
# Upgrade the sources
#*************************************
echo "Rsync the sources."
rsync -arvz --stats --progress -I --delete-after $RDIR $SRCDIR
#**********************************
# create directory for other packages than slackware
#**********************************
mkdir -pv $SRCDIR/others

#**********************************
# copy every package other packages
#**********************************
rsync -arvz --stats --progress -I --delete-after $DNDIR/* $SRCDIR/others
#**********************************
}

test_root () {
#*************************************
# test if user is ROOT, if not exit
#*************************************
[ "$UID" != "0" ] && error "You must be ROOT to execute that script."
}

test_tools_32 () {
#************************************************
# test the existence of tools.tar.gz in tools_32
#************************************************
[ ! -f $PATDIR/$tools_dir/tools.tar.gz ] && echo "You can't build an x86 system, the directory or tools.tar.gz doesn't exist."] && exit 1
}

test_tools_64 () {
#************************************************
# test the existence of tools.tar.gz in tools_64
#************************************************
[ ! -f $PATDIR/$tools_dir/tools.tar.gz ] && echo "You can't build an x86_64 system, the directory or tools.tar.gz doesn't exist."] && exit 1
}

generate_source_slack_desc () {
#************************************************
cat > $SRCDIR/k/slack-desc << "EOF"
# HOW TO EDIT THIS FILE:
# The "handy ruler" below makes it easier to edit a package description.  Line
# up the first '|' above the ':' following the base package name, and the '|' on
# the right side marks the last column you can put a character in.  You must make
# exactly 11 lines for the formatting to be correct.  It's also customary to
# leave one space after the ':'.

             |-----handy-ruler------------------------------------------------------|
kernel-source: kernel-source (Linux kernel source)
kernel-source:
kernel-source: Source code for Linus Torvalds' Linux kernel.
kernel-source:
kernel-source: This is the complete and unmodified source code for the Linux kernel.
kernel-source:
kernel-source:
kernel-source:
kernel-source:
kernel-source:
kernel-source:
EOF
}


#************************************************************************
#************************************************************************
# MAIN CORE SCRIPT
#************************************************************************
#************************************************************************

#**************************************
# before everything we test if we are root
#**************************************
test_root
distribution_selector
arch_selector

#**************************************
# generation of patches on $SFS side
# clean the previous patches and recreate them
#**************************************
. patches_generator.sh


#**************************************
# preparation of $SFS side
#**************************************
mkdir -pv $SRCDIR

cd $SFS/sources

#*************************************
# Erase old installation, if any.
#*************************************
echo "Removing old installation."
clean_sfs

#*************************************
# Upgrade the sources
#*************************************
upgrade_src

#*************************************
# create mini /etc/group and /etc/passwd
# to avoid noise while building pkgtools
# "chown: invalid user: 'root:root'"
#*************************************
etc_group
etc_passwd

#***********************************************************
# package management: copy tools from slackware source
# before chrooting and building slackware
#***********************************************************
sfsprep
#***********************************************************
echo
echo "Making adjustments to sources."
echo
#***********************************************************
cd $SFS/sources
. sources_alteration.sh


#***********************************************************
generate_etc_fstab

cd $SFS/sources
. lists_generator.sh

generate_source_slack_desc


#*************************************
# finally chroot in $SFS environment
#*************************************
chroot_sfs && exit 0
