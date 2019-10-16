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
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
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
			echo -e "$BLUE" "You chose $tools_dir" "$NORMAL"
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
echo -e "$BLUE" "You chose $distribution."  "$NORMAL" 
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
			wget -c -v $DLDIR3/slackware/l/readline-6.3-i586-2.txz
		fi
		if [ ! -f libpng-1.4.12-i486-1.txz ]; then
			wget -c -v $DLDIR2/slackware/l/libpng-1.4.12-i486-1.txz
		fi
		if [ ! -f ksh93-2012_08_01-i586-2.txz ]; then
			wget -c -v $DLDIR3/slackware/ap/ksh93-2012_08_01-i586-2.txz
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
		cd $SRCDIR/others
		if [ ! -f readline-7.0.005-i586-1.txz ]; then
			wget -c -v $DLDIR12/readline-7.0.005-i586-1.txz
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
		cd $SRCDIR/others
		if [ ! -f readline-7.0.005-x86_64-1.txz ]; then
			wget -c -v $DLDIR12/readline-7.0.005-x86_64-1.txz
		fi
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
--- cmake.SlackBuild.old	2019-07-19 15:56:49.099995746 +0200
+++ cmake.SlackBuild	2019-07-19 21:08:14.298792238 +0200
@@ -82,7 +82,6 @@
   --prefix=/usr \
   --docdir=/doc/$PKGNAM-$VERSION \
   --parallel=$(echo $NUMJOBS | cut -f 2 -d j | tr -d ' ') \
-  --qt-gui \
   --system-curl \
   --system-expat \
   --no-system-jsoncpp \
EOF
}

patch_findutils_c () {
#******************************************************************
cat > $PATCHDIR/findutilsSB.patch << "EOF"
--- findutils.SlackBuild.old	2019-08-31 14:00:08.376145372 +0200
+++ findutils.SlackBuild	2019-08-31 15:28:02.130125255 +0200
@@ -77,12 +77,12 @@
 # Don't output warnings by default.  Let's make the crazy assumption that the
 # user actually does know what they are doing, and will use -warn if they'd
 # like to be yelled at.
-zcat $CWD/findutils.no.default.options.warnings.diff.gz | patch -p1 --verbose || exit 1
+# zcat $CWD/findutils.no.default.options.warnings.diff.gz | patch -p1 --verbose || exit 1
 
 # Don't include updatedb, locate, frcode:
-zcat $CWD/findutils.nolocate.diff.gz | patch -p1 --verbose || exit 1
+# zcat $CWD/findutils.nolocate.diff.gz | patch -p1 --verbose || exit 1
 
-autoreconf -vif
+# autoreconf -vif
 
 CFLAGS="$SLKCFLAGS" \
 ./configure \
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

patch_glib2_c () {
#******************************************************************
cat > $PATCHDIR/glib2SB.patch << "EOF"
--- glib2.SlackBuild.old	2019-07-22 20:40:21.806143611 +0000
+++ glib2.SlackBuild	2019-07-22 20:40:21.817143611 +0000
@@ -98,9 +98,9 @@
   --localstatedir=/var \
   --buildtype=release \
   -Dselinux=disabled \
-  -Dfam=true \
-  -Dman=true \
-  -Dgtk_doc=true \
+  -Dfam=false \
+  -Dman=false \
+  -Dgtk_doc=false \
   -Dinstalled_tests=false \
   .. || exit 1
   "${NINJA:=ninja}" $NUMJOBS || exit 1
EOF
}

patch_gobject_c () {
#******************************************************************
cat > $PATCHDIR/gobject-introspectionSB.patch << "EOF"
--- gobject-introspection.SlackBuild.old	2019-09-25 04:53:51.990319000 +0000
+++ gobject-introspection.SlackBuild	2019-09-25 04:18:36.198262779 +0000
@@ -104,7 +104,7 @@
   --sysconfdir=/etc \
   --localstatedir=/var \
   --buildtype=release \
-  -Dgtk_doc=true \
+  -Dgtk_doc=false \
   .. || exit 1
   "${NINJA:=ninja}" $NUMJOBS || exit 1
   DESTDIR=$PKG $NINJA install || exit 1
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
--- libcaca.SlackBuild.old	2019-02-23 08:53:08.160995822 +0100
+++ libcaca.SlackBuild	2019-02-23 20:38:05.346867197 +0100
@@ -25,6 +25,12 @@
 PKGNAM=libcaca
 VERSION=${VERSION:-$(echo $PKGNAM-*.tar.?z* | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
 BUILD=${BUILD:-4}
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
--- llvm.SlackBuild.old	2019-10-01 16:44:17.175010877 +0000
+++ llvm.SlackBuild	2019-10-01 16:47:17.085015694 +0000
@@ -136,8 +136,8 @@
 mkdir build
 cd build
   cmake -GNinja \
-    -DCMAKE_C_COMPILER="clang" \
-    -DCMAKE_CXX_COMPILER="clang++" \
+    -DCMAKE_C_COMPILER="gcc" \
+    -DCMAKE_CXX_COMPILER="g++" \
     -DCMAKE_C_FLAGS:STRING="$SLKCFLAGS" \
     -DCMAKE_CXX_FLAGS:STRING="$SLKCFLAGS" \
     -DCMAKE_INSTALL_PREFIX=/usr \
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
--- QScintilla.SlackBuild.old	2019-08-02 08:23:09.958969743 +0200
+++ QScintilla.SlackBuild	2019-08-02 08:28:06.846968611 +0200
@@ -128,8 +128,8 @@
       --pyqt=PyQt5 \
       -n ../Qt4Qt5/ -o ../Qt4Qt5/ -c \
       || exit 1
-    make  || exit 1
-    make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG || exit 1
+    make
+    make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG
 
     make clean || exit 1
 
@@ -139,8 +139,8 @@
       --pyqt=PyQt5 \
       -n ../Qt4Qt5/ -o ../Qt4Qt5/ -c \
       || exit 1
-    make  || exit 1
-    make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG || exit 1
+    make
+    make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG
   cd -
 
   # In order to compile Qt4 support next, clean up first:
EOF
}

patch_readline_c () {
#******************************************************************
cat > $PATCHDIR/readlineSB.patch << "EOF"
--- readline.SlackBuild.old	2019-07-22 20:40:21.926143614 +0000
+++ readline.SlackBuild	2019-07-22 20:40:21.935143614 +0000
@@ -102,26 +102,10 @@
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
--- subversion.SlackBuild.old	2019-07-22 20:40:21.941143615 +0000
+++ subversion.SlackBuild	2019-07-22 20:40:21.949143615 +0000
@@ -98,7 +98,6 @@
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
--- texlive.SlackBuild.old	2019-06-29 10:09:09.060998512 +0200
+++ texlive.SlackBuild	2019-06-29 14:31:39.012938430 +0200
@@ -123,11 +123,13 @@
     --disable-dialog \
     --disable-bibtexu \
     --disable-xz \
-    --with-x \
+    --without-x \
     --disable-dvisvgm \
-    --enable-xindy \
+    --disable-xindy \
     --disable-xindy-docs \
     --disable-xindy-rules \
+    --disable-web2c \
+    --disable-xetex \
     --with-clisp-runtime=system \
     --enable-gc=system \
     --with-system-zlib \
@@ -137,12 +139,11 @@
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
--- freetype.SlackBuild.old	2019-07-22 20:40:21.779143610 +0000
+++ freetype.SlackBuild	2019-07-22 20:40:21.788143611 +0000
@@ -113,8 +113,14 @@
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
--- harfbuzz.SlackBuild.old	2019-07-22 20:40:21.822143611 +0000
+++ harfbuzz.SlackBuild	2019-07-22 20:40:21.829143612 +0000
@@ -92,8 +92,12 @@
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
		zcat $PATCHDIR/cmakeSB.patch.gz |patch cmake.SlackBuild  --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/d/cmake/cmake.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_cmake_sed () {
#******************************************************************
if [ ! -f $SRCDIR/d/cmake/cmake.SlackBuild.old ]; then
	cp -v $SRCDIR/d/cmake/cmake.SlackBuild $SRCDIR/d/cmake/cmake.SlackBuild.old
	(
		cd $SRCDIR/d/cmake
		sed -i -e '/--qt-gui/d' cmake.SlackBuild
	)
fi
}

execute_dbus () {
#******************************************************************
if [ ! -f $SRCDIR/a/dbus/dbus.SlackBuild.old ]; then
	cp -v $SRCDIR/a/dbus/dbus.SlackBuild $SRCDIR/a/dbus/dbus.SlackBuild.old
	(
		cd $SRCDIR/a/dbus
		zcat $PATCHDIR/dbusSB.patch.gz |patch dbus.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/a/dbus/dbus.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_dbus_sed () {
#******************************************************************
if [ ! -f $SRCDIR/a/dbus/dbus.SlackBuild.old ]; then
	cp -v $SRCDIR/a/dbus/dbus.SlackBuild $SRCDIR/a/dbus/dbus.SlackBuild.old
	(
		cd $SRCDIR/a/dbus
		sed -i -e '/--enable-x11-autolaunch/d' dbus.SlackBuild
	)
fi
}

execute_findutils () {
#******************************************************************
if [ ! -f $SRCDIR/a/findutils/findutils.SlackBuild.old ]; then
	cp -v $SRCDIR/a/findutils/findutils.SlackBuild $SRCDIR/a/findutils/findutils.SlackBuild.old
	(
		cd $SRCDIR/a/findutils
		zcat $PATCHDIR/findutilsSB.patch.gz |patch findutils.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/a/findutils/findutils.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_findutils_sed () {
#******************************************************************
if [ ! -f $SRCDIR/a/findutils/findutils.SlackBuild.old ]; then
	cp -v $SRCDIR/a/findutils/findutils.SlackBuild $SRCDIR/a/findutils/findutils.SlackBuild.old
	(
		cd $SRCDIR/a/findutils
		sed -i -e 's/zcat/# zcat/g' findutils.SlackBuild
		sed -i -e 's/autoreconf/# autoreconf/g' findutils.SlackBuild
	)
fi
}

execute_fontconfig  () {
#******************************************************************
if [ ! -f $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old ]; then
	cp -v $SRCDIR/x/fontconfig/fontconfig.SlackBuild $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old
	(
		cd $SRCDIR/x/fontconfig
		zcat $PATCHDIR/fontconfigSB.patch.gz |patch fontconfig.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/x/fontconfig/fontconfig.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_fontconfig_sed () {
#******************************************************************
if [ ! -f $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old ]; then
	cp -v $SRCDIR/x/fontconfig/fontconfig.SlackBuild $SRCDIR/x/fontconfig/fontconfig.SlackBuild.old
	(
		cd $SRCDIR/x/fontconfig
		sed -i -e '/--sysconfdir/p' fontconfig.SlackBuild
		sed -i -e '0,/sysconfdir/ s/sysconfdir=\/\etc/disable-docs/' fontconfig.SlackBuild
	)
fi
}

execute_freetype () {
#******************************************************************
if [ ! -f $SRCDIR/l/freetype/freetype.SlackBuild.old ]; then
	cp -v $SRCDIR/l/freetype/freetype.SlackBuild $SRCDIR/l/freetype/freetype.SlackBuild.old
	(
		cd $SRCDIR/l/freetype
		zcat $PATCHDIR/freetypeSB.patch.gz |patch freetype.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/freetype/freetype.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_freetype_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/freetype/freetype.SlackBuild.old ]; then
	cp -v $SRCDIR/l/freetype/freetype.SlackBuild $SRCDIR/l/freetype/freetype.SlackBuild.old
	(
		cd $SRCDIR/l/freetype
		sed -i -e 's/make $NUMJOBS || make || exit 1/make $NUMJOBS/' freetype.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' freetype.SlackBuild
		sed -i -e '/make install DESTDIR=$PKG/p' freetype.SlackBuild
		sed -i -e '0,/make install DESTDIR=$PKG/ s/make install DESTDIR=$PKG/make/' freetype.SlackBuild
		sed -i -e '/make install DESTDIR=$PKG/a # install freetype headers to build harfbuzz/' freetype.SlackBuild
		sed -i -e '/# install freetype headers/a mkdir -pv $PKG/usr/include/freetype2/' freetype.SlackBuild
		sed -i -e '/mkdir -pv/a cp devel/ft2build.h $PKG/usr/include/freetype2/ft2build.h' freetype.SlackBuild
		sed -i -e '/cp devel\/\ft2build.h/a cp devel/ftoption.h $PKG/usr/include/freetype2/ftoption.h' freetype.SlackBuild
		sed -i -e '/ft2build.h/a cp devel/ftoption.h $PKG/usr/include/freetype2/ftoption.h' freetype.SlackBuild
	)
fi
}

execute_gd () {
#******************************************************************
if [ ! -f $SRCDIR/l/gd/gd.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gd/gd.SlackBuild $SRCDIR/l/gd/gd.SlackBuild.old
	(
		cd $SRCDIR/l/gd
		zcat $PATCHDIR/gdSB.patch.gz |patch gd.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/gd/gd.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_gd_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/gd/gd.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gd/gd.SlackBuild $SRCDIR/l/gd/gd.SlackBuild.old
	(
		cd $SRCDIR/l/gd
		sed -i -e '/--disable-static/p' gd.SlackBuild
		sed -i -e '/--program-prefix=/p' gd.SlackBuild
		sed -i -e '0,/disable-static/ s/disable-static/without-fontconfig/' gd.SlackBuild
		sed -i -e '0,/program-prefix=/ s/program-prefix=/without-xpm/' gd.SlackBuild
		sed -i -e 's/make $NUMJOBS || make || exit 1/make $NUMJOBS || make/' gd.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' gd.SlackBuild
	)
fi
}

execute_glib2 () {
#******************************************************************
if [ ! -f $SRCDIR/l/glib2/glib2.SlackBuild.old ]; then
	cp -v $SRCDIR/l/glib2/glib2.SlackBuild $SRCDIR/l/glib2/glib2.SlackBuild.old
	(
		cd $SRCDIR/l/glib2
		zcat $PATCHDIR/glib2SB.patch.gz |patch glib2.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/glib2/glib2.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_glib2_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/glib2/glib2.SlackBuild.old ]; then
	cp -v $SRCDIR/l/glib2/glib2.SlackBuild $SRCDIR/l/glib2/glib2.SlackBuild.old
	(
		cd $SRCDIR/l/glib2
		sed -i -e 's/true/false/g' glib2.SlackBuild
	)
fi
}

execute_gobject () {
#******************************************************************
if [ ! -f $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild.old
	(
		cd $SRCDIR/l/gobject-introspection
		zcat $PATCHDIR/gobject-introspectionSB.patch.gz |patch gobject-introspection.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_gobject_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild.old ]; then
	cp -v $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild $SRCDIR/l/gobject-introspection/gobject-introspection.SlackBuild.old
	(
		cd $SRCDIR/l/gobject-introspection
		sed -i -e 's/true/false/' gobject-introspection.SlackBuild
	)
fi
}

execute_harfbuzz () {
#******************************************************************
if [ ! -f $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.old ]; then
	cp -v $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.old
	(
		cd $SRCDIR/l/harfbuzz
		zcat $PATCHDIR/harfbuzzSB.patch.gz |patch harfbuzz.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.rej  ]; then 
	exit 1
fi
}

execute_harfbuzz_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.old ]; then
	cp -v $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild $SRCDIR/l/harfbuzz/harfbuzz.SlackBuild.old
	(
		cd $SRCDIR/l/harfbuzz
		sed -i -e 's/make $NUMJOBS || make || exit 1/make $NUMJOBS || make/' harfbuzz.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' harfbuzz.SlackBuild
		sed -i -e '/make install DESTDIR=$PKG/a # install harfbuzz headers to build freetype/' harfbuzz.SlackBuild
		sed -i -e '/# install harfbuzz/a mkdir -pv $PKG/usr/include/harfbuzz' harfbuzz.SlackBuild
		sed -i -e '/mkdir -pv $PKG/a cp src/*.h $PKG/usr/include/harfbuzz' harfbuzz.SlackBuild
	)
fi
}

execute_kmod () {
#******************************************************************
if [ ! -f $SRCDIR/a/kmod/kmod.SlackBuild.old ]; then
	cp -v $SRCDIR/a/kmod/kmod.SlackBuild $SRCDIR/a/kmod/kmod.SlackBuild.old
	(
		cd $SRCDIR/a/kmod
		zcat $PATCHDIR/kmodSB.patch.gz |patch kmod.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/a/kmod/kmod.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_kmod_sed () {
#******************************************************************
if [ ! -f $SRCDIR/a/kmod/kmod.SlackBuild.old ]; then
	cp -v $SRCDIR/a/kmod/kmod.SlackBuild $SRCDIR/a/kmod/kmod.SlackBuild.old
	(
		cd $SRCDIR/a/kmod
		sed -i -e 's/make || exit 1/make/' kmod.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' kmod.SlackBuild
	)
fi
}

execute_libcaca () {
#******************************************************************
if [ ! -f $SRCDIR/l/libcaca/libcaca.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libcaca/libcaca.SlackBuild $SRCDIR/l/libcaca/libcaca.SlackBuild.old
	(
		cd $SRCDIR/l/libcaca
		zcat $PATCHDIR/libcacaSB.patch.gz |patch libcaca.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/libcaca/libcaca.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_libcaca_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/libcaca/libcaca.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libcaca/libcaca.SlackBuild $SRCDIR/l/libcaca/libcaca.SlackBuild.old
	(
		cd $SRCDIR/l/libcaca
		sed -i -e '/BUILD=${BUILD:/a LCAC=${LCAC:-1}' libcaca.SlackBuild
		sed -i -e '/LCAC=${LCAC:-1}/a if [ $LCAC == 1 ]; then' libcaca.SlackBuild
		sed -i -e '/$LCAC == 1/a 	JAVAENABLE="disable"' libcaca.SlackBuild
		sed -i -e 's/JAVAENABLE="disable"/  JAVAENABLE="disable"/' libcaca.SlackBuild
		sed -i -e '/JAVAENABLE="disable"/a 		JAVAENABLE="enable"' libcaca.SlackBuild
		sed -i -e 's/JAVAENABLE="enable"/  JAVAENABLE="enable"/' libcaca.SlackBuild
		sed -i -e '/JAVAENABLE="disable"/a 	else' libcaca.SlackBuild
		sed -i -e '/JAVAENABLE="enable"/a fi' libcaca.SlackBuild
		sed -i -e '/disable-ruby/p' libcaca.SlackBuild
		sed -i -e '0,/disable-ruby/! s/disable-ruby/$JAVAENABLE-java/' libcaca.SlackBuild
		sed -i -e 's/setup.py install --root=$PKG || exit 1/setup.py install --root=$PKG/' libcaca.SlackBuild
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
		zcat $PATCHDIR/libusbSB.patch.gz |patch libusb.SlackBuild  --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/libusb/libusb.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_libusb_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/libusb/libusb.SlackBuild.old ]; then
	cp -v $SRCDIR/l/libusb/libusb.SlackBuild \
		$SRCDIR/l/libusb/libusb.SlackBuild.old
	(
		cd $SRCDIR/l/libusb
		sed -i -e '/--disable-static/p' libusb.SlackBuild
		sed -i -e '0,/disable-static/ s/static/udev/' libusb.SlackBuild
	)
fi
}

execute_llvm () {
#******************************************************************
if [ ! -f $SRCDIR/d/llvm/llvm.SlackBuild.old ]; then
	cp -v $SRCDIR/d/llvm/llvm.SlackBuild $SRCDIR/d/llvm/llvm.SlackBuild.old
	(
		cd $SRCDIR/d/llvm
		zcat $PATCHDIR/llvmSB.patch.gz |patch llvm.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/d/llvm/llvm.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_llvm_sed () {
#******************************************************************
if [ ! -f $SRCDIR/d/llvm/llvm.SlackBuild.old ]; then
	cp -v $SRCDIR/d/llvm/llvm.SlackBuild $SRCDIR/d/llvm/llvm.SlackBuild.old
	(
		cd $SRCDIR/d/llvm
		sed -i -e 's/"clang++"/"g++"/' llvm.SlackBuild
		sed -i -e 's/"clang"/"gcc"/' llvm.SlackBuild
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
		zcat $PATCHDIR/pkg-configSB.patch.gz |patch pkg-config.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/d/pkg-config/pkg-config.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_pkg_config_sed() {
#******************************************************************
if [ ! -f $SRCDIR/d/pkg-config/pkg-config.SlackBuild.old ]; then
	cp -v $SRCDIR/d/pkg-config/pkg-config.SlackBuild \
		$SRCDIR/d/pkg-config/pkg-config.SlackBuild.old
	(
		cd $SRCDIR/d/pkg-config
		sed -i -e '/--prefix=\/\usr/p' pkg-config.SlackBuild
		sed -i -e '0,/--prefix=\/\usr/ s/--prefix=\/\usr/--with-internal-glib/' pkg-config.SlackBuild
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
		zcat $PATCHDIR/QScintillaSB.patch.gz |patch QScintilla.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/QScintilla/QScintilla.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_qscint_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/QScintilla/QScintilla.SlackBuild.old ]; then
	cp -v $SRCDIR/l/QScintilla/QScintilla.SlackBuild \
		$SRCDIR/l/QScintilla/QScintilla.SlackBuild.old
	(
		cd $SRCDIR/l/QScintilla
		sed -i -e 's/make  || exit 1/make/' QScintilla.SlackBuild
		sed -i -e 's/make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG || exit 1/make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG/' QScintilla.SlackBuild
	)
fi
}

execute_readline () {
#******************************************************************
if [ ! -f $SRCDIR/l/readline/readline.SlackBuild.old ]; then
	cp -v $SRCDIR/l/readline/readline.SlackBuild $SRCDIR/l/readline/readline.SlackBuild.old
	(
		cd $SRCDIR/l/readline
		zcat $PATCHDIR/readlineSB.patch.gz |patch readline.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/l/readline/readline.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_readline_sed () {
#******************************************************************
if [ ! -f $SRCDIR/l/readline/readline.SlackBuild.old ]; then
	cp -v $SRCDIR/l/readline/readline.SlackBuild $SRCDIR/l/readline/readline.SlackBuild.old
	(
		cd $SRCDIR/l/readline
		sed -i -e '/make $NUMJOBS static shared SHLIB_LIBS=-ltinfo/d' readline.SlackBuild
		sed -i -e '/# Link with libtinfo:/a make $NUMJOBS static' readline.SlackBuild
		sed -i -e '/# build rlfe/,+16d' readline.SlackBuild
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
		zcat $PATCHDIR/subversionSB.patch.gz |patch subversion.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/d/subversion/subversion.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_subversion_sed () {
#******************************************************************
if [ ! -f $SRCDIR/d/subversion/subversion.SlackBuild.old ]; then
	cp -v $SRCDIR/d/subversion/subversion.SlackBuild \
		$SRCDIR/d/subversion/subversion.SlackBuild.old
	(
		cd $SRCDIR/d/subversion
		sed -i -e '/--with-kwallet/d' subversion.SlackBuild
	)
fi
}

execute_texlive () {
#******************************************************************
if [ ! -f $SRCDIR/t/texlive/texlive.SlackBuild.old ]; then
	cp -v $SRCDIR/t/texlive/texlive.SlackBuild $SRCDIR/t/texlive/texlive.SlackBuild.old
	(
		cd $SRCDIR/t/texlive
		zcat $PATCHDIR/texliveSB.patch.gz |patch texlive.SlackBuild --verbose || exit 1
	)
fi
# exit if patch is rejected
if [ -f $SRCDIR/t/texlive/texlive.SlackBuild.rej ]; then 
	exit 1
fi
}

execute_texlive_sed () {
#******************************************************************
if [ ! -f $SRCDIR/t/texlive/texlive.SlackBuild.old ]; then
	cp -v $SRCDIR/t/texlive/texlive.SlackBuild $SRCDIR/t/texlive/texlive.SlackBuild.old
	(
		cd $SRCDIR/t/texlive
		sed -i -e 's/with-x/without-x/' texlive.SlackBuild
		sed -i -e 's/enable-xindy/disable-xindy/' texlive.SlackBuild
		sed -i -e 's/with-system-pixman/without-system-pixman/' texlive.SlackBuild
		sed -i -e 's/with-system-cairo/without-system-cairo/' texlive.SlackBuild
		sed -i -e 's/with-system-gmp/without-system-gmp/' texlive.SlackBuild
		sed -i -e 's/with-system-mpfr/without-system-mpfr/' texlive.SlackBuild
		sed -i -e 's/with-system-fontconfig/without-system-fontconfig/' texlive.SlackBuild
		sed -i -e '/disable-xindy-rules/p' texlive.SlackBuild
		sed -i -e '0,/disable-xindy-rules/ s/disable-xindy-rules/disable-web2c/' texlive.SlackBuild
		sed -i -e '/disable-web2c/p' texlive.SlackBuild
		sed -i -e '0,/disable-web2c/ s/disable-web2c/disable-xetex/' texlive.SlackBuild
	)
fi
}

execute_xfce () {
#******************************************************************
if [ ! -f $SRCDIR/xfce/xfce-build-all.sh.old ]; then
	cp -v $SRCDIR/xfce/xfce-build-all.sh  $SRCDIR/xfce/xfce-build-all.sh.old 
	(
		cd $SRCDIR/xfce
		zcat $PATCHDIR/xfce-build-all.patch.gz |patch xfce-build-all.sh --verbose || exit 1
	)
fi
}

execute_xfce_sed () {
#******************************************************************
if [ ! -f $SRCDIR/xfce/xfce-build-all.sh.old ]; then
	cp -v $SRCDIR/xfce/xfce-build-all.sh  $SRCDIR/xfce/xfce-build-all.sh.old 
	(
		cd $SRCDIR/xfce
		sed -i -e '/cd $package || exit 1/a .\/\${package}.SlackBuild/' xfce-build-all.sh
		sed -i -e '/{package}.failed ; exit 1 ) || exit 1/d' xfce-build-all.sh
		sed -i -e '/${package}.SlackBuild/a [ $? != 0 ] && touch /tmp/${package}.failed' xfce-build-all.sh
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
		patch_glib2_c
		patch_gobject_c
		patch_harfbuzz_c
		patch_kmod_c
 		patch_libcaca_c
		patch_libusb_c
		patch_llvm_c
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
echo -e "$RED" "You chose $build_patches." "$NORMAL" && echo
echo 

}

sources_alteration_c () {
#**********************************
# alteration of the slackware sources
	execute_cmake # 2 pass
	execute_dbus # 2 pass
	execute_findutils # 2 pass
	execute_fontconfig # 2 pass
	execute_freetype # 2 pass
	execute_gd # 2 pass
	execute_glib2 # 2 pass
	execute_gobject # 2 pass
	execute_harfbuzz # 2 pass
	execute_kmod # 2 pass
	execute_libcaca # 2 pass
	execute_libusb # 2 pass
	execute_llvm # 2 pass
	execute_pkg_config # 2 pass
	execute_qscint # 2 pass
	execute_readline # 2 pass
	execute_subversion # 2 pass
	execute_texlive # 2 pass
	execute_xfce # 2 pass

}

sources_alteration_sed () {
#**********************************
# alteration of the slackware sources
	execute_cmake_sed # 2 pass
	execute_dbus_sed # 2 pass
	execute_findutils_sed # 2 pass
	execute_fontconfig_sed # 2 pass
	execute_freetype_sed # 2 pass
	execute_gd_sed # 2 pass
	execute_glib2_sed # 2 pass
	execute_gobject_sed # 2 pass
	execute_harfbuzz_sed # 2 pass
	execute_kmod_sed # 2 pass
	execute_libcaca_sed # 2 pass
	execute_libusb_sed # 2 pass
	execute_llvm_sed # 2 pass
	execute_pkg_config_sed # 2 pass
	execute_qscint_sed # 2 pass
	execute_readline_sed # 2 pass
	execute_subversion_sed # 2 pass
	execute_texlive_sed # 2 pass
	execute_xfce_sed # 2 pass

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
# patches_generator_c

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
		populate_others
		break
	elif [[ "$upgrade_type" = "local" ]]
	then
		echo
		echo  -e "$RED" "You chose to rsync slacksrc from a local mirror." "$NORMAL"
		echo 
		upgrade_src
		populate_others
		break
	elif [[ "$upgrade_type" = "DVD" ]]
	then
		echo
		echo  -e "$RED" "You chose to rsync slacksrc from a local DVD or BluRay." "$NORMAL"
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
# sources_alteration_c
sources_alteration_sed
#***********************************************************
cd $SFS/sources
. lists_generator_c.sh
. prep-sfs-tools.sh
#*************************************
# finally chroot in $SFS environment
#*************************************
. chroot_sfs.sh
exit 0
