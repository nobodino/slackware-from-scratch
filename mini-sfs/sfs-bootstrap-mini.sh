#######################  sfs-bootstrap-mini.sh #################################
#!/bin/bash
#
# Copyright 2018  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018  "nobodino", Bordeaux, FRANCE
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
#  Revision 0 			13072018				nobodino
#		-script issued from sfs-boostrap.sh to build slackware from scratch
#		-trimmed to build only list1
#		-no local upgrade
#		-integrated list1 generation
#
#	Above july 2018, revisions made through github project: https://github.com/nobodino/slackware-from-scratch 
#
################################################################################
# set -x

#*******************************************************************
# VARIABLES to be set by the user
#*******************************************************************
# the directory where will be built slackware from scratch
#*******************************************************************
export SFS=/mnt/sfs
#*******************************************************************
export RDIR1=/mnt/ext4/sda4/home/ftp/pub/Linux/Slackware/slackware-current
export RDIR3=/mnt/ext4/sda4/home/ftp/pub/Linux/Slackware/slackware64-current
#*******************************************************************
# the rsync mirror from which you get the slackware source tree
#*******************************************************************
#export RSYNCDIR=rsync://mirror.slackbuilds.org/slackware/slackware-current
#export RSYNCDIR=rsync://mirrors.slackware.bg/slackware/slackware-current
# export RSYNCDIR=rsync://slackware.uk/slackware/slackware-current
export RSYNCDIR=rsync://bear.alienbase.nl/mirrors/slackware/slackware64-current
#*******************************************************************
# the directory where will be copied the slackware sources from RDIR
#*******************************************************************
export SRCDIR=$SFS/slacksrc
#*******************************************************************
# the directory where will be stored the patches necessary to build SFS
#*******************************************************************
export PATCHDIR=$SFS/sources/patches
#*******************************************************************
# the mirrors from which we download files to populate "others" directly
#*******************************************************************
export DLDIR2=ftp://slackware.uk/slackware/slackware-14.1
export DLDIR3=ftp://slackware.uk/slackware/slackware-14.2
export DLDIR4=ftp://slackware.uk/slackware/slackware64-14.1
export DLDIR5=ftp://slackware.uk/slackware/slackware64-14.2
export DLDIR6=http://mirror.eu.oneandone.net/linux/distributions/gentoo/gentoo/distfiles
#*******************************************************************
# rust and cargo versions
#*******************************************************************
export GNAT_x86="gnat-gpl-2014-x86-linux-bin.tar.gz"
export GNAT_x86_64="gnat-gpl-2017-x86_64-linux-bin.tar.gz"
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#*******************************************************************


generate_etc_fstab () {
#*******************************************************************
mkdir -pv $SFS/etc
cat > $SFS/etc/fstab << "EOF"
/dev/sdd1        swap             swap        defaults         0   0
/dev/sdd2       /                ext4        defaults,noatime,discard  	   1   1
/dev/fd0         /mnt/floppy      auto        noauto,owner     0   0
devpts           /dev/pts         devpts      gid=5,mode=620   0   0
proc             /proc            proc        defaults         0   0
tmpfs            /dev/shm         tmpfs       nosuid,nodev,noexec 0   0
# End /fstab
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
			tools_dir='tools'
			echo
			echo -e "$BLUE" "You choose $tools_dir" "$NORMAL"
			echo
			break
		fi
		break
	elif [[ "$build_arch" = "x86_64" ]]
	then
		if [[ "$distribution" = "slackware" ]]
		then
			tools_dir='tools_64'
			echo
			echo -e "$BLUE" "You choose $tools_dir" "$NORMAL"
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
echo -e "$BLUE"  "You choose $build_arch." "$NORMAL"
echo

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
echo -e "$BLUE" "You choose $distribution."  "$NORMAL" 
export $distribution
if [[ "$distribution" = "slackware" ]]
	then
		if [[ "$build_arch" = "x86" ]]
		then
			export RDIR="$RDIR1"
		elif [[ "$build_arch" = "x86_64" ]]
		then
			export RDIR="$RDIR3"
		fi
fi
echo $RDIR

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
		echo "You choose to upgrade the sources of SFS."
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
		echo  -e "$YELLOW" "You choose to keep the sources of SFS as they are." "$NORMAL" 
		break
	fi
done
export $upgrade_sources
}

copy_rust () {
#*************************************
# rust can't be built without previous version
#*************************************

if [[ "$build_arch" = "x86" ]]
	then
		cp -rv $SRCDIR/others/rust/* $SRCDIR/d/rust
	elif [[ "$build_arch" = "x86_64" ]]
	then
		cp -rv $SRCDIR/others/rust64/* $SRCDIR/d/rust
fi
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
			wget -c -v $DLDIR2/slackware/l/readline-6.3-i586-2.txz
		fi
		if [ ! -f libpng-1.4.12-i486-1.txz ]; then
			wget -c -v $DLDIR2/slackware/l/libpng-1.4.12-i486-1.txz
		fi
		cd $SRCDIR/others 
		if [ ! -f ksh93-2012_08_01-i586-2.txz ]; then
			wget -c -v $DLDIR3/slackware/ap/ksh93-2012_08_01-i586-2.txz
		fi
		cd $SRCDIR/others
		if [ ! -f $GNAT_x86 ]; then
			wget -c -v $DLDIR6/$GNAT_x86  && chmod 644 *.tar.gz
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
			wget -c -v $DLDIR4/slackware64/l/readline-6.3-x86_64-2.txz
		fi
		if [ ! -f libpng-1.4.12-x86_64-1.txz ]; then
			wget -c -v $DLDIR4/slackware64/l/libpng-1.4.12-x86_64-1.txz
		fi
		cd $SRCDIR/others  
		if [ ! -f ksh93-2012_08_01-x86_64-2.txz ]; then
			wget -c -v $DLDIR5/slackware64/ap/ksh93-2012_08_01-x86_64-2.txz
		fi
		cd $SRCDIR/others
		if [ ! -f $GNAT_x86_64 ]; then
			wget -c -v $DLDIR6/$GNAT_x86_64 && chmod 644 *.tar.gz
		fi 	
fi
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

#*******************************************************************
# sub-system of generation of patches
#*******************************************************************

patch_cmake_c () {
#******************************************************************
cat > $PATCHDIR/cmakeSB.patch << "EOF"
--- cmake.SlackBuild.old	2018-03-22 13:14:34.939837627 +0100
+++ cmake.SlackBuild	2018-03-22 13:14:34.946840870 +0100
@@ -79,7 +79,6 @@
 ../bootstrap \
   --prefix=/usr \
   --docdir=/doc/$PKGNAM-$VERSION \
-  --qt-gui \
   --system-curl \
   --system-expat \
   --no-system-jsoncpp \
@@ -96,7 +95,6 @@
   ../configure \
   --prefix=/usr \
   --docdir=/doc/$PKGNAM-$VERSION \
-  --qt-gui \
   --system-curl \
   --system-expat \
   --no-system-jsoncpp \
EOF
}

patch_findutils_c () {
#******************************************************************
cat > $PATCHDIR/findutilsSB.patch << "EOF"
--- findutils.SlackBuild.old	2018-09-22 15:27:07.594932088 +0200
+++ findutils.SlackBuild	2018-09-22 16:05:48.038923236 +0200
@@ -67,6 +67,11 @@
 tar xvf $CWD/findutils-$VERSION.tar.?z* || exit 1
 cd findutils-$VERSION || exit 1
 
+# patch to build with glibc-2.28 (from LFS)
+sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
+sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
+echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
+
 chown -R root:root .
 find . \
   \( -perm 777 -o -perm 775 -o -perm 711 -o -perm 555 -o -perm 511 \) \
@@ -79,22 +84,6 @@
 # like to be yelled at.
 zcat $CWD/findutils.no.default.options.warnings.diff.gz | patch -p1 --verbose || exit 1
 
-# Add patches from Fedora to finally make findutils-4.6.0 usable:
-zcat $CWD/patches/findutils-4.4.2-xautofs.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.5.13-warnings.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.5.15-no-locate.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-exec-args.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-fts-update.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-gnulib-fflush.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-gnulib-makedev.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-internal-noop.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-leaf-opt.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-man-exec.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-mbrtowc-tests.patch.gz | patch -p1 --verbose || exit 1
-zcat $CWD/patches/findutils-4.6.0-test-lock.patch.gz | patch -p1 --verbose || exit 1
-
-autoreconf -vif
-
 CFLAGS="$SLKCFLAGS" \
 ./configure \
   --prefix=/usr \
EOF
}

patch_kmod_c () {
#******************************************************************
cat > $PATCHDIR/kmodSB.patch << "EOF"
--- kmod.SlackBuild.old	2018-03-22 13:14:35.002866815 +0100
+++ kmod.SlackBuild	2018-03-22 13:14:35.009870059 +0100
@@ -94,8 +94,8 @@
   --enable-python \
   --build=$ARCH-slackware-linux || exit 1
 
-make || exit 1
-make install DESTDIR=$PKG || exit 1
+make
+make install DESTDIR=$PKG
 
 # "make clean" deletes too much, so we have to start fresh :(
 
EOF
}

patch_libcap_c () {
#******************************************************************
cat > $PATCHDIR/libcapSB.patch << "EOF"
--- libcap.SlackBuild.old	2018-03-22 13:14:34.951843186 +0100
+++ libcap.SlackBuild	2018-03-22 13:14:34.958846429 +0100
@@ -92,7 +92,7 @@
 
 
 make DYNAMIC=yes $NUMJOBS || make DYNAMIC=yes || exit 1
-make install FAKEROOT=$PKG man_prefix=/usr || exit 1
+make RAISE_SETFCAP=no install FAKEROOT=$PKG man_prefix=/usr || 1
 chmod 755 $PKG/lib${LIBDIRSUFFIX}/libcap.so*
 
 find $PKG | xargs file | grep -e "executable" -e "shared object" | grep ELF \
EOF
}

patch_pkg_config_c () {
#******************************************************************
cat > $PATCHDIR/pkg-configSB.patch << "EOF"
--- pkg-config.SlackBuild.old	2018-03-22 13:14:34.976854769 +0100
+++ pkg-config.SlackBuild	2018-03-22 13:14:34.983858012 +0100
@@ -85,6 +85,7 @@
 CFLAGS="$SLKCFLAGS" \
 ./configure \
   --prefix=/usr \
+  --with-internal-glib \
   --libdir=/usr/lib${LIBDIRSUFFIX} \
   --mandir=/usr/man \
   --docdir=/usr/doc/pkg-config-$VERSION \
EOF
}

patch_readline_c () {
#******************************************************************
cat > $PATCHDIR/readlineSB.patch << "EOF"
--- readline.SlackBuild.old	2018-04-20 03:37:08.479444178 +0200
+++ readline.SlackBuild	2018-04-20 16:59:57.686260427 +0200
@@ -100,26 +100,10 @@
   --build=$ARCH-slackware-linux-gnu || exit 1
 
 # Link with libtinfo:
-make $NUMJOBS static shared SHLIB_LIBS=-ltinfo || make static shared SHLIB_LIBS=-ltinfo || exit 1
+# make $NUMJOBS static shared SHLIB_LIBS=-ltinfo || make static shared SHLIB_LIBS=-ltinfo || exit 1
+make $NUMJOBS static
 make install DESTDIR=$PKG || exit 1
 
-# build rlfe (ReadLine Front-End) from examples/
-# NOTE:  This will link against the currently installed libreadline!
-# Build/install this package twice whenever there is an .soname bump.
-( cd examples/rlfe || exit 1
-  CFLAGS="$SLKCFLAGS" \
-  ./configure \
-    --prefix=/usr \
-    --libdir=/usr/lib${LIBDIRSUFFIX} \
-    --mandir=/usr/man \
-    --infodir=/usr/info \
-    --docdir=/usr/doc/readline-$VERSION \
-    --build=$ARCH-slackware-linux-gnu || exit 1
-  make $NUMJOBS || exit 1
-  install -m 755 rlfe $PKG/usr/bin
-  cp -a README $PKG/usr/doc/readline-$VERSION/README.rlfe
-) || exit 1
-
 find $PKG | xargs file | grep -e "executable" -e "shared object" \
   | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
 
EOF
}

#*******************************************************************
# End of sub-system of patches
#*******************************************************************
#*******************************************************************
# sub-system of execution of patches
#*******************************************************************

execute_cmake () {
#******************************************************************
if [ ! -f $SRCDIR/d/cmake/cmake.SlackBuild.old ]; then
	cp -v $SRCDIR/d/cmake/cmake.SlackBuild $SRCDIR/d/cmake/cmake.SlackBuild.old
	(
		cd $SRCDIR/d/cmake
		zcat $PATCHDIR/cmakeSB.patch.gz |patch cmake.SlackBuild  --verbose
	)
fi
}

execute_findutils() {
#******************************************************************
if [ ! -f $SRCDIR/a/findutils/findutils.SlackBuild.old ]; then
	cp -v $SRCDIR/a/findutils/findutils.SlackBuild $SRCDIR/a/findutils/findutils.SlackBuild.old
	(
		cd $SRCDIR/a/findutils
		zcat $PATCHDIR/findutilsSB.patch.gz |patch findutils.SlackBuild --verbose
	)
fi
}

execute_kmod () {
#******************************************************************
if [ ! -f $SRCDIR/a/kmod/kmod.SlackBuild.old ]; then
	cp -v $SRCDIR/a/kmod/kmod.SlackBuild $SRCDIR/a/kmod/kmod.SlackBuild.old
	(
		cd $SRCDIR/a/kmod
		zcat $PATCHDIR/kmodSB.patch.gz |patch kmod.SlackBuild --verbose
	)
fi
}

execute_libcap () {
#******************************************************************
if [ ! -f $SRCDIR/l/libcap/libcap.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libcap/libcap.SlackBuild \
		$SRCDIR/l/libcap/libcap.SlackBuild.old
	(
		cd $SRCDIR/l/libcap
		zcat $PATCHDIR/libcapSB.patch.gz |patch libcap.SlackBuild  --verbose
	)
fi
}

execute_pkg_config () {
#******************************************************************
if [ ! -f $SRCDIR/d/pkg-config/pkg-config.SlackBuild.old ]; then
	cp -v $SRCDIR/d/pkg-config/pkg-config.SlackBuild \
		$SRCDIR/d/pkg-config/pkg-config.SlackBuild.old
	(
		cd $SRCDIR/d/pkg-config
		zcat $PATCHDIR/pkg-configSB.patch.gz |patch pkg-config.SlackBuild --verbose
	)
fi
}

execute_readline () {
#******************************************************************
if [ ! -f $SRCDIR/l/readline/readline.SlackBuild.old ]; then
	cp -v $SRCDIR/l/readline/readline.SlackBuild $SRCDIR/l/readline/readline.SlackBuild.old
	(
		cd $SRCDIR/l/readline
		zcat $PATCHDIR/readlineSB.patch.gz |patch readline.SlackBuild --verbose
	)
fi
}


#*******************************************************************
# End of sub-system of execution of patches
#*******************************************************************

patches_generator_c () {
#**********************************
# generation of the patches
#**********************************
PS3="Your choice:"
echo
echo -e "$RED" "Do you want to regenerate the patches: yes, no or quit." "$NORMAL" 
echo
select build_patches in yes no quit
do
	if [[ "$build_patches" = "yes" ]]
	then
		rm -rvf $PATCHDIR && mkdir -pv $PATCHDIR
		patch_cmake_c
		patch_findutils_c
		patch_kmod_c
		patch_libcap_c
		patch_pkg_config_c
		patch_readline_c
		gzip -9 $PATCHDIR/*.patch
		break
	elif [[ "$build_patches" = "no" ]]
	then
		break
	elif [[ "$build_patches" = "quit" ]]
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	fi
done
echo
echo -e "$RED" "You choose $build_patches." "$NORMAL" && echo
echo 
}

sources_alteration_c () {
#**********************************
# alteration of the slackware sources
#**********************************
PS3="Your choice:"
echo
echo -e "$BLUE" "Do you want to alter the slackware sources: yes, no or quit." "$NORMAL" && echo
echo
select sources_alteration in yes no quit
do
	if [[ "$sources_alteration" = "yes" ]]
	then

		execute_cmake # 2 pass
		execute_findutils # 2 pass
		execute_kmod # 2 pass
		execute_libcap # 2 pass
		execute_pkg_config # 2 pass
		execute_readline # 2 pass
		break
	elif [[ "$sources_alteration" = "no" ]]
	then
		echo
		echo "You decided to keep the slackware sources."
		echo "The building of slackware won't build completely"
		echo
		break
	elif [[ "$sources_alteration" = "quit" ]]
	then
		echo
		echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	fi
done
export $distribution
echo
echo $distribution
echo "You choose $sources_alteration."
echo
}

generate_slackware_link_build_list () {
cat > $SFS/sources/link.list << "EOF"
a link_tools_slackware
EOF
}

generate_slackware_build_list1_c () {
#******************************************
cat > $SFS/sources/build1_s.list << "EOF"
a findutils
a pkgtools
a aaa_base
a etc
d kernel-headers
d python
d python3
d bison
l glibc
a adjust
# a test-glibc
l zlib
d bison
d help2man
a lzip
d flex
d binutils
d libtool
l gmp
l mpfr
l libmpc
a infozip
l expat
d python
d python3
l gc
d patchelf
d pre-gcc
d gcc
d post-gcc
a bzip2
d pkg-config
l ncurses
a attr
a acl
l libcap
l libcap
a sed
a shadow
a grep
l readline
l gdbm
d gperf
d autoconf
d automake
a xz
a kmod
a gettext
a gettext-tools
l elfutils
l libffi
a procps-ng
ap groff
a util-linux
a e2fsprogs
a coreutils
a glibc-zoneinfo
l readline
l readline
ap diffutils
a gawk
a less
a gzip
n libmnl
l libnl
l libnl3
l libpcap
n libnfnetlink
n libnetfilter_conntrack
n libnftnl
n iptables
n iproute2
a hostname
a kbd
l libunistring
l gc
l gmp
d guile
d make
a patch
a sysklogd
a utempter
a sysvinit
a sysvinit-scripts
l popt
a sysvinit-functions
a bin
a devs
n network-scripts
l pcre
l glib2
l gamin
l glib2
l gobject-introspection
a eudev
ap man-db
a bash
a tar
ap texinfo
ap man-pages
l jemalloc
l libaio
n openssl
n openssl10
l libssh2
l jansson
n curl
l libarchive
d cmake
ap mariadb
d perl
d intltool
a ed
ap bc
a file
d m4
a which
l readline
n dhcpcd
a kernel-all
d help2man
d flex
d bison
d autoconf
d libtool
a findutils
n lynx
a end1
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
patches_generator_c

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
# Upgrade the sources from local or rsync
#*************************************
echo
echo "Do you want to upgrade the sources of SFS? rsync or Quit."
echo
echo "rsync means: it will rsync directly from a slackware mirror defined by"
echo 
echo -e "$BLUE" "$RSYNCDIR" "$NORMAL"
echo 
PS3="Your choice:"
echo
select upgrade_type in rsync Quit
do
	if [[ "$upgrade_type" = "Quit" ]]
	then
		echo
		echo  -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
	elif [[ "$upgrade_type" = "rsync" ]]
	then
		echo
		echo -e "$RED" "You choose to rsync slacksrc directly from a slackware mirror." "$NORMAL"
		echo
		cd $SFS/sources
		rsync_src
		populate_others
		break
	fi
done
#*************************************
# populate_others

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
# Making adjustments to sources
#***********************************************************
cd $SFS/sources
sources_alteration_c

#***********************************************************
generate_etc_fstab

cd $SFS/sources
generate_slackware_link_build_list
generate_slackware_build_list1_c

. prep-sfs-tools.sh

#*************************************
# finally chroot in $SFS environment
#*************************************
. chroot_sfs.sh
exit 0
