#######################  sfs-bootstrap.sh ######################################
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
# -current or -dev selector
#**********************************
PS3="Your choice:"
select dev_select in current development quit
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

}

rsync_src () {
#*************************************
# Upgrade the sources by rsyncing 
#*************************************
echo "Do you want to upgrade the sources of SFS? No, Yes or Quit."
PS3="Your choice:"
select upgrade_sources in Yes No Quit
do
	if [[ "$upgrade_sources" = "Quit" ]]
	then
		echo  -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_sources" = "Yes" ]]
	then
		echo "You chose to upgrade the sources of SFS."
		echo
		echo "rsync the slacksrc tree from a slackware mirror"
		mkdir $SFS/sources/others > /dev/null 2>&1
		cp -r --preserve=timestamps $SRCDIR/others/* $SFS/sources/others > /dev/null 2>&1
		mkdir $SFS/sources/extra > /dev/null 2>&1
		cp -r --preserve=timestamps $SRCDIR/extra/* $SFS/sources/extra > /dev/null 2>&1
		rsync -arvz --stats --progress -I --delete-after $RSYNCDIR/source/ $SRCDIR
		mkdir $SRCDIR/others > /dev/null 2>&1
		cp -r --preserve=timestamps $SFS/sources/others/* $SRCDIR/others > /dev/null 2>&1
		mkdir $SRCDIR/extra > /dev/null 2>&1
		cp -r --preserve=timestamps  $SFS/sources/extra/* $SRCDIR/extra > /dev/null 2>&1
		rsync -arvz --stats --progress -I --delete-after $RSYNCDIR/extra/source/ $SRCDIR/extra > /dev/null 2>&1
		cd $SFS/sources 
		rm end* > /dev/null 2>&1
		rm *.t?z > /dev/null 2>&1
		rm -rf $SFS/sources/others > /dev/null 2>&1 
		rm -rf $SFS/sources/extra > /dev/null 2>&1
		break
	elif [[ "$upgrade_sources" = "No" ]]
	then
		echo  -e "$YELLOW" "You chose to keep the sources of SFS as they are." "$NORMAL" 
		break
	fi
done

}

upgrade_src () {
#*************************************
# Upgrade the sources from local mirror
#*************************************
echo "Do you want to upgrade the sources of SFS? No, Yes or Quit."
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
		echo "You chose to upgrade the sources of SFS."
		echo "Removing old slacksrc."
		[ -d $SRCDIR ] && rm -rf $SRCDIR
		echo "Installing new sources."
		cp -r --preserve=timestamps $RDIR/source $SRCDIR
		mkdir -pv $SRCDIR/others  > /dev/null 2>&1
		mkdir -pv $SRCDIR/extra > /dev/null 2>&1
		cp -r --preserve=timestamps $DNDIR1/* $SRCDIR/others
		cp -r --preserve=timestamps $RDIR/extra/source/* $SRCDIR/extra
		cd $SFS/sources
		rm end* > /dev/null 2>&1
		rm *.t?z > /dev/null 2>&1
		rm -rf $SFS/sources/extra && rm -rf $SFS/sources/others
		break
	elif [[ "$upgrade_sources" = "No" ]]
	then
		echo
		echo "You chose to keep the sources of SFS as they are." 
		break
	fi
done

}

rsync_dev_current () {
#*************************************
# download directly from github repository
#*************************************

if [[ "$dev_select" = "current" ]]; then
		echo "You chose the -current branch of slackware to build SFS."
		echo
		rm -rf $SFS/slacksrc/current && mkdir $SFS/slacksrc/current
		svn checkout $DLDIR13/current $SFS/slacksrc/current > /dev/null 2>&1
		rm -rf $SFS/slacksrc/current/.svn
		cp -r --preserve=timestamps $SFS/slacksrc/current/* $SFS/slacksrc
		rm -rf $SFS/slacksrc/current
	elif [[ "$dev_select" = "development" ]]; then
		echo "You chose the -development branch of slackware to build SFS."
		echo
		rm -rf $SFS/slacksrc/development && mkdir $SFS/slacksrc/development
		svn checkout $DLDIR13/development $SFS/slacksrc/development > /dev/null 2>&1
		rm -rf $SFS/slacksrc/development/.svn
		if find $SFS/slacksrc/development/l/glibc -mindepth 1 | read; then
			rm -rf $SFS/slacksrc/l/glibc
		fi
		if find $SFS/slacksrc/development/d/binutils -mindepth 1 | read; then
			rm -rf $SFS/slacksrc/d/binutils
		fi
		if find $SFS/slacksrc/development/d/gcc -mindepth 1 | read; then
			rm -rf $SFS/slacksrc/d/gcc
		fi
		if find $SFS/slacksrc/development/d/rust -mindepth 1 | read; then
			rm -rf $SFS/slacksrc/d/rust && mkdir -pv $SFS/slacksrc/d/rust
			cd $SFS/slacksrc/d/rust && lftpget https://static.rust-lang.org/dist/2020-12-31/rustc-1.49.0-src.tar.xz
		fi
		cp -r --preserve=timestamps $SFS/slacksrc/development/* $SFS/slacksrc
		rm -rf $SFS/slacksrc/development

fi

}

upgrade_dvd () {
#*************************************
# Upgrade the sources from local dvd (blu-ray disc)
#*************************************
echo "Do you want to upgrade the sources of SFS? No, Yes or Quit."
PS3="Your choice: "
select upgrade_sources in Yes No Quit
do
	if [[ "$upgrade_sources" = "Quit" ]] 
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_sources" = "Yes" ]]; then
		echo
		echo "You chose to upgrade the sources of SFS from DVD."
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
		cd $SFS/sources
		rm end* > /dev/null 2>&1
		rm *.t?z > /dev/null 2>&1
		rm -rf $SFS/sources/extra && rm -rf $SFS/sources/others
		break
	elif [[ "$upgrade_sources" = "No" ]]
	then
		echo
		echo "You chose to keep the sources of SFS as they are."
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
		cd $SRCDIR/d/rust && sed -i -e '1,22d' rust.url && sed -i -e '5,10d' rust.url && source rust.url
		cd $SRCDIR/others
		if [ ! -f readline-7.0.005-i586-1.txz ]; then
			wget -c -v $DLDIR12/readline-7.0.005-i586-1.txz
		fi
		if [ ! -f libffi-3.2.1-i586-2.txz ]; then
			wget -c -v $DLDIR12/libffi-3.2.1-i586-2.txz
		fi
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
		cd $SRCDIR/d/rust && sed -i -e '1,27d' rust.url && source rust.url
		cd $SRCDIR/others
		if [ ! -f readline-7.0.005-x86_64-1.txz ]; then
			wget -c -v $DLDIR12/readline-7.0.005-x86_64-1.txz
		fi
		if [ ! -f libffi-3.2.1-x86_64-2.txz ]; then
			wget -c -v $DLDIR12/libffi-3.2.1-x86_64-2.txz
		fi
fi

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

root_bashrc () {
#***************************************************
mkdir -pv $SFS/root
cat >  $SFS/root/.bashrc << "EOF"
#!/bin/sh
LC_ALL=C.UTF-8
export LC_ALL
EOF
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
. export_variables_perso.sh
distribution_selector
arch_selector
dev_selector

#**************************************
# preparation of $SFS side
#**************************************
mkdir -pv $SRCDIR

cd $SFS/sources

#*************************************
# Erase old installation, if any.
#*************************************
echo
echo "Removing old installation."
echo
clean_sfs

#*************************************
# Upgrade the sources from local, rsync or DVD
#*************************************
echo
echo "Do you want to upgrade the sources of SFS? rsync, local, DVD or Quit."
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
		cd $SFS/sources
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
sfsprep

cd $SFS/sources
. lists_generator_c.sh
. prep-sfs-tools.sh
#*************************************
# finally chroot in $SFS environment
#*************************************
. chroot_sfs.sh
exit 0
