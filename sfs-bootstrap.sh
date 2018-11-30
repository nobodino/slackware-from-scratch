#######################  sfs-bootstrap.sh ######################################
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
# 
#  Revision 0 			18022018				nobodino
#		-script issued from sfsinit.sh to build slackware from scratch
#		-only slackware-current for x86 and x86_64 will be boostrapped
#	Revision 1			041032018		nobodino
#		-modified upgrade_src to be able to copy extra/
#	Revision 2			20032018		nobodino
#		-added rsync_src to rsync the slacksrc directly from a slackware mirror
#		-added populate_others to download directly all the packages without local mirror
#		-reintegrated patch_generator_c and source_alteration_c (much shorter now)
#	Revision 3			25032018		nobodino
#		-linked to lists_generator_c.sh
#		-for bootstrap only
#	Revision 4			26032018		nobodino
#		-corrected typo: "gnuada64" instead "gnuada" for x86 in rsync_src
#		-corrected type: flex-2.5.39.tar.xz instead of flex-2.5.39-tar.xz
#		-corrected typo: x86 slackware instead of slackware64
#		-displaced populate_others in the right place after rsync_src
#		-added patch from LFS for flex-2.6.4 to build doxygen-1.8.14 for glibc >= 2.26
#	Revision 5			15042018		nobodino
#		-removed flex-2.5.39 to build doxygen-1.8.14 (found a patch for flex-2.6.4)
#	Revision 6			20042018		nobodino
#		-modified for 'third mass rebuild'
#	Revision 7			26042018		nobodino
#		-modified GNAT_x86 and GNAT_x86_64 definition
#		-corrected isl-$ISLVER
#		-modified java build: switch to extra/java (jre)
#		-colorized the script
#	Revision 8			03072018		nobodino
#		-restored cxxlibs-6.0.18 (libstdc++.so.5)
#		-modified libpng-1.4.12 (DIR2 and DIR4)
#		-modified texlive patch
#		-added gd, freetype and harfbuzz patch (two pass packages)
#	Revision 9			16072018		nobodino
#		-added QScintilla  patch (two pass package)
#
#	Above july 2018, revisions made through github project: https://github.com/nobodino/slackware-from-scratch 
#
#*******************************************************************
# set -x
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
echo

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
LANGUAGE=C.UTF-8
LC_MESSAGES=C.UTF-8
LC_ALL=C.UTF-8
LANG=C.UTF-8
export LC_CTYPE LANGUAGE LC_MESSAGES LC_ALL LANG
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
		echo "You choose to upgrade the sources of SFS."
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
		echo "You choose to keep the sources of SFS as they are." 
		break
	fi
done
export $upgrade_sources

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
export $upgrade_sources
return

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
		if [ ! -f ksh93-2012_08_01-i586-2.txz ]; then
			wget -c -v $DLDIR3/slackware/ap/ksh93-2012_08_01-i586-2.txz
		fi
		mkdir -pv $SRCDIR/others/isl  > /dev/null 2>&1
		cd $SRCDIR/others/isl
		if [ ! -f isl.tar.gz ]; then
			curl --user user:password -o isl.tar.gz $DLDIR11/libraries/isl.tar.gz 
			tar xf isl.tar.gz
			cd $SRCDIR/others/isl/isl 
			mv * ../ > /dev/null 2>&1
			cd .. && rm -rf isl && rm isl.tar.gz
		fi 
		if [ ! -f isl-$ISLVER.tar.xz ]; then
			wget -c -v $DLDIR6/isl-$ISLVER.tar.xz
		fi
		cd $SRCDIR/others
		if [ ! -f $GNAT_x86 ]; then
			wget -c -v $DLDIR6/$GNAT_x86  && chmod 644 *.tar.gz
		fi
		cd $SRCDIR/others 
		if [ ! -f jre-$JDK-linux-i586.tar.gz ]; then
			# from https://gist.github.com/P7h/9741922
			curl -C - -LR#OH "Cookie: oraclelicense=accept-securebackup-cookie" -k $DLDIR9
		fi
		cp -v jre-$JDK-linux-i586.tar.gz $SRCDIR/extra/java
		cd $SRCDIR/d/rust && sed -i -e '1,12d' rust.url && sed -i -e '7,11d' rust.url && source rust.url	
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
		if [ ! -f ksh93-2012_08_01-x86_64-2.txz ]; then
			wget -c -v $DLDIR5/slackware64/ap/ksh93-2012_08_01-x86_64-2.txz
		fi
		mkdir -pv $SRCDIR/others/isl  > /dev/null 2>&1
		cd $SRCDIR/others/isl
		if [ ! -f isl.tar.gz ]; then
			curl --user user:password -o isl.tar.gz $DLDIR11/libraries/isl.tar.gz 
			tar xf isl.tar.gz
			cd $SRCDIR/others/isl/isl 
			mv * ../ > /dev/null 2>&1
			cd .. && rm -rf isl && rm isl.tar.gz
		fi 
		if [ ! -f isl-$ISLVER.tar.xz ]; then
			wget -c -v $DLDIR6/isl-$ISLVER.tar.xz
		fi
		cd $SRCDIR/others
		if [ ! -f $GNAT_x86_64 ]; then
			wget -c -v $DLDIR6/$GNAT_x86_64 && chmod 644 *.tar.gz
		fi
		cd $SRCDIR/others 
		if [ ! -f jre-$JDK-linux-x64.tar.gz ]; then
			# from https://gist.github.com/P7h/9741922
			curl -C - -LR#OH "Cookie: oraclelicense=accept-securebackup-cookie" -k $DLDIR10
		fi
		cp -rv jre-$JDK-linux-x64.tar.gz $SRCDIR/extra/java
		cd $SRCDIR/d/rust && sed -i -e '1,18d' rust.url && source rust.url
fi

}


test_root () {
#*************************************
# test if user is ROOT, if not exit
#*************************************
[ "$UID" != "0" ] && error "You must be ROOT to execute that script."
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

patch_dbus_c () {
#******************************************************************
cat > $PATCHDIR/dbusSB.patch << "EOF"
--- dbus.SlackBuild.old	2018-03-22 13:14:35.014872375 +0100
+++ dbus.SlackBuild	2018-03-22 13:14:35.021875618 +0100
@@ -94,7 +94,6 @@
   --enable-shared=yes \
   --enable-static=no \
   --enable-inotify \
-  --enable-x11-autolaunch \
   --with-system-pid-file=/var/run/dbus/dbus.pid \
   --with-system-socket=/var/run/dbus/system_bus_socket \
   --with-console-auth-dir=/var/run/console \
EOF
}

patch_fontconfig_c () {
#******************************************************************
cat > $PATCHDIR/fontconfigSB.patch << "EOF"
--- fontconfig.SlackBuild.old	2018-03-22 13:14:35.062894614 +0100
+++ fontconfig.SlackBuild	2018-03-22 13:14:35.069897858 +0100
@@ -93,6 +93,7 @@
   --libdir=/usr/lib${LIBDIRSUFFIX} \
   --mandir=/usr/man \
   --sysconfdir=/etc \
+  --disable-docs \
   --with-templatedir=/etc/fonts/conf.avail \
   --with-baseconfigdir=/etc/fonts \
   --with-configdir=/etc/fonts/conf.d \
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

patch_libcaca_c () {
#******************************************************************
cat > $PATCHDIR/libcacaSB.patch << "EOF"
--- libcaca.SlackBuild.old	2018-04-20 03:37:08.415444179 +0200
+++ libcaca.SlackBuild	2018-04-20 03:41:35.836443158 +0200
@@ -25,6 +25,12 @@
 PKGNAM=libcaca
 VERSION=${VERSION:-$(echo $PKGNAM-*.tar.?z* | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
 BUILD=${BUILD:-3}
+LCAC=${LCAC:-1}
+if [ $LCAC == 1 ]; then
+	JAVAENABLE="disable"
+else
+	JAVAENABLE="enable"
+fi
 
 # Automatically determine the architecture we're building on:
 if [ -z "$ARCH" ]; then
@@ -90,6 +96,7 @@
   --disable-doc \
   --disable-imlib2 \
   --disable-ruby \
+  --$JAVAENABLE-java \
   --disable-python \
   --disable-static \
   --enable-slang \
@@ -105,8 +112,8 @@
 rm -f $PKG/{,usr/}lib${LIBDIRSUFFIX}/*.la
 
 cd python
-  python setup.py install --root=$PKG || exit 1
-  python3 setup.py install --root=$PKG || exit 1
+  python setup.py install --root=$PKG
+  python3 setup.py install --root=$PKG
 cd -
 
 # Strip binaries:
EOF
}

patch_libusb_c () {
#******************************************************************
cat > $PATCHDIR/libusbSB.patch << "EOF"
--- libusb.SlackBuild.old	2018-04-20 03:37:08.437444178 +0200
+++ libusb.SlackBuild	2018-04-20 16:55:04.665261545 +0200
@@ -84,6 +84,7 @@
   --mandir=/usr/man \
   --docdir=/usr/doc/libusb-$VERSION \
   --disable-static \
+  --disable-udev \
   --build=$ARCH-slackware-linux || exit 1
 
 make $NUMJOBS || make || exit 1
EOF
}

patch_llvm_c () {
#******************************************************************
cat > $PATCHDIR/llvmSB.patch << "EOF"
--- llvm.SlackBuild.old	2018-09-22 15:10:51.319935812 +0200
+++ llvm.SlackBuild	2018-09-22 15:10:51.322935812 +0200
@@ -127,8 +127,8 @@
 mkdir build
 cd build
   cmake \
-    -DCMAKE_C_COMPILER="clang" \
-    -DCMAKE_CXX_COMPILER="clang++" \
+    -DCMAKE_C_COMPILER="gcc" \
+    -DCMAKE_CXX_COMPILER="g++" \
     -DCMAKE_C_FLAGS:STRING="$SLKCFLAGS" \
     -DCMAKE_CXX_FLAGS:STRING="$SLKCFLAGS" \
     -DCMAKE_INSTALL_PREFIX=/usr \
EOF
}

patch_mesa_c () {
#******************************************************************
cat > $PATCHDIR/mesaSB.patch << "EOF"
--- mesa.SlackBuild.old	2018-09-22 15:10:51.323935812 +0200
+++ mesa.SlackBuild	2018-09-22 15:10:51.326935812 +0200
@@ -178,7 +178,7 @@
   done
   # Remove cruft:
   rm -rf $PKG/cruft
-) || exit 1
+)
 
 # Strip binaries:
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

patch_qscint_c () {
#******************************************************************
cat > $PATCHDIR/QScintillaSB.patch << "EOF"
--- QScintilla.SlackBuild.old	2018-05-22 19:50:51.515794609 +0200
+++ QScintilla.SlackBuild	2018-07-16 19:10:42.421411468 +0200
@@ -108,14 +108,14 @@
 
 cd Python
   python3 configure.py || exit 1
-  make $NUMJOBS || exit 1
-  make install INSTALL_ROOT=$PKG || exit 1
+  make $NUMJOBS
+  make install INSTALL_ROOT=$PKG
 
   make clean || exit 1
 
   python configure.py || exit 1
-  make $NUMJOBS || exit 1
-  make install INSTALL_ROOT=$PKG || exit 1
+  make $NUMJOBS
+  make install INSTALL_ROOT=$PKG
 cd -
 
 # Link the shared libraries into /usr/lib${LIBDIRSUFFIX}:
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

patch_subversion_c () {
#******************************************************************
cat > $PATCHDIR/subversionSB.patch << "EOF"
--- subversion.SlackBuild.old	2018-04-20 03:37:08.491444178 +0200
+++ subversion.SlackBuild	2018-04-20 03:37:08.494444178 +0200
@@ -93,7 +93,6 @@
   --with-lz4=internal \
   --with-zlib=/usr \
   --with-pic \
-  --with-kwallet \
   --build=$ARCH-slackware-linux || exit 1
 
 make $NUMJOBS || make || exit 1
EOF
}

patch_texlive_c () {
#******************************************************************
cat > $PATCHDIR/texliveSB.patch << "EOF"
--- texlive.SlackBuild.old	2018-11-30 16:13:43.056989837 +0100
+++ texlive.SlackBuild	2018-11-30 16:22:42.170987780 +0100
@@ -133,8 +133,11 @@
     --disable-dialog \
     --disable-bibtexu \
     --disable-xz \
-    --with-x \
-    --enable-xindy \
+    --disable-web2c \
+    --disable-xetex \
+    --disable-dvisvgm \
+    --without-x \
+    --disable-xindy \
     --disable-xindy-docs \
     --disable-xindy-rules \
     --with-clisp-runtime=system \
@@ -146,12 +149,11 @@
     --with-system-freetype2 \
     --with-system-libgs \
     --with-system-icu \
-    --with-system-pixman \
-    --with-system-cairo \
-    --with-system-gmp \
-    --with-system-mpfr \
-    --with-system-fontconfig \
-    --with-system-ncurses \
+    --without-system-pixman \
+    --without-system-cairo \
+    --without-system-gmp \
+    --without-system-mpfr \
+    --without-system-fontconfig \
     --with-system-harfbuzz \
     --disable-aleph \
     --disable-dump-share \
EOF
}

patch_xfce_c () {
#******************************************************************
cat > $PATCHDIR/xfce-build-all.patch << "EOF"
--- xfce-build-all.sh.old	2018-03-22 13:14:35.087906197 +0100
+++ xfce-build-all.sh	2018-03-22 13:14:35.094909440 +0100
@@ -55,7 +55,9 @@
   xfce4-weather-plugin \
   ; do
   cd $package || exit 1
-  ./${package}.SlackBuild || ( touch /tmp/${package}.failed ; exit 1 ) || exit 1
+#  ./${package}.SlackBuild || ( touch /tmp/${package}.failed ; exit 1 ) || exit 1
+   ./${package}.SlackBuild
+   [ $? != 0 ] && touch /tmp/${package}.failed
   if [ "$INST" = "1" ]; then
     PACKAGE="$(ls -t $TMP/$(ls ${package}*.xz | rev | cut -f2- -d - | rev)-*txz | head -n 1)"
     if [ -f $PACKAGE ]; then
EOF
}

patch_freetype_c () {
#******************************************************************
cat > $PATCHDIR/freetypeSB.patch << "EOF"
--- freetype.SlackBuild.old	2018-09-22 12:50:49.615967862 +0200
+++ freetype.SlackBuild	2018-09-22 12:54:20.173967059 +0200
@@ -117,8 +117,14 @@
   --with-png=yes \
   --enable-freetype-config \
   --build=$ARCH-slackware-linux || exit 1
-make $NUMJOBS || make || exit 1
-make install DESTDIR=$PKG || exit 1
+make $NUMJOBS
+make
+make install DESTDIR=$PKG
+
+# install freetype headers to build harfbuzz
+mkdir -pv $PKG/usr/include/freetype2
+cp devel/ft2build.h $PKG/usr/include/freetype2/ft2build.h
+cp devel/ftoption.h $PKG/usr/include/freetype2/ftoption.h
 
 # Don't ship .la files:
 rm -f $PKG/{,usr/}lib${LIBDIRSUFFIX}/*.la
EOF
}

patch_harfbuzz_c () {
#******************************************************************
cat > $PATCHDIR/harfbuzzSB.patch << "EOF"
--- harfbuzz.SlackBuild.old	2018-06-23 17:21:47.193436297 +0200
+++ harfbuzz.SlackBuild	2018-06-24 11:04:15.203652967 +0200
@@ -90,8 +90,12 @@
   --docdir=/usr/doc/$PKGNAM-$VERSION \
   --build=$ARCH-slackware-linux || exit 1
 
-make $NUMJOBS || make || exit 1
-make install DESTDIR=$PKG || exit 1
+make $NUMJOBS || make
+make install DESTDIR=$PKG
+
+# install harfbuzz headers to build freetype
+mkdir -pv $PKG/usr/include/harfbuzz
+cp src/*.h $PKG/usr/include/harfbuzz
 
 # Don't ship .la files:
 rm -f $PKG/{,usr/}lib${LIBDIRSUFFIX}/*.la
EOF
}

patch_gd_c () {
#******************************************************************
cat > $PATCHDIR/gdSB.patch << "EOF"
--- gd.SlackBuild.old	2018-04-23 19:20:53.924170184 +0200
+++ gd.SlackBuild	2018-07-04 20:39:26.859379010 +0200
@@ -87,13 +87,15 @@
   --prefix=/usr \
   --libdir=/usr/lib${LIBDIRSUFFIX} \
   --disable-static \
+  --without-fontconfig \
+  --without-xpm \
   --program-prefix= \
   --program-suffix= \
   --build=$ARCH-slackware-linux || exit 1
 
 # Build and install:
-make $NUMJOBS || make || exit 1
-make install DESTDIR=$PKG || exit 1
+make $NUMJOBS || make
+make install DESTDIR=$PKG
 
 # Don't ship .la files:
 rm -f $PKG/{,usr/}lib${LIBDIRSUFFIX}/*.la
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

execute_dbus () {
#******************************************************************
if [ ! -f $SRCDIR/a/dbus/dbus.SlackBuild.old ]; then
	cp -v $SRCDIR/a/dbus/dbus.SlackBuild $SRCDIR/a/dbus/dbus.SlackBuild.old
	(
		cd $SRCDIR/a/dbus
		zcat $PATCHDIR/dbusSB.patch.gz |patch dbus.SlackBuild --verbose
	)
fi
}

execute_findutils () {
#******************************************************************
if [ ! -f $SRCDIR/a/findutils/findutils.SlackBuild.old ]; then
	cp -v $SRCDIR/a/findutils/findutils.SlackBuild $SRCDIR/a/findutils/findutils.SlackBuild.old
	(
		cd $SRCDIR/a/findutils
		zcat $PATCHDIR/findutilsSB.patch.gz |patch findutils.SlackBuild --verbose
	)
fi
}

execute_fontconfig() {
#******************************************************************
if [ ! -f $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old ]; then
	cp -v $SRCDIR/x/fontconfig/fontconfig.SlackBuild $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old
	(
		cd $SRCDIR/x/fontconfig
		zcat $PATCHDIR/fontconfigSB.patch.gz |patch fontconfig.SlackBuild --verbose
	)
fi
}

execute_freetype () {
#******************************************************************
if [ ! -f $SRCDIR/l/freetype/freetype.SlackBuild.old ]; then
	cp -v $SRCDIR/l/freetype/freetype.SlackBuild $SRCDIR/l/freetype/freetype.SlackBuild.old
	(
		cd $SRCDIR/l/freetype
		zcat $PATCHDIR/freetypeSB.patch.gz |patch freetype.SlackBuild --verbose
	)
fi
}

execute_gd () {
#******************************************************************
if [ ! -f $SRCDIR/l/gd/gd.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gd/gd.SlackBuild $SRCDIR/l/gd/gd.SlackBuild.old
	(
		cd $SRCDIR/l/gd
		zcat $PATCHDIR/gdSB.patch.gz |patch gd.SlackBuild --verbose
	)
fi
}

execute_harfbuzz() {
#******************************************************************
if [ ! -f $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.old ]; then
	cp -v $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.old
	(
		cd $SRCDIR/l/harfbuzz
		zcat $PATCHDIR/harfbuzzSB.patch.gz |patch harfbuzz.SlackBuild --verbose
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

execute_libcaca () {
#******************************************************************
if [ ! -f $SRCDIR/l/libcaca/libcaca.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libcaca/libcaca.SlackBuild $SRCDIR/l/libcaca/libcaca.SlackBuild.old
	(
		cd $SRCDIR/l/libcaca
		zcat $PATCHDIR/libcacaSB.patch.gz |patch libcaca.SlackBuild --verbose
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

execute_libusb () {
#******************************************************************
if [ ! -f $SRCDIR/l/libusb/libusb.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libusb/libusb.SlackBuild \
		$SRCDIR/l/libusb/libusb.SlackBuild.old
	(
		cd $SRCDIR/l/libusb
		zcat $PATCHDIR/libusbSB.patch.gz |patch libusb.SlackBuild  --verbose
	)
fi
}

execute_llvm () {
#******************************************************************
if [ ! -f $SRCDIR/d/llvm/llvm.SlackBuild.old ]; then
	cp -v $SRCDIR/d/llvm/llvm.SlackBuild $SRCDIR/d/llvm/llvm.SlackBuild.old
	(
		cd $SRCDIR/d/llvm
		zcat $PATCHDIR/llvmSB.patch.gz |patch llvm.SlackBuild --verbose
	)
fi
}

execute_mesa () {
#******************************************************************
if [ ! -f $SRCDIR/x/mesa/mesa.SlackBuild.old ]; then
	cp -v $SRCDIR/x/mesa/mesa.SlackBuild $SRCDIR/x/mesa/mesa.SlackBuild.old
	(
		cd $SRCDIR/x/mesa
		zcat $PATCHDIR/mesaSB.patch.gz |patch mesa.SlackBuild --verbose
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

execute_qscint () {
#******************************************************************
if [ ! -f $SRCDIR/l/QScintilla/QScintilla.SlackBuild.old ]; then
	cp -v $SRCDIR/l/QScintilla/QScintilla.SlackBuild \
		$SRCDIR/l/QScintilla/QScintilla.SlackBuild.old
	(
		cd $SRCDIR/l/QScintilla
		zcat $PATCHDIR/QScintillaSB.patch.gz |patch QScintilla.SlackBuild --verbose
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

execute_subversion () {
#******************************************************************
if [ ! -f $SRCDIR/d/subversion/subversion.SlackBuild.old ]; then
	cp -v $SRCDIR/d/subversion/subversion.SlackBuild \
		$SRCDIR/d/subversion/subversion.SlackBuild.old
	(
		cd $SRCDIR/d/subversion
		zcat $PATCHDIR/subversionSB.patch.gz |patch subversion.SlackBuild --verbose
	)
fi
}

execute_texlive () {
#******************************************************************
if [ ! -f $SRCDIR/t/texlive/texlive.SlackBuild.old ]; then
	cp -v $SRCDIR/t/texlive/texlive.SlackBuild $SRCDIR/t/texlive/texlive.SlackBuild.old
	(
		cd $SRCDIR/t/texlive
		zcat $PATCHDIR/texliveSB.patch.gz |patch texlive.SlackBuild --verbose
	)
fi
}

execute_xfce () {
#******************************************************************
if [ ! -f $SRCDIR/xfce/xfce-build-all.sh.old ]; then
	cp -v $SRCDIR/xfce/xfce-build-all.sh  $SRCDIR/xfce/xfce-build-all.sh.old 
	(
		cd $SRCDIR/xfce
		zcat $PATCHDIR/xfce-build-all.patch.gz |patch xfce-build-all.sh --verbose
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
		patch_dbus_c
		patch_findutils_c
		patch_fontconfig_c
		patch_freetype_c
		patch_gd_c
		patch_harfbuzz_c
		patch_kmod_c
		patch_libcaca_c
		patch_libusb_c
		patch_llvm_c
		patch_mesa_c
		patch_pkg_config_c
		patch_qscint_c
		patch_readline_c
		patch_subversion_c
		patch_texlive_c
		patch_xfce_c
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
		execute_dbus # 2 pass
		execute_findutils # 2 pass
		execute_fontconfig # 2 pass
		execute_freetype # 2 pass
		execute_gd # 2 pass
		execute_harfbuzz # 2 pass
		execute_kmod # 2 pass
		execute_libcaca # 2 pass
		execute_libusb # 2 pass
		execute_llvm # 2 pass
		execute_mesa # 2 pass
		execute_pkg_config # 2 pass
		execute_qscint # 2 pass
		execute_readline # 2 pass
		execute_subversion # 2 pass
		execute_texlive # 2 pass
		execute_xfce
		break
	elif [[ "$sources_alteration" = "no" ]]
	then
		echo
		echo "You decided to keep the slackware sources."
		echo "The building of slackware may not build completely."
		echo "Or you've not uograded the slacksrc it should be ok"
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

#************************************************************************
#************************************************************************
# MAIN CORE SCRIPT
#************************************************************************
#************************************************************************

#**************************************
# before everything we test if we are root
#**************************************
test_root
. export_variables_perso.sh
. export_variables.sh
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
		echo -e "$RED" "You choose to rsync slacksrc directly from a slackware mirror." "$NORMAL"
		echo
		cd $SFS/sources
		rsync_src
		populate_others
		break
	elif [[ "$upgrade_type" = "local" ]]
	then
		echo
		echo  -e "$RED" "You choose to rsync slacksrc from a local mirror." "$NORMAL"
		echo 
		upgrade_src
		populate_others
		break
	elif [[ "$upgrade_type" = "DVD" ]]
	then
		echo
		echo  -e "$RED" "You choose to rsync slacksrc from a local DVD or BluRay." "$NORMAL"
		echo 
		mount -t auto /dev/sr0 /mnt/dvd && sleep 5 && echo -e "$RED" "DVD mounted on /mnt/DVD" "$NORMAL"
		upgrade_dvd
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
#***********************************************************
# Making adjustments to sources
#***********************************************************
cd $SFS/sources
sources_alteration_c
#***********************************************************
cd $SFS/sources
. lists_generator_c.sh
. prep-sfs-tools.sh
#*************************************
# finally chroot in $SFS environment
#*************************************
. chroot_sfs.sh
exit 0
