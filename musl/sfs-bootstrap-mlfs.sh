#######################  sfs-bootstrap-mlfs.sh ######################################
#!/bin/bash
#
# Copyright 2018,2019,2020,2021  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018,2019,2020,2021  "nobodino", Bordeaux, FRANCE
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
#
#--------------------------------------------------------------------------
#
#	Above july 2018, revisions made through github project: 
#   
#   https://github.com/nobodino/slackware-from-scratch 
#
#*******************************************************************
# set -x
#*******************************************************************

test_root () {
#*************************************
# test if user is ROOT, if not exit
#*************************************
[ "$UID" != "0" ] && error "You must be ROOT to execute that script."
}

distribution_selector () {
#**********************************
# distribution selector
#**********************************
PS3="Your choice:"
select distribution in slackware quit
do
	if [[ "$distribution" != "quit" ]]
	then
		break
	fi
	echo
	echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL"  && exit 1
done
echo -e "$BLUE" "You chose $distribution."  "$NORMAL" 
export $distribution
echo

}

arch_selector () {
#**********************************
# architecture selector
#**********************************
PS3="Your choice:"
select build_arch in x86 x86_64 quit
do
	if [[ "$build_arch" = "x86" ]]
	then
		if [[ "$distribution" = "slackware" ]]
		then
			tools_dir1='tools_x86'
			echo
			echo -e "$BLUE" "You chose $tools_dir1" "$NORMAL"
			echo
			break
		fi
		break
	elif [[ "$build_arch" = "x86_64" ]]
	then
		if [[ "$distribution" = "slackware" ]]
		then
			tools_dir1='tools_x86_64'
			echo
			echo -e "$BLUE" "You chose $tools_dir1" "$NORMAL"
			echo
			break
		fi
		break
	elif [[ "$build_arch" = "quit" ]]
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	fi
done
echo
echo -e "$BLUE"  "You chose $build_arch." "$NORMAL"
echo

}

dev_selector () {
#**********************************
# -currentv -development or -musl selector
#**********************************
PS3="Your choice:"
select dev_select in current development musl quit
do
	if [[ "$dev_select" = "current" ]]; then
		if [[ "$build_arch" = "x86" ]]; then
			tools_dir='tools'
			export $tools_dir && echo $tools_dir
			echo
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
			echo
			break
		elif [[ "$build_arch" = "x86_64" ]]; then
			tools_dir='tools_64'
			export $tools_dir && echo $tools_dir
			echo
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
			echo
			break
		fi
		break
	elif [[ "$dev_select" = "development" ]]; then
		if [[ "$build_arch" = "x86" ]]; then
			tools_dir='tools_dev'
			export $tools_dir && echo $tools_dir
			echo
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
			echo
			break
		elif [[ "$build_arch" = "x86_64" ]]; then
			tools_dir='tools_64_dev'
			export $tools_dir && echo $tools_dir
			echo
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
			echo
			break
		fi
		break
	elif [[ "$dev_select" = "musl" ]]; then
		if [[ "$build_arch" = "x86" ]]; then
			tools_dir='tools_musl'
			export $tools_dir && echo $tools_dir
			echo
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
			echo
			break
		elif [[ "$build_arch" = "x86_64" ]]; then
			tools_dir='tools_64_musl'
			export $tools_dir && echo $tools_dir
			echo
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
			echo
			break
		fi
		break
	elif [[ "$dev_select" = "quit" ]]
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	fi
done
echo
echo -e "$BLUE"  "You chose $dev_select." "$NORMAL"
echo
export $dev_select
#**********************************************
# defines RDIR according to x86 or x86_64:
#**********************************************
	if [[ "$distribution" = "slackware" ]]; then
		if [[ "$build_arch" = "x86" ]]; then
			export RDIR="$RDIR1"
		elif [[ "$build_arch" = "x86_64" ]]; then
			export RDIR="$RDIR3"
		fi
	fi
	echo "****** $RDIR ******"

}

clean_mlfs () {
#**********************************
# Clear $MLFS
#**********************************
cd $MLFS
mount -l -t proc |grep mlfs >/dev/null
if [ $? == 0 ]; then
	umount -v $MLFS/dev/pts
	umount -v $MLFS/dev
	umount -v $MLFS/proc
	umount -v $MLFS/sys
	umount -v $MLFS/run
fi

[ -d $MLFS/proc ] && rm -rf bin boot cross-tools dev etc jre home lib media mnt \
	lib64 opt proc root run sbin sfspacks srv sys tmp tools usr var font*

}

rsync_src () {
#*************************************
# Upgrade the sources by rsyncing 
#*************************************
echo "Do you want to upgrade the sources of MLFS? No, Yes or Quit."
PS3="Your choice:"
select upgrade_sources in Yes No Quit
do
	if [[ "$upgrade_sources" = "Quit" ]]
	then
		echo  -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_sources" = "Yes" ]]
	then
		echo "You chose to upgrade the sources of MLFS."
		echo
		echo "rsync the slacksrc tree from a slackware mirror"
		mkdir $MLFS/sources/others > /dev/null 2>&1
		cp -r --preserve=timestamps $SRCDIR/others/* $MLFS/sources/others > /dev/null 2>&1
		mkdir $MLFS/sources/extra > /dev/null 2>&1
		cp -r --preserve=timestamps $SRCDIR/extra/* $MLFS/sources/extra > /dev/null 2>&1
		rsync -arvz --stats --progress -I --delete-after $RSYNCDIR/source/ $SRCDIR
		mkdir $SRCDIR/others > /dev/null 2>&1
		cp -r --preserve=timestamps $MLFS/sources/others/* $SRCDIR/others > /dev/null 2>&1
		mkdir $SRCDIR/extra > /dev/null 2>&1
		cp -r --preserve=timestamps  $MLFS/sources/extra/* $SRCDIR/extra > /dev/null 2>&1
		rsync -arvz --stats --progress -I --delete-after $RSYNCDIR/extra/source/ $SRCDIR/extra > /dev/null 2>&1
		cd $MLFS/sources 
		rm end* > /dev/null 2>&1
		rm *.t?z > /dev/null 2>&1
		rm -rf $MLFS/sources/others > /dev/null 2>&1 
		rm -rf $MLFS/sources/extra > /dev/null 2>&1
		break
	elif [[ "$upgrade_sources" = "No" ]]
	then
		echo  -e "$YELLOW" "You chose to keep the sources of MLFS as they are." "$NORMAL" 
		break
	fi
done

}

upgrade_src () {
#*************************************
# Upgrade the sources from local mirror
#*************************************
echo "Do you want to upgrade the sources of MLFS? No, Yes or Quit."
PS3="Your choice:"
select upgrade_sources in Yes No Quit
do
	if [[ "$upgrade_sources" = "Quit" ]]
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_sources" = "Yes" ]]
	then
		echo
		echo "You chose to upgrade the sources of MLFS."
		echo "Removing old slacksrc."
		[ -d $SRCDIR ] && rm -rf $SRCDIR
		echo "Installing new sources."
		cp -r --preserve=timestamps $RDIR/source $SRCDIR
		mkdir -pv $SRCDIR/others  > /dev/null 2>&1
		mkdir -pv $SRCDIR/extra > /dev/null 2>&1
		cp -r --preserve=timestamps $DNDIR1/* $SRCDIR/others
		cp -r --preserve=timestamps $RDIR/extra/source/* $SRCDIR/extra
		cd $MLFS/sources
		rm end* > /dev/null 2>&1
		rm *.t?z > /dev/null 2>&1
		rm -rf $MLFS/sources/extra && rm -rf $MLFS/sources/others
		break
	elif [[ "$upgrade_sources" = "No" ]]
	then
		echo
		echo "You chose to keep the sources of MLFS as they are." 
		break
	fi
done

}

rsync_dev_current () {
#*************************************
# download directly from github repository
#*************************************

if [[ "$dev_select" = "current" ]]; then
		echo "You chose the -current branch of slackware to build MLFS."
		echo
		rm -rf $MLFS/slacksrc/current && mkdir $MLFS/slacksrc/current
		svn checkout $DLDIR13/current $MLFS/slacksrc/current > /dev/null 2>&1
		rm -rf $MLFS/slacksrc/current/.svn
		cp -r --preserve=timestamps $MLFS/slacksrc/current/* $MLFS/slacksrc
		rm -rf $MLFS/slacksrc/current
	elif [[ "$dev_select" = "development" ]]; then
		echo "You chose the -development branch of slackware to build MLFS."
		echo
		rm -rf $MLFS/slacksrc/development && mkdir $MLFS/slacksrc/development
		svn checkout $DLDIR13/development $MLFS/slacksrc/development > /dev/null 2>&1
		rm -rf $MLFS/slacksrc/development/.svn
		if find $MLFS/slacksrc/development/l/glibc -mindepth 1 | read; then
			rm -rf $MLFS/slacksrc/l/glibc
		fi
		if find $MLFS/slacksrc/development/d/binutils -mindepth 1 | read; then
			rm -rf $MLFS/slacksrc/d/binutils
		fi
		if find $MLFS/slacksrc/development/d/gcc -mindepth 1 | read; then
			rm -rf $MLFS/slacksrc/d/gcc
		fi
		if find $MLFS/slacksrc/development/d/make -mindepth 1 | read; then
			rm -rf $MLFS/slacksrc/d/make
		fi
#		if find $MLFS/slacksrc/development/d/rust -mindepth 1 | read; then
#			rm -rf $MLFS/slacksrc/d/rust && mkdir -pv $MLFS/slacksrc/d/rust
#			cd $MLFS/slacksrc/d/rust && lftpget https://static.rust-lang.org/dist/2020-12-31/rustc-1.49.0-src.tar.xz
#		fi
		cp -r --preserve=timestamps $MLFS/slacksrc/development/* $MLFS/slacksrc
#		rm -rf $MLFS/slacksrc/development
	elif [[ "$dev_select" = "musl" ]]; then
		echo "You chose the -musl branch of slackware to build MLFS."
		echo
		rm -rf $MLFS/slacksrc/musl && mkdir $MLFS/slacksrc/musl
		svn checkout $DLDIR13/musl $MLFS/slacksrc/musl > /dev/null 2>&1
		rm -rf $MLFS/slacksrc/musl/.svn
#		cp -r --preserve=timestamps $MLFS/slacksrc/musl/* $MLFS/slacksrc
#		rm -rf $MLFS/slacksrc/musl

fi

}

upgrade_dvd () {
#*************************************
# Upgrade the sources from local dvd (blu-ray disc)
#*************************************
echo "Do you want to upgrade the sources of MLFS? No, Yes or Quit."
PS3="Your choice: "
select upgrade_sources in Yes No Quit
do
	if [[ "$upgrade_sources" = "Quit" ]] 
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_sources" = "Yes" ]]; then
		echo
		echo "You chose to upgrade the sources of MLFS from DVD."
		# Check that dvd has been mounted
		[ ! -d "$RDIR5" ] && mkdir $RDIR5
		mount -l |grep "$RDIR5" >/dev/null
		[ $? != 0 ] && mount /dev/sr0 $RDIR5
		echo "Removing old slacksrc."
		[ -d $SRCDIR ] && rm -rf $SRCDIR
		echo "Installing new sources."
		cp -r --preserve=timestamps $RDIR5/source $SRCDIR
		mkdir -pv $SRCDIR/others  > /dev/null 2>&1
		mkdir -pv $SRCDIR/extra > /dev/null 2>&1
		cp -r --preserve=timestamps $DNDIR1/* $SRCDIR/others
		cp -r --preserve=timestamps $RDIR5/extra/source/* $SRCDIR/extra
		cd $MLFS/sources
		rm end* > /dev/null 2>&1
		rm *.t?z > /dev/null 2>&1
		rm -rf $MLFS/sources/extra && rm -rf $MLFS/sources/others
		break
	elif [[ "$upgrade_sources" = "No" ]]
	then
		echo
		echo "You chose to keep the sources of MLFS as they are."
		break
	fi
done

}

populate_others () {
#*************************************
# download directly from source to others
#*************************************

if [[ "$build_arch" = "x86" ]]
	then
		mkdir $SRCDIR/others > /dev/null 2>&1
		cd $SRCDIR/others
		if [ ! -f cxxlibs-6.0.18-i486-1.txz ]; then
			wget -c -v $DLDIR2/slackware/a/cxxlibs-6.0.18-i486-1.txz
		fi
		if [ ! -f gmp-5.1.3-i486-1.txz ]; then
			wget -c -v $DLDIR2/slackware/l/gmp-5.1.3-i486-1.txz
		fi
		if [ ! -f libtermcap-1.2.3-i486-7.txz ]; then
			wget -c -v $DLDIR2/slackware/l/libtermcap-1.2.3-i486-7.txz
		fi
		if [ ! -f ncurses-5.9-i486-4.txz ]; then
			wget -c -v $DLDIR3/slackware/l/ncurses-5.9-i486-4.txz
		fi
		if [ ! -f readline-6.3-i586-2.txz ]; then
			wget -c -v $DLDIR3/slackware/l/readline-6.3-i586-2.txz
		fi
		if [ ! -f libpng-1.4.12-i486-1.txz ]; then
			wget -c -v $DLDIR2/slackware/l/libpng-1.4.12-i486-1.txz
		fi
		if [ ! -f ksh93-2012_08_01-i586-2.txz ]; then
			wget -c -v $DLDIR3/slackware/ap/ksh93-2012_08_01-i586-2.txz
		fi
		if [ ! -f libcaca-0.99.beta18-i486-2.txz ]; then
			wget -c -v $DLDIR3/slackware/l/libcaca-0.99.beta18-i486-2.txz
		fi
		cd $SRCDIR/others
		if [ ! -f $GNAT_x86 ]; then
			wget -c -v $DLDIR6/$GNAT_x86  && chmod 644 *.tar.gz
		fi
#		cd $SRCDIR/others 
#		if [ ! -f jre-$JDK-linux-i586.tar.gz ]; then
#			# from https://gist.github.com/P7h/9741922
#			curl -C - -LR#OH "Cookie: oraclelicense=accept-securebackup-cookie" -k $DLDIR9
#		fi
#		cp -v jre-$JDK-linux-i586.tar.gz $SRCDIR/extra/java
		cd $SRCDIR/d/rust && sed -i -e '1,22d' rust.url && sed -i -e '9,14d' rust.url && source rust.url
		cd $SRCDIR/others
		# download the missing aaa_libraries packages
		svn checkout $DLDIR12
	elif [[ "$build_arch" = "x86_64" ]]
	then
		mkdir $SRCDIR/others > /dev/null 2>&1
		cd $SRCDIR/others
		if [ ! -f cxxlibs-6.0.18-x86_64-1.txz ]; then
			wget -c -v $DLDIR4/slackware64/a/cxxlibs-6.0.18-x86_64-1.txz
		fi
		if [ ! -f gmp-5.1.3-x86_64-1.txz ]; then
			wget -c -v $DLDIR4/slackware64/l/gmp-5.1.3-x86_64-1.txz
		fi
		if [ ! -f libtermcap-1.2.3-x86_64-7.txz ]; then
			wget -c -v $DLDIR4/slackware64/l/libtermcap-1.2.3-x86_64-7.txz
		fi
		if [ ! -f ncurses-5.9-x86_64-4.txz ]; then
			wget -c -v $DLDIR5/slackware64/l/ncurses-5.9-x86_64-4.txz
		fi
		if [ ! -f readline-6.3-x86_64-2.txz ]; then
			wget -c -v $DLDIR5/slackware64/l/readline-6.3-x86_64-2.txz
		fi
		if [ ! -f libpng-1.4.12-x86_64-1.txz ]; then
			wget -c -v $DLDIR4/slackware64/l/libpng-1.4.12-x86_64-1.txz
		fi
		if [ ! -f ksh93-2012_08_01-x86_64-2.txz ]; then
			wget -c -v $DLDIR5/slackware64/ap/ksh93-2012_08_01-x86_64-2.txz
		fi
		if [ ! -f libcaca-0.99.beta18-x86_64-2.txz ]; then
			wget -c -v $DLDIR5/slackware64/l/libcaca-0.99.beta18-x86_64-2.txz
		fi
		cd $SRCDIR/others
		if [ ! -f $GNAT_x86_64 ]; then
			wget -c -v $DLDIR6/$GNAT_x86_64 && chmod 644 *.tar.gz
		fi
#		cd $SRCDIR/others 
#		if [ ! -f jre-$JDK-linux-x64.tar.gz ]; then
#			# from https://gist.github.com/P7h/9741922
#			curl -C - -LR#OH "Cookie: oraclelicense=accept-securebackup-cookie" -k $DLDIR10
#		fi
#		cp -rv jre-$JDK-linux-x64.tar.gz $SRCDIR/extra/java
		cd $SRCDIR/d/rust && sed -i -e '1,22d' rust.url && sed -i -e '4,9d' rust.url && source rust.url
		cd $SRCDIR/others
		# download the missing aaa_libraries packages
		svn checkout $DLDIR12
fi
}

etc_group () {
#***************************************************
mkdir -pv $MLFS/etc
cat > $MLFS/etc/group << "EOF"
root:x:0:root
EOF
chmod 644 $MLFS/etc/group
}

etc_passwd () {
#***************************************************
cat > $MLFS/etc/passwd << "EOF"
root:x:0:0::/root:/bin/bash
EOF
chmod 644 $MLFS/etc/passwd
}

root_bashrc () {
#***************************************************
mkdir -pv $MLFS/root
cat >  $MLFS/root/.bashrc << "EOF"
#!/bin/sh
LC_ALL=C.UTF-8
export LC_ALL
EOF
}

mlfsprep () {
#***********************************************************
# package management: copy tools from slackware source:
#***********************************************************
mkdir -pv $MLFS/sbin
cp $MLFS/slacksrc/a/pkgtools/scripts/makepkg $MLFS/sbin/makepkg
cp $MLFS/slacksrc/a/pkgtools/scripts/installpkg $MLFS/sbin/installpkg
chmod 755 $MLFS/sbin/makepkg $MLFS/sbin/installpkg
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
. export_variables.sh
. export_variables_perso_mlfs.sh
distribution_selector
arch_selector
dev_selector

#**************************************
# preparation of $MLFS side
#**************************************
mkdir -pv $SRCDIR

cd $MLFS/sources

#*************************************
# Erase old installation, if any.
#*************************************
echo
echo "Removing old installation."
echo
clean_mlfs

#*************************************
# Upgrade the sources from local, rsync or DVD
#*************************************
echo
echo "Do you want to upgrade the sources of MLFS? rsync, local, DVD or Quit."
echo
echo "rsync means: it will rsync directly from a slackware mirror defined by"
echo 
echo -e "$BLUE" "$RSYNCDIR" "$NORMAL"
echo
echo "local means: it will rsync from a local slackware mirror you have already rsynced and defined by"
echo
echo -e "$BLUE" "$RDIR1" "$NORMAL"
echo
echo "DVD means: it will rsync from a local slackware DVD (double layer) or BluRay you have already burnt and defined by"
echo
echo -e "$BLUE" "$RDIR5" "$NORMAL"
echo 
PS3="Your choice:"
echo
select upgrade_type in rsync local DVD Quit
do
	if [[ "$upgrade_type" = "Quit" ]]
	then
		echo
		echo  -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_type" = "rsync" ]]
	then
		echo
		echo -e "$RED" "You chose to rsync slacksrc directly from a slackware mirror." "$NORMAL"
		echo
		cd $MLFS/sources
		rsync_src
		rsync_dev_current
		populate_others
		break
	elif [[ "$upgrade_type" = "local" ]]
	then
		echo
		echo  -e "$RED" "You chose to rsync slacksrc from a local mirror." "$NORMAL"
		echo 
		upgrade_src
		rsync_dev_current
		populate_others
		break
	elif [[ "$upgrade_type" = "DVD" ]]
	then
		echo
		echo  -e "$RED" "You chose to rsync slacksrc from a local DVD or BluRay." "$NORMAL"
		echo 
		mount -t auto /dev/sr0 /mnt/dvd && sleep 5 && echo -e "$RED" "DVD mounted on /mnt/DVD" "$NORMAL"
		upgrade_dvd
		rsync_dev_current
		populate_others
		umount /mnt/dvd && sleep 3 && eject && echo -e "$RED" "DVD unmounted from /mnt/DVD and ejected." "$NORMAL"
 		break
	fi
done

#*************************************
# create mini /etc/group and /etc/passwd
# to avoid noise while building pkgtools
# "chown: invalid user: 'root:root'"
#*************************************
etc_group
etc_passwd
root_bashrc
#***********************************************************
# package management: copy tools from slackware source
# before chrooting and building slackware
#***********************************************************
mlfsprep

cd $MLFS/sources
. lists_generator_mlfs.sh
. prep-mlfs-tools.sh
#*************************************
# finally chroot in $MLFS environment
#*************************************
. chroot_mlfs.sh
exit 0
