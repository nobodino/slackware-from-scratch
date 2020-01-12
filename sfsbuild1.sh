
################################  sfsbuild1.sh #################################
#!/bin/bash
#
# Copyright 2018,2019,2020  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018,2019,2020  "nobodino", Bordeaux, FRANCE
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
# Note: The adjust and link_tools procedures of this script are 
#       inspired from the LFS manual chapter 6.10
#       Copyright © 1999-2019 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
#
#	sfsbuild1.sh
#
#	This script builds part of the Slackware from Scratch system using the
#	source directory from the Slackware sources
#
#	Above july 2018, revisions made through github project:
#
#   https://github.com/nobodino/slackware-from-scratch 
#
############################################################################
# set -x
#*********************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#**********************************
export SLACKSRC=/slacksrc
#**********************************
on_error () {
#***********************************************************
# recalls the usage of the main script in case of error
#***********************************************************
echo 	"Usage: sfsbuild1.sh build1.list"
echo
echo	"The build.list of programs to build, and their source directories is required."
echo
echo	"The packages will not be processed until the end of the build{1,4}.list."
echo
exit -1
}

adjust_i686 () {
#***********************************************************
# First, backup the /tools linker, and replace it with the
# adjusted linker we made in chapter 5. We'll also create a
# link to its counterpart in /tools/$(gcc -dumpmachine)/bin:
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2018 Gerard Beekmans and may be
#       copied under the MIT License.
#***********************************************************
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
#***********************************************************
# Next, amend the GCC specs file so that it points to the
# new dynamic linker. Simply deleting all instances of
# '/tools' should leave us with the correct path to the
# dynamic linker. Also adjust the specs file so that GCC
# knows where to find the correct headers and Glibc start
# files. A sed command accomplishes this:
#***********************************************************
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
}

adjust_x86_64 () {
#***********************************************************
# First, backup the /tools linker, and replace it with the
# adjusted linker we made in chapter 5. We'll also create a
# link to its counterpart in /tools/$(gcc -dumpmachine)/bin:
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2018 Gerard Beekmans and may be
#       copied under the MIT License.
#***********************************************************
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
#***********************************************************
# Next, amend the GCC specs file so that it points to the
# new dynamic linker. Simply deleting all instances of
# '/tools' should leave us with the correct path to the
# dynamic linker. Also adjust the specs file so that GCC
# knows where to find the correct headers and Glibc start
# files. A sed command accomplishes this:
#***********************************************************
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib64/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
}

answer () {
#****************************
local testvar
read testvar
if [ "$testvar" != "" ]; then
	exit
fi
echo
}

#*******************************************************************
# sub-system of execution of patches on the fly
#*******************************************************************

execute_cmake_sed () {
#******************************************************************
# delete "--qt-gui" line in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/d/cmake/cmake.SlackBuild.old ]; then
	cp -v $SLACKSRC/d/cmake/cmake.SlackBuild $SLACKSRC/d/cmake/cmake.SlackBuild.old
	(
		cd $SLACKSRC/d/cmake
		sed -i -e '/--qt-gui/d' cmake.SlackBuild
	)
fi
}

execute_dbus_sed () {
#******************************************************************
# delete "--enable-x11-autolaunch" linein SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/a/dbus/dbus.SlackBuild.old ]; then
	cp -v $SLACKSRC/a/dbus/dbus.SlackBuild $SLACKSRC/a/dbus/dbus.SlackBuild.old
	(
		cd $SLACKSRC/a/dbus
		sed -i -e '/--enable-x11-autolaunch/d' dbus.SlackBuild
	)
fi
}

execute_findutils_sed () {
#******************************************************************
# disable the patch and autoreconf in SlackBuild
#******************************************************************
if [ ! -f /slacksrc/a/findutils/findutils.SlackBuild.old ]; then
	cp -v /slacksrc/a/findutils/findutils.SlackBuild /slacksrc/a/findutils/findutils.SlackBuild.old
	(
		cd /slacksrc/a/findutils
		sed -i -e 's/zcat/# zcat/g' findutils.SlackBuild
		sed -i -e 's/autoreconf/# autoreconf/g' findutils.SlackBuild
	)
fi
}

execute_fontconfig_sed () {
#******************************************************************
# add "--disable-docs" to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/x/fontconfig/fontconfig.SlackBuild.old ]; then
	cp -v $SLACKSRC/x/fontconfig/fontconfig.SlackBuild $SLACKSRC/x/fontconfig/fontconfig.SlackBuild.old
	(
		cd $SLACKSRC/x/fontconfig
		sed -i -e '/--sysconfdir/p' fontconfig.SlackBuild
		sed -i -e '0,/sysconfdir/! s/sysconfdir=\/\etc/disable-docs/' fontconfig.SlackBuild
	)
fi
}

execute_freetype_sed () {
#******************************************************************
# remove "exit 1" code and add headers (ft2build.h and ftoption.h) to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/freetype/freetype.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/freetype/freetype.SlackBuild $SLACKSRC/l/freetype/freetype.SlackBuild.old
	(
		cd $SLACKSRC/l/freetype
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

execute_gd_sed () {
#******************************************************************
# add "--without-fontconfig" and "--without-xpm" to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/gd/gd.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/gd/gd.SlackBuild $SLACKSRC/l/gd/gd.SlackBuild.old
	(
		cd $SLACKSRC/l/gd
		sed -i -e '/--disable-static/p' gd.SlackBuild
		sed -i -e '/--program-prefix=/p' gd.SlackBuild
		sed -i -e '0,/disable-static/ s/disable-static/without-fontconfig/' gd.SlackBuild
		sed -i -e '0,/program-prefix=/ s/program-prefix=/without-xpm/' gd.SlackBuild
		sed -i -e 's/make $NUMJOBS || make || exit 1/make $NUMJOBS || make/' gd.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' gd.SlackBuild
	)
fi
}

execute_glib2_sed () {
#******************************************************************
# change all "true" options to "false" options in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/glib2/glib2.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/glib2/glib2.SlackBuild $SLACKSRC/l/glib2/glib2.SlackBuild.old
	(
		cd $SLACKSRC/l/glib2
		sed -i -e 's/true/false/g' glib2.SlackBuild
	)
fi
}

execute_gobject_sed () {
#******************************************************************
# change all "true" options to "false" options in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/gobject-introspection/gobject-introspection.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/gobject-introspection/gobject-introspection.SlackBuild $SLACKSRC/l/gobject-introspection/gobject-introspection.SlackBuild.old
	(
		cd $SLACKSRC/l/gobject-introspection
		sed -i -e 's/true/false/' gobject-introspection.SlackBuild
	)
fi
}

execute_harfbuzz_sed () {
#******************************************************************
# remove "exit 1" code and add harfbuzz headers to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/harfbuzz/harfbuzz.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/harfbuzz/harfbuzz.SlackBuild $SLACKSRC/l/harfbuzz/harfbuzz.SlackBuild.old
	(
		cd $SLACKSRC/l/harfbuzz
		sed -i -e 's/make $NUMJOBS || make || exit 1/make $NUMJOBS || make/' harfbuzz.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' harfbuzz.SlackBuild
		sed -i -e '/make install DESTDIR=$PKG/a # install harfbuzz headers to build freetype/' harfbuzz.SlackBuild
		sed -i -e '/# install harfbuzz/a mkdir -pv $PKG/usr/include/harfbuzz' harfbuzz.SlackBuild
		sed -i -e '/mkdir -pv $PKG/a cp src/*.h $PKG/usr/include/harfbuzz' harfbuzz.SlackBuild
	)
fi
}

execute_kmod_sed () {
#******************************************************************
# remove "exit 1" code in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/a/kmod/kmod.SlackBuild.old ]; then
	cp -v $SLACKSRC/a/kmod/kmod.SlackBuild $SLACKSRC/a/kmod/kmod.SlackBuild.old
	(
		cd $SLACKSRC/a/kmod
		sed -i -e 's/make || exit 1/make/' kmod.SlackBuild
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' kmod.SlackBuild
	)
fi
}

execute_libcaca_sed () {
#******************************************************************
# remove "exit 1" code and add "--enable-java" option to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/libcaca/libcaca.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/libcaca/libcaca.SlackBuild $SLACKSRC/l/libcaca/libcaca.SlackBuild.old
	(
		cd $SLACKSRC/l/libcaca
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

execute_libusb_sed () {
#******************************************************************
# add "--disable-dev" to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/libusb/libusb.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/libusb/libusb.SlackBuild \
		$SLACKSRC/l/libusb/libusb.SlackBuild.old
	(
		cd $SLACKSRC/l/libusb
		sed -i -e '/--disable-static/p' libusb.SlackBuild
		sed -i -e '0,/disable-static/ s/static/udev/' libusb.SlackBuild
	)
fi
}

execute_llvm_sed () {
#******************************************************************
# change "clang++" to "g++" and "clang" to "gcc" in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/d/llvm/llvm.SlackBuild.old ]; then
	cp -v $SLACKSRC/d/llvm/llvm.SlackBuild $SLACKSRC/d/llvm/llvm.SlackBuild.old
	(
		cd $SLACKSRC/d/llvm
		sed -i -e 's/"clang++"/"g++"/' llvm.SlackBuild
		sed -i -e 's/"clang"/"gcc"/' llvm.SlackBuild
	)
fi
}

execute_pkg_config_sed () {
#******************************************************************
# add "--with-internel-glib" to SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/d/pkg-config/pkg-config.SlackBuild.old ]; then
	cp -v $SLACKSRC/d/pkg-config/pkg-config.SlackBuild \
		$SLACKSRC/d/pkg-config/pkg-config.SlackBuild.old
	(
		cd $SLACKSRC/d/pkg-config
		sed -i -e '/--prefix=\/\usr/p' pkg-config.SlackBuild
		sed -i -e '0,/--prefix=\/\usr/ s/--prefix=\/\usr/--with-internal-glib/' pkg-config.SlackBuild
	)
fi
}

execute_qscint_sed () {
#******************************************************************
# remove "exit 1" code in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/QScintilla/QScintilla.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/QScintilla/QScintilla.SlackBuild \
		$SLACKSRC/l/QScintilla/QScintilla.SlackBuild.old
	(
		cd $SLACKSRC/l/QScintilla
		sed -i -e 's/make  || exit 1/make/' QScintilla.SlackBuild
		sed -i -e 's/make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG || exit 1/make -j1 install DESTDIR=$PKG INSTALL_ROOT=$PKG/' QScintilla.SlackBuild
	)
fi
}

execute_readline_sed () {
#******************************************************************
# disable shared SHLIBS code in SlackBuild
# delete examples/rlfe lines in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/l/readline/readline.SlackBuild.old ]; then
	cp -v $SLACKSRC/l/readline/readline.SlackBuild $SLACKSRC/l/readline/readline.SlackBuild.old
	(
		cd $SLACKSRC/l/readline
		sed -i -e '/make $NUMJOBS static shared SHLIB_LIBS=-ltinfo/d' readline.SlackBuild
		sed -i -e '/# Link with libtinfo:/a make $NUMJOBS static' readline.SlackBuild
		sed -i -e '/# build rlfe/,+16d' readline.SlackBuild
	)
fi
}

execute_subversion_sed () {
#******************************************************************
# delete "--with-kwallet" line in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/d/subversion/subversion.SlackBuild.old ]; then
	cp -v $SLACKSRC/d/subversion/subversion.SlackBuild \
		$SLACKSRC/d/subversion/subversion.SlackBuild.old
	(
		cd $SLACKSRC/d/subversion
		sed -i -e '/--with-kwallet/d' subversion.SlackBuild
	)
fi
}

execute_texlive_sed () {
#******************************************************************
# change some options from "--with-xxx" in "--without-xxx",
# and add "--disable-web2c" and "--disable-xetex" in SlackBuild
#******************************************************************
if [ ! -f $SLACKSRC/t/texlive/texlive.SlackBuild.old ]; then
	cp -v $SLACKSRC/t/texlive/texlive.SlackBuild $SLACKSRC/t/texlive/texlive.SlackBuild.old
	(
		cd $SLACKSRC/t/texlive
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

execute_xfce_sed () {
#******************************************************************
# modify SlackBuild to avoid "exit 1" on failed package building
#******************************************************************
if [ ! -f $SLACKSRC/xfce/xfce-build-all.sh.old ]; then
	cp -v $SLACKSRC/xfce/xfce-build-all.sh  $SLACKSRC/xfce/xfce-build-all.sh.old 
	(
		cd $SLACKSRC/xfce
		sed -i -e '/cd $package || exit 1/a .\/\$package.SlackBuild' xfce-build-all.sh
		sed -i -e '/{package}.failed ; exit 1 ) || exit 1/d' xfce-build-all.sh
		sed -i -e '/$package.SlackBuild/a [ $? != 0 ] && touch /tmp/$package.failed' xfce-build-all.sh
	)
fi
}

#*******************************************************************
# End of sub-system of execution of patches
#*******************************************************************

all_deps () {
#********************************************************
# 
#********************************************************
# Note: Much of this script is inspired from the KDE Slackware script by Eric Hameleers <alien@slackware.com>
#       Copyright © 2019 Eric Hameleers and may be copied under the MIT License.
# 
# 		Build (and install) all KDE dependencies
#
#
# Set initial variables:
#********************************************************
which upgradepkg 2>&1 >/dev/null
if [ $? == 0 ]; then
	INSTALLPRG="upgradepkg --install-new --reinstall"
else
	INSTALLPRG=installpkg
fi

cd /slacksrc/deps
CWD=$(pwd)
TMP=${TMP:-/tmp}

# This avoids compiling a version number into KDE's .la files:
QTDIR=/usr/lib${LIBDIRSUFFIX}/qt ; export QTDIR

for module in \
  extra-cmake-modules \
  md4c \
  sni-qt \
  SDL_sound \
  OpenAL \
  libxkbcommon \
  wayland \
  wayland-protocols \
  brotli \
  woff2 \
  hyphen \
  qt5 \
  qt5-webkit \
  qca-qt5 \
  libdbusmenu-qt5 \
  phonon \
  phonon-gstreamer \
  phonon-qt4 \
  phonon-qt4-gstreamer \
  python-enum34 \
  pcaudiolib \
  espeak-ng \
  dotconf \
  flite \
  speech-dispatcher \
  sip \
  PyQt \
  PyQt5 \
  QScintilla \
  polkit-qt5-1 \
  grantlee \
  grantlee-qt4 \
  poppler \
  libdbusmenu-gtk \
  libindicator \
  libappindicator \
  cfitsio \
  libdmtx \
  qrencode \
  hack-font-ttf \
  noto-font-ttf \
  noto-cjk-font-ttf \
  gpgme \
  lensfun \
  opencv \
  dvdauthor \
  vid.stab \
  frei0r-plugins \
  mlt \
  cracklib \
  libpwquality \
  accountsservice \
  libburn \
  qtav \
  ddcutil \
  id3lib \
  cryptopp \
  cryfs \
  python3-random2 \
  perl-path-tiny \
  perl-template-toolkit \
  freecell-solver \
  drumstick \
  libsass \
  sassc \
  rttr \
  quazip \
  ; do
  cd $module && ./$module.SlackBuild
  if [ $? = 0 ]; then
    $INSTALLPRG /tmp/${module}-*.txz
    # Keep MIME database current:
    /usr/bin/update-mime-database /usr/share/mime 1> /dev/null 2> /dev/null &
	mv -v /tmp/$module*.txz /sfspacks/deps
	rm -rf /tmp/package-$module /tmp/$module-*
  else
    echo "${module} failed to build."
    exit 1
  fi
cd - ;
done

}

kernel_source_build_c () {
#********************************************************
# remove everything related to building the kernel image
#********************************************************
cd /slacksrc/k
cp -v kernel-source.SlackBuild kernel-source.SlackBuild.old
sed -i -e '52,89d;109,111d;138,163d' kernel-source.SlackBuild && ./kernel-source.SlackBuild 
upgradepkg --install-new --reinstall /tmp/kernel-source*.txz && mv -v /tmp/kernel-source*.txz /sfspacks/k
rm -rf /tmp/package-kernel-source/
mv kernel-source.SlackBuild.old kernel-source.SlackBuild
}

kernel_headers_build_c () {
#********************************************************
# remove everything related to .config and PRINT_PACKAGE_NAME
#********************************************************
cd /slacksrc/k
cp -v kernel-headers.SlackBuild kernel-headers.SlackBuild.old
sed -i -e '45,47d;57,64d' kernel-headers.SlackBuild && ./kernel-headers.SlackBuild 
upgradepkg --install-new --reinstall /tmp/kernel-headers*.txz && mv -v /tmp/kernel-headers*.txz /sfspacks/d
rm -rf /tmp/package-kernel-headers/
mv kernel-headers.SlackBuild.old kernel-headers.SlackBuild
}

kernel_build_all () {
#***********************************************************
# build kernel and modules before packaging with SlackBuild
#***********************************************************
cd /slacksrc/k

./build-all-kernels.sh || exit 1

case $(uname -m) in
	x86_64 )
		cd /tmp/output-x86_64*
		mv kernel-source*.t?z /sfspacks/k
		mv kernel-headers*.t?z /sfspacks/d
		mv kernel-*.t?z /sfspacks/a
		[ $? != 0 ] && exit 1 ;;
	* )
		cd /tmp/output-ia32*
		mv kernel-source*.t?z /sfspacks/k
		mv kernel-headers*.t?z /sfspacks/d
		mv kernel-*.t?z /sfspacks/a
		[ $? != 0 ] && exit 1 ;;
esac
cd /tmp
rm -rf *
}

build () {
#***********************************************************
# main build procedure for slackware package
#***********************************************************
which upgradepkg 2>&1 >/dev/null
if [ $? == 0 ]; then
	INSTALLPRG="upgradepkg --install-new --reinstall"
else
	INSTALLPRG=installpkg
fi

# BUILDN: defines if package will be installed or upgraded
[ "$BUILDN" != "" ] && export BUILDN
SRCDIR=$1
shift
PACKNAME=$1
shift

case $PACKNAME in
#**************************
# BUILD package treatment
#**************************

	aspell-word-lists )
		cd /slacksrc/extra/aspell-word-lists && chmod +x aspell-dict.SlackBuild && ./aspell-dict.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	gettext-tools )
		# two packages in gettext: gettext and gettext-tools
		DIRNAME=gettext
		cd /slacksrc/$SRCDIR/$DIRNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	java )
		cd /slacksrc/extra/java && chmod +x java.SlackBuild && ./java.SlackBuild
		[ $? != 0 ] && exit 1 ;;
		
	linuxdoc-tools )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x trackbuild.linuxdoc-tools && chmod +x linuxdoc-tools.build && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozilla-firefox )
		# need sh shell to be built
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-firefox.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozjs60 )
		# need sh shell to be built
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozjs60.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozilla-thunderbird )
		# need sh shell to be built
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-thunderbird.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	seamonkey )
		# need sh shell to be built
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./seamonkey.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	snownews )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && gzip -d *.diff.gz && sed -i 's/root//' *.diff && gzip -9 *.diff && ./$PACKNAME.SlackBuild
		[ $? != 0 ] && exit 1 ;;
	
	vim )
		cd /slacksrc/$SRCDIR/$PACKNAME
		chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		chmod +x vim-gvim.SlackBuild && ./vim-gvim.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	xfce )
		# xfce doesn't build with one SlackBuild, but with multiple SlackBuilds
		cd /slacksrc/$SRCDIR && chmod +x xfce-build-all.sh && ./xfce-build-all.sh
		upgradepkg --install-new /tmp/*.t?z
		mv -v /tmp/*.t?z /sfspacks/$SRCDIR
		[ $? != 0 ] && exit 1 ;;

	* )
		# every other package treatment
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		[ $? != 0 ] && exit 1 ;;
esac

case $PACKNAME in
#****************************
# INSTALL package treatment
#****************************

	aaa_terminfo )
		# remove extra ncurses packages
		rm /tmp/ncurses*.t?z
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	alpine )
		# package name is not alpine but imapd
		$INSTALLPRG /tmp/imapd*.txz
		$INSTALLPRG /tmp/alpine*.txz
		[ $? != 0 ] && exit 1 ;;

	aspell-word-lists )
		# install aspell-en
		$INSTALLPRG /tmp/aspell-en*.txz
		[ $? != 0 ] && exit 1 ;;

	etc )
		# remove mini /etc/group and etc/passwd
		rm /etc/group && rm /etc/passwd
		cd /tmp
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	java )
		# install java
		$INSTALLPRG /tmp/j*.txz
		[ $? != 0 ] && exit 1 ;;

	php )
		# remove extra alpine and imapd packages
		rm /tmp/imapd*.t?z
		rm /tmp/alpine*.t?z
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	vim )
		# install both vim and vim-gvim packages
		$INSTALLPRG /tmp/vim-gvim*.t?z
		$INSTALLPRG /tmp/$PACKNAME-*.t?z
		[ $? != 0 ] && exit 1 ;;

	xfce )
		echo ;;

	* )
		# every other package is built in /tmp
		export TERM=xterm && cd /tmp
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

esac

case $PACKNAME in
#****************************
# MOVE package treatment
#****************************

	alpine )
		# package name is not 'alpine' but 'imapd'
		mv /tmp/alpine*.txz /sfspacks/$SRCDIR
		cd /sources ;;

	aspell-word-lists )
		# don't forget to move aspell-en in l/
		mv /tmp/aspell-en*.txz /sfspacks/l
		# don't forget to move others aspell in extra/
		mkdir -pv /sfspacks/extra/aspell-words-list
		mv /tmp/aspell*.txz /sfspacks/extra/aspell-words-list
		cd /sources ;;

	gettext-tools )
		# don't forget to mv gettext-tools in d/
		cd /tmp
		mv /tmp/$PACKNAME*.t?z /sfspacks/d/
		cd /sources ;;

	java )
		# don't forget to mv java in extra/
		cd /tmp
		mv /tmp/j*.t?z /sfspacks/extra/
		cd /sources ;;

	glibc )
		cd /tmp
		# don't forget to mv glibc-solibs in a/
		mv glibc-solibs*.t?z /sfspacks/a/
		mv glibc*.t?z /sfspacks/$SRCDIR
		rm -rf /tmp/*
		cd /sources ;;

	openssl )
		# don't forget to mv opennsl-solibs in a/
		cd /tmp
		mv /tmp/$PACKNAME-solibs*.t?z /sfspacks/a/
		mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
		cd /sources ;;

	openssl10 )
		# don't forget to mv opennsl-solibs in a/
		cd /tmp
		mv /tmp/$PACKNAME-solibs*.t?z /sfspacks/a/
		mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
		cd /sources ;;

	vim )
		# don't forget to mv vim-gvim in xap/ and vim in ap/
		mv -v /tmp/vim-gvim*.txz /sfspacks/xap
		mv -v /tmp/$PACKNAME-*.txz /sfspacks/ap
		[ $? != 0 ] && exit 1 ;;

	xz )
		# package built in /tmp 
		cd /tmp
		mv xz*.txz /sfspacks/$SRCDIR
		cd /sources ;;
	* )
		# mv every built package in its destination directory
		mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR ;;
esac

cd /tmp
#***************************************************
# Note that the following removes any SBo directory.
#***************************************************
for i in *; do
    [ -d "$i" ] && rm -rf $i
done
cd /sources
}

build_linux_howtos () {
#*******************************************************************
BUILD=${BUILD:-1}

SRCDIR=$1
shift
PACKNAME=$1
shift

CWD=$(pwd)
TMP=${TMP:-/tmp}
PKG=$TMP/package-Linux-HOWTOS

cd $TMP
mkdir -pv $PKG/usr/doc/Linux-HOWTOs
cd $PKG/usr/doc/Linux-HOWTOs
wget -c http://www.tldp.org/Linux-HOWTO-text.tar.gz
tar xf *.tar.gz && rm *.tar.gz .htacess

mkdir -p $PKG/install
cat /slacksrc/f/slack-desc.linux-howtos > $PKG/install/slack-desc.linux-howtos

cd $PKG
chown -R root:root .
/sbin/makepkg -l y -c n $TMP/linux-howtos-20160401-noarch-$BUILD.txz
installpkg $TMP/linux-howtos-20160401-noarch-$BUILD.txz
mv -v $TMP/linux-howtos-20160401-noarch-$BUILD.txz /sfspacks/f
rm -rf $PKG
cd /sources
}

build_linux_faqs () {
#*******************************************************************
BUILD=${BUILD:-1}

SRCDIR=$1
shift
PACKNAME=$1
shift

CWD=$(pwd)
TMP=${TMP:-/tmp}
PKG=$TMP/package-Linux-FAQS

cd $TMP
mkdir -pv $PKG/usr/doc/Linux-FAQs
cd $PKG/usr/doc/Linux-FAQs
mkdir -pv AfterStep-FAQ && cd AfterStep-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/AfterStep-FAQ/AfterStep-FAQ
cd .. && mkdir -pv Ftape-FAQ && cd Ftape-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/Ftape-FAQ/Ftape-FAQ
cd .. && mkdir -pv LDP-FAQ && cd LDP-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/LDP-FAQ/LDP-FAQ
cd .. && mkdir -pv Linux-FAQ && cd Linux-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/Linux-FAQ/Linux-FAQ
cd .. && mkdir -pv Linux-RAID-FAQ && cd Linux-RAID-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/Linux-RAID-FAQ/Linux-RAID-FAQ
cd .. && mkdir -pv PPP-FAQ && cd PPP-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/PPP-FAQ/PPP-FAQ
cd .. && mkdir -pv Threads-FAQ/html && cd Threads-FAQ/html
wget -c www.tldp.org/pub/Linux/docs/faqs-archived/Threads-FAQ/Threads-FAQ-html.tar.gz
tar xf *.tar.gz && rm *.tar.gz
cd .. && mkdir -pv WordPerfect-Linux-FAQ && cd WordPerfect-Linux-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/WordPerfect-Linux-FAQ/WordPerfect-Linux-FAQ
cd .. && mkdir -pv linux-FAQ && cd linux-FAQ
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/linux-faq/linux-FAQ
cd .. && mkdir -pv security && cd security
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/security/Cryptographic-File-System
cd ..
wget -c http://www.tldp.org/FAQ/faqs/ATAPI-FAQ
wget -c http://www.tldp.org/FAQ/sig11/text/GCC-SIG11-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/SCSI-Generic-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/BLFAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/BLFAQ.lsm
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/FTP-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/Joe-Command-Reference
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/Linux-RAID-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/MSSQL6-via-Openlink-PHP-ODBC-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/README
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/SMP-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/Swap-space-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/Wine-FAQ
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/new.gif
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/next.gif
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/prev.gif
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/toc.gif
wget -c http://slackware.uk/splack/splack-8.0/docs/faqs/updated.gif

mkdir -p $PKG/install
cat /slacksrc/f/slack-desc.linux-faqs > $PKG/install/slack-desc.linux-faqs

cd $PKG
chown -R root:root .
/sbin/makepkg -l y -c n $TMP/linux-faqs-20060228-noarch-$BUILD.txz
installpkg $TMP/linux-faqs-20060228-noarch-$BUILD.txz
mv -v $TMP/linux-faqs-20060228-noarch-$BUILD.txz /sfspacks/f
rm -rf $PKG
cd /sources
}

clean_tmp () {
#*************************
# cleanup /tmp directory
#*************************
cd / && [ -f localtime ] && rm localtime
cd /tmp
rm *
rm -rf /tmp/*
cd /sources
}

define_path_lib () {
#****************************************
case $ARCH in
	x86_64 )
		export LD_LIBRARY_PATH="/lib64:/usr/lib64"
		mkdir -pv /usr/lib64/java/bin && mkdir -pv /usr/lib64/jre/bin
		PATH_HOLD=$PATH && export PATH=/usr/lib64/java/bin:/usr/lib64/jre/bin:$PATH_HOLD ;;

	* )
		mkdir -pv /usr/lib/java/bin && mkdir -pv /usr/lib/jre/bin
		PATH_HOLD=$PATH && export PATH=/usr/lib/java/bin:/usr/lib/jre/bin:$PATH_HOLD ;;
esac
}

echo_message_slackware () {
#****************************************************************
echo "-------------------------------------------"
echo
echo "By now, you are ready to build Slackware From Scratch."
echo "and wait a long time, a few hours."
echo
echo "You can do it by hand, by building packages, one by one."
echo "./package.SlackBuild && installpkg /tmp/package*.t?z"
echo
echo "You can also do it with only one script, by executing the"
echo "following command, there will be 4 steps:"
echo
echo -e "$YELLOW" "time (./sfsbuild1.sh build1_s.list)" "$NORMAL"
echo
echo "Either, you can also do it in one step, by executing the"
echo "following command, it will build the entire system till the end:"
echo
echo -e "$YELLOW" "time (./full-sfs.sh)" "$NORMAL"
}

test_arch () {
#******************************************
# test the architecture i686/586/386 or x86_64 we
# will be build the  slackware distribution,
#******************************************
ARCH=$(uname -m)
echo $ARCH
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "i686" ] && [ "$ARCH" != "i586" ] && [ "$ARCH" != "i386" ]; then
	boot_mesg "
 >>> This arch ($ARCH) is not supported."
	echo_failure
	exit 1
fi
}

test_1 () {
#******************************************
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

echo
echo "There should be no errors, and the output of the last command"
echo "will be (allowing for platform-specific differences in dynamic"
echo "linker name):"
echo "[Requesting program interpreter: /lib/ld-linux.so.2]"
echo
echo "or on x86_64"
echo
echo "[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"
echo
echo -n "Enter <Enter> to continue:"

}

test_2 () {
# Now make sure that we're setup to use the correct startfiles:
	grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log

echo
echo "The output of the last command should be:"
echo "	/usr/lib/crt1.o succeeded"
echo "	/usr/lib/crti.o succeeded"
echo "	/usr/lib/crtn.o succeeded"
echo 
echo "or on x86_64"
echo
echo "	/usr/lib64/crt1.o succeeded"
echo "	/usr/lib64/crti.o succeeded"
echo "	/usr/lib64/crtn.o succeeded"
echo
echo -n "Enter <Enter> to continue:"
}

test_3 () {
# Verify that the compiler is searching for the correct header files:
grep -B1 '^ /usr/include' dummy.log

echo
echo "This command should return the following output:"
echo "	#include <...> search starts here:"
echo "	 /usr/include"
echo
echo -n "Enter <Enter> to continue:"
}

test_4 () {
# Next, verify that the new linker is being used with the
# correct search paths:
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
echo
echo "References to paths that have components with '-linux-gnu'"
echo "should be ignored, but otherwise the output of the last"
echo "command should be:"
echo "	SEARCH_DIR("/usr/lib")"
echo "	SEARCH_DIR("/lib")"
echo
echo -n "Enter <Enter> to continue:"
}

test_5 () {
# Next make sure that we're using the correct libc:
grep "/lib.*/libc.so.6" dummy.log

echo
echo "The output of the last command (allowing for a lib64"
echo "directory on 64-bit hosts) should be:"
echo "	attempt to open /lib/libc.so.6 succeeded"
echo
echo "or on x86_64"
echo "attempt to open /lib64/libc.so.6 succeeded"
echo "/lib64/libc.so.6"
echo "ld-linux-x86-64.so.2 needed by /lib64/libc.so.6"
echo
echo -n "Enter <Enter> to continue:"
}

test_6 () {
# Lastly, make sure GCC is using the correct dynamic linker:
grep found dummy.log

echo
echo "The output of the last commnand should be (allowing for"
echo "platform-specific differences in dynamic linker name and"
echo "a lib64 directory on 64-bit hosts):"
echo "     found ld-linux.so.2 at /lib/ld-linux.so.2"
echo
echo "or on x86_64"
echo
echo "     found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2"
echo
echo -n "Enter <Enter> to continue: "
}

test_7 () {
# Now we clean up our mess and exit:
rm -v dummy.c a.out dummy.log
echo
echo -n "Enter <Enter> to continue: "
echo "the process of building slackware from scratch can continue."
echo
}

test_progs () {
#*************************************************************************
# test essential program presence and location for makepkg and installpkg
# for which, tar-1.13, xz and patch, the existence is sufficient
# if one of those test fails, the script will exit.
#*************************************************************************

echo "Now we test essential program locations."
echo "The following should be located:"
echo "	/tools/bin/which"
echo "	/tools/bin/tar-1.13"
echo "	/tools/bin/xz"
echo "	/tools/bin/patch"
echo "	/sbin/makepkg"
echo "	/sbin/installpkg"

	if ! (`which which > /dev/null`); then
		error "which was not found on the system, the 'tools' you built are not complete"
		[ $? != 0 ] && exit 1
	fi
	if ! (`which tar-1.13 > /dev/null`); then
		error "tar-1.13 was not found on the system, the 'tools' you built are not complete"
		[ $? != 0 ] && exit 1
	fi
	if ! (`which xz > /dev/null`); then
		error "xz was not found on the system, the 'tools' you built are not complete"
		[ $? != 0 ] && exit 1
	fi
	if ! (`which patch > /dev/null`); then
		error "patch was not found on the system, the 'tools' you built are not complete"
		[ $? != 0 ] && exit 1
	fi
	if ! (`which makepkg > /dev/null`); then
		error "makepkg was not found on the system, the 'tools' you built are not complete"
		[ $? != 0 ] && exit 1
	fi
	if ! (`which installpkg > /dev/null`); then
		error "installpkg was not found on the system, the 'tools' you built are not complete"
		[ $? != 0 ] && exit 1
	fi

echo
}

link_tools () {
#****************************************************************
# Some programs use hard-wired paths to programs which do not
# exist yet. In order to satisfy these programs, create a
# number of symbolic links which will be replaced by real
# files throughout the course of this chapter after the
# software has been installed. And create some directories
# to install the first slackware programs.
# We added a link to /tools/bin/du to avoid 'noise' during
# pkgtools building, which is not in LFS of course.
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2019 Gerard Beekmans and may be
#       copied under the MIT License.
#****************************************************************
mkdir -pv /usr/lib && mkdir -v /bin && mkdir -pv /usr/include
mkdir -pv /usr/src && mkdir -pv /usr/bin
ln -sv /tools/bin/{bash,cat,dd,du,echo,ln,pwd,rm,stty} /bin
ln -sv /tools/bin/{install,perl} /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.{a,so{,.6}} /usr/lib
ln -sv bash /bin/sh
ln -sv /proc/self/mounts /etc/mtab
echo
}

link_tools_x64 () {
#****************************************************************
# Some programs use hard-wired paths to programs which do not
# exist yet. In order to satisfy these programs, create a
# number of symbolic links which will be replaced by real
# files throughout the course of this chapter after the
# software has been installed. And create some directories
# to install the first slackware programs.
# We added a link to /tools/bin/du to avoid 'noise' during
# pkgtools building, which is not in LFS of course.
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2019 Gerard Beekmans and may be
#       copied under the MIT License.
#****************************************************************
mkdir -pv /usr/lib64 && mkdir -v /bin && mkdir -pv /usr/include
mkdir -pv /usr/src && mkdir -pv /usr/bin
ln -sv /tools/bin/{bash,cat,dd,du,echo,ln,pwd,rm,stty} /bin
ln -sv /tools/bin/{install,perl} /usr/bin
ln -sv /tools/lib64/libgcc_s.so{,.1} /usr/lib64
ln -sv /tools/lib64/libstdc++.{a,so{,.6}} /usr/lib64
ln -sv bash /bin/sh
ln -sv /proc/self/mounts /etc/mtab
}

pre_elflibs_c () {
#******************************************************************
# Install packages from slackware-14.2 to be able
# to build aaa_alflibs
#******************************************************************
cd /slacksrc/others
installpkg cxxlibs-6.0.18-i486-1.txz
installpkg gmp-5.1.3-i486-1.txz
installpkg readline-6.3-i586-2.txz
installpkg readline-7.0.005-i586-1.txz
installpkg libtermcap-1.2.3-i486-7.txz
installpkg ncurses-5.9-i486-4.txz
installpkg libpng-1.4.12-i486-1.txz
installpkg libffi-3.2.1-i586-2.txz
installpkg /sfspacks/l/libpng-1.6.*.txz
cd /sources
}

pre_elflibs64_c () {
#******************************************************************
# Install packages from slackware-14.2 to be able
# to build aaa_alflibs
#******************************************************************
cd /slacksrc/others
installpkg cxxlibs-6.0.18-x86_64-1.txz
installpkg gmp-5.1.3-x86_64-1.txz
installpkg readline-6.3-x86_64-2.txz
installpkg readline-7.0.005-x86_64-1.txz
installpkg libtermcap-1.2.3-x86_64-7.txz
installpkg ncurses-5.9-x86_64-4.txz
installpkg libpng-1.4.12-x86_64-1.txz
installpkg libffi-3.2.1-x86_64-2.txz
installpkg /sfspacks/l/libpng-1.6.*-x86_64*.txz
cd /sources
}

post_elflibs_c () {
#******************************************************************
# Remove packages temporary installed after
# aaa_elflibs has been built and installed
#******************************************************************
removepkg cxxlibs-6.0.18-i486-1.txz readline-6.3-i586-2 ncurses-5.9-i486-4
removepkg gmp-5.1.3-i486-1  libtermcap-1.2.3-i486-7 libpng-1.4.12-i486-1.txz
removepkg readline-7.0.005-i586-1.txz
removepkg libffi-3.2.1-i586-2.txz
upgradepkg --reinstall /sfspacks/l/libpng-1.6.*.txz
upgradepkg --reinstall /sfspacks/l/readline-8.0.*.txz
cd /sources
}

post_elflibs64_c () {
#******************************************************************
# Remove packages temporary installed after
# aaa_elflibs has been built and installed
#******************************************************************
removepkg cxxlibs-6.0.18-x86_64-1.txz readline-6.3-x86_64-2 ncurses-5.9-x86_64-4
removepkg gmp-5.1.3-x86_64-1 libtermcap-1.2.3-x86_64-7 libpng-1.4.12-x86_64-1.txz
removepkg libffi-3.2.1-x86_64-2.txz
upgradepkg --reinstall /sfspacks/l/libpng-1.6.*.txz
upgradepkg --reinstall /sfspacks/l/readline-8.0.*.txz
cd /sources
}

#****************************************************************
# X11 SUB-SYSTEM BUILDING
#****************************************************************

build_x11_group1 () {
#***********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

for package in \
  xorg-sgml-doctools \
  xorg-docs \
  ; do
   ./x11.SlackBuild doc $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

./x11.SlackBuild util util-macros
 [ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

./x11.SlackBuild proto
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

for package in \
  xorg-cf-files \
  gccmakedep \
  imake \
  lndir \
  makedepend \
  ; do
   ./x11.SlackBuild util $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

cd /sources
}

build_x11_lib () {
#***********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

for package in \
  libXau \
  libXdmcp \
  ; do
   ./x11.SlackBuild lib $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

for package in \
  xcb-proto \
  libpthread-stubs \
  libxcb \
  ; do
   ./x11.SlackBuild xcb $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

for package in \
  xtrans \
  libX11 \
  libXext \
  libFS \
  libICE \
  libSM \
  libXScrnSaver \
  libXt \
  libXmu \
  libXpm \
  libXaw \
  libXfixes \
  libXcomposite \
  libXrender \
  libXcursor \
  libXdamage \
  libXft \
  libXi \
  libXinerama \
  libXrandr \
  libXres \
  libXtst \
  libXv \
  libXvMC \
  libXpresent \
  libXxf86dga \
  libXxf86vm \
  libdmx \
  libfontenc \
  libpciaccess \
  libxkbfile \
  libxshmfence \
  libXevie \
  libXxf86misc \
  libXp \
  libXfontcache \
  libXaw3d \
  pixman \
  libXfont2 \
  ; do
   ./x11.SlackBuild lib $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

cd /sources
}

build_x11_xcb () {
#*****************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

for package in \
  xcb-util \
  xcb-util-image \
  xcb-util-keysyms \
  xcb-util-renderutil \
  xcb-util-wm \
  xcb-util-cursor \
  xcb-util-errors \
  xpyb \
  ; do
   ./x11.SlackBuild xcb $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

cd /sources
}

build_x11_group2 () {
#*****************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild data xbitmaps
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

./x11.SlackBuild font font-util
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

for package in \
  bdftopcf \
  iceauth \
  mkfontscale \
  sessreg\
  setxkbmap \
  smproxy \
  x11perf \
  xauth \
  xbacklight \
  xcmsdb \
  xcursorgen \
  xdpyinfo \
  xdriinfo \
  xev \
  xgamma \
  xhost \
  xinput \
  xkbcomp \
  xkbevd \
  xkbutils \
  xkill \
  xlsatoms \
  xlsclients \
  xmessage \
  xmodmap \
  xpr \
  xprop \
  xrandr \
  xrdb \
  xrefresh \
  xset \
  xsetroot \
  xvinfo \
  xwd \
  xwininfo \
  xwud \
  appres \
  beforelight \
  bitmap \
  editres \
  fonttosfnt \
  fslsfonts \
  fstobdf \
  ico \
  listres \
  mkcomposecache \
  oclock \
  rendercheck \
  rgb \
  showfont \
  transset \
  viewres \
  xbiff \
  xcalc \
  xclipboard \
  xclock \
  xcompmgr \
  xconsole \
  xdbedizzy \
  xditview \
  xdm \
  xedit \
  xeyes \
  xf86dga \
  xfd \
  xfontsel \
  xfs \
  xfsinfo \
  xgc \
  xkbprint \
  xload \
  xlogo \
  xlsfonts \
  xmag \
  xman \
  xmh \
  xmore \
  xscope \
  xsm \
  xstdcmap \
  xvidtune \
  ; do
   ./x11.SlackBuild app $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

./x11.SlackBuild data xcursor-themes
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

for package in \
  font-adobe-100dpi \
  font-adobe-75dpi \
  font-adobe-utopia-100dpi \
  font-adobe-utopia-75dpi \
  font-adobe-utopia-type1 \
  font-alias \
  font-arabic-misc \
  font-bh-100dpi \
  font-bh-75dpi \
  font-bh-lucidatypewriter-100dpi \
  font-bh-lucidatypewriter-75dpi \
  font-bh-ttf \
  font-bh-type1 \
  font-bitstream-100dpi \
  font-bitstream-75dpi \
  font-bitstream-speedo \
  font-bitstream-type1 \
  font-cronyx-cyrillic \
  font-cursor-misc \
  font-daewoo-misc \
  font-dec-misc \
  font-ibm-type1 \
  font-isas-misc \
  font-jis-misc \
  font-micro-misc \
  font-misc-cyrillic \
  font-misc-ethiopic \
  font-misc-meltho \
  font-misc-misc \
  font-mutt-misc \
  font-schumacher-misc \
  font-screen-cyrillic \
  font-sony-misc \
  font-sun-misc \
  font-winitzki-cyrillic \
  font-xfree86-type1 \
  ; do
   ./x11.SlackBuild font $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

./x11.SlackBuild data xkeyboard-config
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

./x11.SlackBuild xserver xorg-server
[ $? != 0 ] && exit 1
mv /tmp/x11-build/*.txz /sfspacks/x

for package in \
  xf86-input-acecad \
  xf86-input-evdev \
  xf86-input-joystick \
  xf86-input-keyboard \
  xf86-input-mouse \
  xf86-input-penmount \
  xf86-input-synaptics \
  xf86-input-vmmouse \
  xf86-input-void \
  xf86-input-wacom \
  xf86-video-amdgpu \
  xf86-video-apm \
  xf86-video-ark \
  xf86-video-ast \
  xf86-video-ati \
  xf86-video-chips \
  xf86-video-cirrus \
  xf86-video-dummy \
  xf86-video-geode \
  xf86-video-glint \
  xf86-video-i128 \
  xf86-video-i740 \
  xf86-video-intel \
  xf86-video-mach64 \
  xf86-video-mga \
  xf86-video-neomagic\
  xf86-video-nouveau \
  xf86-video-nv \
  xf86-video-openchrome \
  xf86-video-r128 \
  xf86-video-rendition \
  xf86-video-s3 \
  xf86-video-s3virge \
  xf86-video-savage \
  xf86-video-siliconmotion \
  xf86-video-sis \
  xf86-video-sisusb \
  xf86-video-tdfx \
  xf86-video-tga \
  xf86-video-trident \
  xf86-video-tseng \
  xf86-video-v4l \
  xf86-video-vesa \
  xf86-video-vmware \
  xf86-video-voodoo \
  ; do
   ./x11.SlackBuild driver $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

./x11.SlackBuild font encodings
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

for package in \
  compiz \
  luit \
  igt-gpu-tools \
  twm \
  xinit \
  ; do
   ./x11.SlackBuild app $package
 	[ $? != 0 ] && exit 1
	mv -v /tmp/x11-build/*.txz /sfspacks/x
done

./x11.SlackBuild driver xf86-video-vboxvideo
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

cd /sources
}

build_x11_app_post () {
#*****************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild driver xf86-input-libinput
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

./x11.SlackBuild app compiz
[ $? != 0 ] && exit 1
mv -v /tmp/x11-build/*.txz /sfspacks/x

cd /sources
}

build_kde () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdelibs
[ $? != 0 ] && touch /tmp/kde_build/kdelibs.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  nepomuk-core \
  nepomuk-widgets \
  ; do
   ./kde.SlackBuild kdebase:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

./kde.SlackBuild kdepimlibs
[ $? != 0 ] && touch /tmp/kde_build/kdepimlibs.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  kfilemetadata \
  kde-baseapps \
  kactivities \
  konsole \
  kde-wallpapers \
  kde-workspace \
  kde-runtime \
  kde-baseapps \
  kde-base-artwork \
  ; do
   ./kde.SlackBuild kdebase:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  cervisia \
  dolphin-plugins \
  kapptemplate \
  kactivities \
  kcachegrind \
  kde-dev-scripts \
  kde-dev-utils \
  kdesdk-kioslaves \
  kdesdk-strigi-analyzers \
  kdesdk-thumbnailers \
  libkomparediff2 \
  kompare \
  lokalize \
  okteta \
  poxml \
  umbrello \
  ; do
   ./kde.SlackBuild kdesdk:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

./kde.SlackBuild extragear:libkscreen
[ $? != 0 ] && touch /tmp/kde_build/libkscreen.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  libkipi \
  libkexiv2 \
  libkdcraw \
  libksane\
  kdegraphics-mobipocket \
  okular \
  kdegraphics-strigi-analyzer \
  kdegraphics-thumbnailers \
  kamera \
  kcolorchooser \
  kgamma \
  kolourpaint \
  kruler \
  ksaneplugin \
  ksnapshot \
  svgpart \
  ; do
   ./kde.SlackBuild kdegraphics:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  smokegen \
  smokeqt \
  qtruby \
  perlqt\
  smokekde \
  korundum \
  perlkde \
  pykde4 \
  kate \
  kross-interpreters \
  ; do
   ./kde.SlackBuild kdebindings:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  kaccessible \
  kmouth \
  kmousetool \
  kmag \
  ; do
   ./kde.SlackBuild kdeaccessibility:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  ark \
  filelight \
  kcalc  \
  kcharselect \
  kdf \
  kfloppy \
  kgpg \
  print-manager   \
  kremotecontrol \
  ktimer \
  kwalletmanager \
  superkaramba \
  sweeper \
  ; do
   ./kde.SlackBuild kdeutils:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  libkcddb \
  libkcompactdisc \
  audiocd-kio \
  dragon \
  mplayerthumbs \
  juk \
  kmix \
  ; do
   ./kde.SlackBuild kdemultimedia:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

./kde.SlackBuild extragear:libktorrent
[ $? != 0 ] && touch /tmp/kde_build/libktorrent.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  kdenetwork-filesharing \
  kdenetwork-strigi-analyzers \
  zeroconf-ioslave \
  kget \
  kopete \
  kppp \
  krdc \
  krfb \
  ; do
   ./kde.SlackBuild kdenetwork:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

./kde.SlackBuild oxygen-icons
[ $? != 0 ] && touch /tmp/kde_build/oxygen-icons.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  kcron \
  ksystemlog \
  kuser \
  ; do
   ./kde.SlackBuild kdeadmin:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

./kde.SlackBuild kdeartwork
[ $? != 0 ] && touch /tmp/kde_build/kdeartwork.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  libkdegames \
  libkmahjongg \
  klickety \
  ksudoku \
  ksquares \
  kpat \
  klines \
  ksnakeduel \
  kollision \
  kshisen \
  kblocks \
  lskat \
  kreversi \
  bovo \
  kajongg \
  granatier \
  kmines \
  kiriki \
  kigo \
  bomber \
  kolf \
  kdiamond \
  kbounce \
  konquest \
  kapman \
  knavalbattle \
  killbots \
  kubrick \
  kgoldrunner \
  knetwalk \
  kbreakout \
  ksirk \
  kfourinline \
  picmi \
  kblackbox \
  palapeli \
  katomic \
  ktuberling \
  kjumpingcube \
  kmahjongg \
  kspaceduel \
  ; do
   ./kde.SlackBuild kdegames:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  amor \
  kteatime \
  ktux \
  ; do
   ./kde.SlackBuild kdetoys:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

for package in \
  libkdeedu \
  analitza \
  artikulate \
  blinken \
  cantor \
  kalgebra \
  kalzium \
  kanagram \
  kbruch \
  kgeography \
  khangman \
  kig \
  kiten \
  klettres \
  kmplot \
  kstars \
  kqtquickcharts \
  ktouch \
  kturtle \
  kwordquiz \
  marble \
  parley \
  pairs \
  rocs \
  step \
  ; do
   ./kde.SlackBuild kdeedu:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

./kde.SlackBuild  kdewebdev
[ $? != 0 ] && touch /tmp/kde_build/kdewebdev.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild  kdebase:kde-baseapps
[ $? != 0 ] && touch /tmp/kde_build/kde-baseapps.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild  kdeplasma-addons
[ $? != 0 ] && touch /tmp/kde_build/kdeplasma-addons.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild  polkit-kde:polkit-kde-agent-1
[ $? != 0 ] && touch /tmp/kde_build/polkit-kde-agent-1.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild  polkit-kde:polkit-kde-kcmodules-1
[ $? != 0 ] && touch /tmp/kde_build/polkit-kde-kcmodules-1.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

for package in \
  bluedevil \
  kaudiocreator \
  kplayer \
  kwebkitpart \
  oxygen-gtk2 \
  kdevplatform \
  kdevelop-pg-qt \
  kdevelop \
  kdev-python \
  kdevelop-php \
  kdevelop-php-docs \
  wicd-kde\
  libmm-qt \
  libnm-qt \
  plasma-nm \
  skanlite \
  kio-mtp \
  libktorrent\
  ktorrent \
  amarok \
  calligra \
  kscreen \
  kdeconnect-kde \
  partitionmanager \
  k3b \
  ; do
   ./kde.SlackBuild extragear:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde
done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

build_kdei () {
#****************************************************************
cd /slacksrc/kdei/kde-l10n

export UPGRADE_PACKAGES=always

for package in \
  ar \
  bg \
  bs \
  ca \
  ca@valencia \
  cs \
  da \
  de \
  el \
  en_GB \
  es \
  et \
  eu \
  fa \
  fi \
  fr \
  ga \
  gl \
  he \
  hi \
  hr \
  hu \
  ia \
  id \
  is \
  it \
  ja \
  kk \
  km \
  ko \
  lt \
  lv \
  mr \
  nb \
  nds \
  nl \
  nn \
  pa \
  pl \
  pt \
  pt_BR \
  ro \
  ru \
  sk \
  sl \
  sr \
  sv \
  tr \
  ug \
  uk \
  wa \
  zh_CN \
  zh_TW \
  ; do
   PKGLANG=$package ./kde-l10n.SlackBuild
 	[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kdei
done

cd /sources

}

build_calligra () {
#****************************************************************
cd /slacksrc/kdei/calligra-l10n

export UPGRADE_PACKAGES=always

for package in \
  bs \
  ca \
  ca@valencia \
  cs \
  da \
  de \
  el \
  en_GB \
  es \
  et \
  fi \
  fr \
  gl \
  hu \
  it \
  ja \
  kk \
  nb \
  nl \
  pl \
  pt \
  pt_BR \
  ru \
  sk \
  sv \
  tr \
  uk \
  zh_CN \
  zh_TW \
  ; do
   PKGLANG=$package ./calligra-l10n.SlackBuild
 	[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kdei
done

cd /sources

}

build_post_kde () {
#****************************************************************
# this part exist because some kde packages don't build directly
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild  kdebase:baloo
[ $? != 0 ] && touch /tmp/kde_build/baloo.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild  kdebase:baloo-widgets
[ $? != 0 ] && touch /tmp/kde_build/baloo-widgets.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild  kdegraphics:gwenview
[ $? != 0 ] && touch /tmp/kde_build/gwenview.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild extragear:amarok
[ $? != 0 ] && touch /tmp/kde_build/amarok.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

cd /sources

}

build_kdepim () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdepim
[ $? != 0 ] && touch /tmp/kde_build/kdepim.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

./kde.SlackBuild kdepim-runtime
[ $? != 0 ] && touch /tmp/kde_build/kdepim-runtime.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde

cd /sources

}

build_frameworks_kde5 () {
#********************************************************
#  kde4 \
#  frameworks \
#  applications-extra:kdiagram \
#  kdepim \
#  plasma \
#  plasma-extra \
#  applications-extra:libktorrent \
#  applications \
#  applications-extra \
#  applications:umbrello \
#********************************************************

cd /slacksrc/kde5

export UPGRADE_PACKAGES=always

./kde.SlackBuild kde4:kdelibs
[ $? != 0 ] && touch /tmp/kde_build/kdelibs.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde5/kde4

for package in \
	attica-framework \
	extra-cmake-modules \
	kapidox \
	karchive \
	kcodecs \
	kconfig \
	kcoreaddons \
	kdbusaddons \
	kdnssd \
	kguiaddons \
	ki18n \
	kidletime \
	kimageformats \
	kitemmodels \
	kitemviews \
	kplotting \
	kwidgetsaddons \
	kwindowsystem \
	networkmanager-qt \
	solid \
	sonnet \
	threadweaver \
	kauth \
	kcompletion \
	kcrash \
	kdoctools \
	kpty \
	kunitconversion \
	kconfigwidgets \
	kservice \
	kglobalaccel \
	kpackage \
	kdesu \
	kemoticons \
	kiconthemes \
	kjobwidgets \
	knotifications \
	ktextwidgets \
	kxmlgui \
	kbookmarks \
	kwallet \
	kio \
	kdeclarative \
	kcmutils \
	kirigami2 \
	knewstuff \
	frameworkintegration \
	kinit \
	knotifyconfig \
	kparts \
	kactivities-framework \
	kded \
	kdewebkit \
	syntax-highlighting \
	ktexteditor \
	kdesignerplugin \
	kwayland \
	plasma-framework \
	modemmanager-qt \
	kpeople \
	kxmlrpcclient \
	bluez-qt \
	kfilemetadata5 \
	baloo5 \
	breeze-icons \
	oxygen-icons5 \
	kactivities-stats \
	krunner \
	prison \
	qqc2-desktop-style \
	kjs \
	kdelibs4support \
	khtml \
	kjsembed \
	kmediaplayer \
	kross \
	purpose \
	syndication \
	kholidays \
	kcalendarcore \
	kcontacts \
  ; do
   ./kde.SlackBuild frameworks:$package 
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde5/frameworks
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi
done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

build_kdepim_kde5 () {
#********************************************************
cd /slacksrc/kde5

export UPGRADE_PACKAGES=always

./kde.SlackBuild applications-extra:kdiagram
[ $? != 0 ] && touch /tmp/kde_build/kdiagram.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications-extra

for package in \
	akonadi \
	kpimtextedit \
	kidentitymanagement \
	kcalutils \
	kblog \
	libkgapi \
	kmime \
	ksmtp \
	kimap \
	kmbox \
	kldap \
	kontactinterface \
	ktnef \
	akonadi-mime \
	akonadi-contacts \
	akonadi-notes \
	akonadi-search \
	kalarmcal \
	kmailtransport \
	akonadi-calendar \
	libkleo \
	grantleetheme \
	libkdepim \
	pimcommon \
	libgravatar \
	libksieve \
	mailimporter \
	kdepim-apps-libs \
	calendarsupport \
	eventviews \
	incidenceeditor \
	messagelib \
	mailcommon \
	kleopatra \
	kdav \
	kpkpass \
	kitinerary \
	kdepim-addons \
	kdepim-runtime \
	akonadi-calendar-tools \
	akonadiconsole \
	akonadi-import-wizard \
	akregator \
	grantlee-editor \
	kaddressbook \
	kalarm \
	kmail \
	kmail-account-wizard \
	knotes \
	kontact \
	korganizer \
	mbox-importer \
	pim-data-exporter \
	pim-sieve-editor \
  ; do
   ./kde.SlackBuild kdepim:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde5/kdepim
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi
done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

build_plasma_kde5 () {
#********************************************************
cd /slacksrc/kde5

export UPGRADE_PACKAGES=always

for package in \
	kgamma5 \
	kdecoration \
	breeze \
	breeze-gtk \
	breeze-grub \
	kwayland-integration \
	plasma-integration \
	kinfocenter \
	libksysguard \
	ksysguard \
	kscreenlocker \
	kwin \
	kwrited \
	libkscreen2 \
	milou \
	oxygen \
	plasma-workspace \
	kde-cli-tools \
	plasma-workspace \
	systemsettings \
	plasma-desktop \
	kdeplasma-addons \
	plasma-workspace-wallpapers \
	plasma5-nm \
	powerdevil \
	bluedevil \
	khotkeys \
	kmenuedit \
	polkit-kde-framework \
	kscreen2 \
	sddm-kcm \
	kde-gtk-config \
	ksshaskpass \
	plasma-sdk \
	plasma-pa \
	kactivitymanagerd \
	user-manager \
	xdg-desktop-portal-kde \
	drkonqi \
	plasma-vault \
	plasma-browser-integration \
  ; do
   ./kde.SlackBuild plasma:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde5/plasma
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi
done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

build_plasma_extra_kde5 () {
#********************************************************
cd /slacksrc/kde5

export UPGRADE_PACKAGES=always

for package in \
	sddm-qt5 \
	kdeconnect-framework \
	polkit-kde-kcmodules-framework \
	kde-wallpapers \
	latte-dock \
	oxygen-fonts \
	wacomtablet \
  ; do
   ./kde.SlackBuild plasma-extra:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde5/plasma-extra
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi
done

./kde.SlackBuild applications-extra:libktorrent
[ $? != 0 ] && touch /tmp/kde_build/libktorrent.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications-extra
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

build_applications_kde5 () {
#********************************************************
cd /slacksrc/kde5

export UPGRADE_PACKAGES=always

for package in \
	libkipi \
	kipi-plugins \
	libkexiv2 \
	libkdcraw \
	libksane \
	gwenview \
	kio-extras \
	kate \
	konsole \
	kdialog \
	keditbookmarks \
	kfind \
	konqueror \
	ark \
	baloo5-widgets \
	filelight \
	kcalc \
	kcharselect \
	kdf \
	kfloppy \
	kgpg \
	print-manager \
	kbackup \
	ktimer \
	khelpcenter \
	kwalletmanager \
	sweeper \
	dolphin \
	kdebugsettings \
	kapptemplate \
	cervisia \
	dolphin-plugins \
	kcachegrind \
	kde-dev-scripts \
	kde-dev-utils \
	kdesdk-kioslaves \
	kdesdk-thumbnailers \
	kross-interpreters \
	libkomparediff2 \
	kompare \
	lokalize \
	poxml \
	kdegraphics-mobipocket \
	okular \
	kdegraphics-thumbnailers \
	kamera \
	kcolorchooser \
	kolourpaint \
	kruler \
	spectacle \
	svgpart \
	kirigami-gallery \
	kmouth \
	kmousetool \
	kmag \
	libkcddb \
	libkcompactdisc \
	audiocd-kio \
	dragon \
	juk \
	kmix \
	ffmpegthumbs \
	kwave \
	k3b \
	kamoso \
	kdenetwork-filesharing \
	zeroconf-ioslave \
	kget \
	kopete \
	krdc \
	krfb \
	kcron \
	ksystemlog \
	libkdegames \
	libkmahjongg \
	klickety \
	ksudoku \
	ksquares \
	kpat \
	klines \
	ksnakeduel \
	kollision \
	kshisen \
	kblocks \
	lskat \
	kreversi \
	bovo \
	granatier \
	kmines \
	kiriki \
	kigo \
	bomber \
	kolf \
	kdiamond \
	kbounce \
	konquest \
	kapman \
	knavalbattle \
	killbots \
	kubrick \
	kgoldrunner \
	knetwalk \
	kbreakout \
	ksirk \
	kfourinline \
	picmi \
	kblackbox \
	palapeli \
	katomic \
	ktuberling \
	kjumpingcube \
	kmahjongg \
	kspaceduel \
	knights \
	kteatime \
	kdeedu-data \
	libkeduvocdocument \
	analitza \
	kalgebra \
	kanagram \
	khangman \
	kig \
	parley \
	artikulate \
	blinken \
	cantor \
	kalzium \
 	kbruch \
	kgeography \
	kiten \
	klettres \
	kmplot \
	kqtquickcharts \
	ktouch \
	kturtle \
	kwordquiz \
	marble \
	rocs \
	step \
	minuet \
	libkgeomap \
	kdenlive \
	kimagemapeditor \
	yakuake \
  ; do
   ./kde.SlackBuild applications:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi

done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

build_applications_extra_kde5 () {
#********************************************************
cd /slacksrc/kde5

export UPGRADE_PACKAGES=always

for package in \
	calligra \
	calligraplan \
	digikam \
	krita \
	ktorrent \
	kpmcore \
	partitionmanager \
	falkon \
	skanlite \
	kdevelop-pg-qt \
	kdevelop \
	kdev-php \
	kdiagram \
	kjots \
	kstars \
	krusader \
	kile \
	kaudiocreator \
	kwebkitpart \
	oxygen-gtk2 \
	kdev-python \
	alkimia \
	kmymoney \
	okteta \
	krename \
  ; do
   ./kde.SlackBuild applications-extra:$package
 	[ $? != 0 ] && touch /tmp/kde_build/$package.failed
	mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications-extra
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi
done

./kde.SlackBuild applications:umbrello
[ $? != 0 ] && touch /tmp/kde_build/umbrello.failed
mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	if [ $? = 0 ]; then
#		mv -v /tmp/kde_build/*.txz /sfspacks/kde5/applications
#	else
#		touch /tmp/kde_build/$package.failed
#		exit 1
#	fi 

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /sources

}

message_end1 () {
#****************************************************************
echo
echo "sfsbuild1.sh has finished to build the first part of SFS."
echo "You now have a bare slackware system able to boot."
echo "You can even go on internet with the lynx browser." 
echo
echo "You can modify your bootloader to test your new environment."
echo "Before you test your new system, you must execute the script"
echo "myprofile.sh to have /etc/fstab and some other conveniences."
echo "You must edit that script to adapt to your needs and execute it:"
echo 
echo -e "$YELLOW"  "./myprofile.sh" "$NORMAL"
echo
echo "Then you can:"
echo
echo -e "$YELLOW"  "exit" "$NORMAL"
echo
echo "and:"
echo
echo -e "$YELLOW"  "upgrade your boot loader and reboot in your SFS system" "$NORMAL"
echo
echo -e "$RED" "Or if you want to go on building slackware from scratch" "$NORMAL"
echo
echo "Just execute the following command:"
echo
echo -e "$YELLOW" "time (./sfsbuild1.sh build2_s.list)" "$NORMAL"
echo
echo "After that, you should have an X11 system with blackbox."
echo
echo
cd /sources && killall -9 dhcpcd
}

message_end2 () {
#****************************************************************
echo
echo "sfsbuild1.sh has finished to build the second part of SFS."
echo "You should now have an X11 system with just blackbox."
echo
echo "You can modify your bootloader to test your new environment."
echo "Before you test your new system, you must execute the script"
echo "myprofile.sh to have /etc/fstab and some other conveniences."
echo "You must edit that script to adapt to your needs and execute it:"
echo 
echo -e "$YELLOW"  "./myprofile.sh" "$NORMAL"
echo
echo "Then you can:"
echo
echo -e "$YELLOW"  "exit" "$NORMAL"
echo
echo "and:"
echo
echo -e "$YELLOW"  "upgrade your boot loader and reboot in your SFS system" "$NORMAL"
echo
echo -e "$RED" "Or if you want to go on building slackware from scratch" "$NORMAL"
echo
echo "Just execute the following command:"
echo
echo -e "$YELLOW" "time (./sfsbuild1.sh build3_s.list)" "$NORMAL"
echo
echo "After that you should have an X11 system with xfce."
echo
echo
cd /sources && killall -9 dhcpcd
}

message_end3 () {
#****************************************************************
echo
echo "sfsbuild1.sh has finished to build the third part of SFS."
echo "You should now have an X11 system with xfce and seamonkey."
echo
echo "Before you test your new system, you must execute the script"
echo "myprofile.sh to have /etc/fstab and some other conveniences."
echo "You must edit that script to adapt to your needs and execute it:"
echo 
echo -e "$YELLOW"  "./myprofile.sh" "$NORMAL"
echo
echo "Then you can:"
echo
echo -e "$YELLOW"  "exit" "$NORMAL"
echo
echo "and:"
echo
echo -e "$YELLOW"  "upgrade your boot loader and reboot in your SFS system" "$NORMAL"
echo
echo -e "$RED" "Or if you want to go on building slackware from scratch" "$NORMAL"
echo
echo "Just execute the following command:"
echo
echo -e "$YELLOW"  "time (./sfsbuild1.sh build4_s.list)" "$NORMAL"
echo
echo "After that you should have a complete Slackware system"
echo
echo
cd /sources && killall -9 dhcpcd
}

message_end4 () {
#****************************************************************
echo
echo "sfsbuild1.sh has finished to build the fourth part of SFS."
echo "You should now have a complete slackware system."
echo
echo "Before you test your new system, you must execute the script"
echo "myprofile.sh to have /etc/fstab and some other conveniences."
echo "You must edit that script to adapt to your needs and execute it:"
echo 
echo -e "$YELLOW"  "./myprofile.sh" "$NORMAL"
echo
echo "Then you can:"
echo
echo -e "$YELLOW"  "exit" "$NORMAL"
echo
echo "and:"
echo
echo -e "$YELLOW"  "upgrade your boot loader and reboot in your SFS system" "$NORMAL"
echo
echo
cd /sources && killall -9 dhcpcd
}

update_slackbuild () {
#****************************************************************
# rename SlackBuild.old to original SlackBuild
#****************************************************************
cd /slacksrc/$SRCDIR/$PACKNAME && mv $PACKNAME.SlackBuild.old $PACKNAME.SlackBuild && cd /sources
}

update_xfce () {
#****************************************************************
# rename xfce-build-all.sh.old to original name
#****************************************************************
cd /slacksrc/xfce && mv xfce-build-all.sh.old xfce-build-all.sh && cd /sources
}

#****************************************************************
#****************************************************************
# MAIN CORE SCRIPT of sfsbuild1
#****************************************************************
#****************************************************************
test_arch
define_path_lib

#****************************************************************
# Ensure that the /sfspacks/$SAVDIRs exists.
#****************************************************************
distribution="slackware"
mkdir -pv /sfspacks/{others,a,ap,d,deps,e,extra,f,k,kde,kde5,kdei,l,n,t,tcl,x,xap,xfce,y}
mkdir -pv /sfspacks/kde5/{applications,applications-extra,frameworks,kde4,kdepim,plasma,plasma-extra}
#******************************************************************
# Some packages need two pass to be built completely.
# Alteration of the slackware sources is made "on the fly" during
# the first build. On the second pass, the old SlackBuild is 
# renamed to its original version, and package can be built normally. 
#	execute_cmake_sed # 2 pass
#	execute_dbus_sed # 2 pass
#	execute_findutils_sed # 2 pass
#	execute_fontconfig_sed # 2 pass
#	execute_freetype_sed # 2 pass
#	execute_gd_sed # 2 pass
#	execute_glib2_sed # 2 pass
#	execute_gobject_sed # 2 pass
#	execute_harfbuzz_sed # 2 pass
#	execute_kmod_sed # 2 pass
#	execute_libcaca_sed # 2 pass
#	execute_libusb_sed # 2 pass
#	execute_llvm_sed # 2 pass
#	execute_pkg_config_sed # 2 pass
#	execute_qscint_sed # 2 pass
#	execute_readline_sed # 3 pass
#	execute_subversion_sed # 2 pass
#	execute_texlive_sed # 2 pass
#	execute_xfce_sed # 2 pass
#
#******************************************************************
# BUILDN: defines if package will be installed or upgraded
#******************************************************************
# init libusb variable
LUSB=1
# init pkg-config variable
LPKG=1
# init llvm variable
LPVM=1
# init libcaca variable
LCAC=1
# init kmod variable
LKMO=1
# init readline variable
LREA=1
# init mesa variable
LMES=1
# init freetype variable
LFRE=1
# init harfbuzz variable
LHAR=1
# init gd variable
LGD=1
# init QScintilla variable
LQSC=1
# init findutils variable
LFIN=1
# init NUMJOBS variable
NUMJOBS="-j$(( $(nproc) * 2 )) -l$(( $(nproc) + 1 ))"

#**************************************************************
# read the length of build.list and affect SRCDIR and PACKNAME
#**************************************************************

[ "$1" == "" ] && on_error
[ ! -f $1 ] && on_error
LISTFILE=$1

FILELEN=$(wc -l $LISTFILE |cut -d' ' -f1)

typeset -i LINE=0
while read ra[LINE]; do
	(( LINE = LINE + 1 ))
done <<< "`cat $LISTFILE`"

(( LINE = 0 ))
while (( LINE < $FILELEN )); do
	aline=${ra[LINE]}
	echo $aline
	SRCDIR=`echo $aline |cut -d' ' -f1`
	PACKNAME=`echo $aline |cut -d' ' -f2`
	(( LINE = LINE + 1 ))
	[ "$SRCDIR" == "#" ] && continue

			case $PACKNAME in

				adjust )
					case $(uname -m) in
						x86_64 )
							adjust_x86_64
							[ $? != 0 ] && exit 1 ;;
						* )
							adjust_i686
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				all-deps )
					all_deps
					[ $? != 0 ] && exit 1 ;;

				alsa-lib )
					case $LISTFILE in
						build2_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						* )
							rm /sfspacks/l/alsa-lib*.t?z
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				atk )
					source /root/.bashrc
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				ca-certificates )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					update-ca-certificates ;;

				cmake )
					case $LISTFILE in
						build1_s.list )
							execute_cmake_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 
							update_slackbuild ;;

						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				dbus )
					case $LISTFILE in
						build2_s.list )
							execute_dbus_sed && build $SRCDIR $PACKNAME && 
							[ $? != 0 ] && exit 1  
							dbus-uuidgen --ensure ;;

						* )
							update_slackbuild && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				dhcpcd_up )
					dhcpcd -t 15 -L eth0 || dhcpcd -t 15 -L wlan0 && echo
					[ $? != 0 ] && exit 1 ;;

				end1 )
					message_end1
					clean_tmp ;;

				end2 )
					message_end2
					clean_tmp ;;

				end3 )
					message_end3
					clean_tmp ;;

				end4 )
					message_end4
					clean_tmp ;;

				findutils )
					case $LFIN in
						1 )
							execute_findutils_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							update_slackbuild && LFIN=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				fontconfig )
					case $LISTFILE in
						build2_s.list )
							execute_fontconfig_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1
							update_slackbuild ;;

						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				freetype )
					case $LFRE in
						1 )
							execute_freetype_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1
							Lupdate_slackbuild && FRE=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				gd )
					case $LGD in
						1 )
							execute_gd_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							update_slackbuild && LGD=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				glib2 )
					case $LISTFILE in
						build1_s.list )
							execute_glib2_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 
							update_slackbuild ;;

						build2_s.list )
							execute_glib2_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 
							update_slackbuild ;;

						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				glib-networking )
					update-ca-certificates && build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				gobject-introspection )
					case $LISTFILE in
						build1_s.list )
							execute_gobject_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 
							update_slackbuild ;; 

						build2_s.list )
							execute_gobject_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 
							update_slackbuild ;;

						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				gucharmap )
					update-ca-certificates --fresh && build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				harfbuzz )
					case $LHAR in
						1 )
							execute_harfbuzz_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							 update_slackbuild && LHAR=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				isapnptools )
					case $ARCH in
						x86_64 )
							echo ;;
						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				frameworks )
					build_frameworks_kde5
					[ $? != 0 ] && exit 1 ;;

				kdepim5 )
					build_kdepim_kde5
					[ $? != 0 ] && exit 1 ;;

				applications )
					build_applications_kde5
					[ $? != 0 ] && exit 1 ;;

				applications-extra )
					build_applications_extra_kde5
					[ $? != 0 ] && exit 1 ;;

				plasma )
					build_plasma_kde5
					[ $? != 0 ] && exit 1 ;;

				plasma-extra )
					build_plasma_extra_kde5
					[ $? != 0 ] && exit 1 ;;

				kde )
					build_kde
					[ $? != 0 ] && exit 1 ;;

				kde-l10n )
					build_kdei
					[ $? != 0 ] && exit 1 ;;

				calligra-l10n )
					build_calligra
					[ $? != 0 ] && exit 1 ;;

				post-kde )
					build_post_kde
					[ $? != 0 ] && exit 1 ;;

				kdepim )
					build_kdepim
					[ $? != 0 ] && exit 1 ;;

				kernel-all )
					kernel_build_all
					[ $? != 0 ] && exit 1 ;;

				kernel-headers )
					kernel_headers_build_c
					[ $? != 0 ] && exit 1 ;;

				kernel-source )
					kernel_source_build_c
					[ $? != 0 ] && exit 1 ;;

				kmod )
					case $LKMO in
						1 )
							execute_kmod_sed && build $SRCDIR  $PACKNAME
							[ $? != 0 ] && exit 1
							update_slackbuild && LKMO=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				ksh93 )
					case $ARCH in
						x86_64 )
							upgradepkg --install-new /slacksrc/others/ksh93-2012_08_01-x86_64-2.txz
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
						* )
							upgradepkg --install-new /slacksrc/others/ksh93-2012_08_01-i586-2.txz
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				link_tools_slackware )
					test_progs
					distribution="slackware"
					case $ARCH in
						x86_64 )
 							link_tools_x64
							echo_message_slackware && exit 1 ;;
						* )
							link_tools
							echo_message_slackware && exit 1 ;;
					esac
					continue ;;

				libcaca )
					case $LCAC in
						1 )
							execute_libcaca_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1
							update_slackbuild && LCAC=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				libsoup )
					source /root/.bashrc
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				libusb )
					case $LUSB in
						1 )
							execute_libusb_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1
							update_slackbuild && LUSB=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				linux-faqs )
					build_linux_faqs
					[ $? != 0 ] && exit 1 ;;

				linux-howtos )
					build_linux_howtos
					[ $? != 0 ] && exit 1 ;;

				llvm )
					case $LPVM in
						1 )
							execute_llvm_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							update_slackbuild && LPVM=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				mesa )
					case $LMES in
						1 )
							export BUILD_DEMOS=NO && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LMES=2 ;;
						2 )
							export BUILD_DEMOS=YES && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				pci-utils )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					update-pciids ;;

				pkg-config )
					case $LPKG in
						1 )
							execute_pkg_config_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1
							update_slackbuild && LPKG=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				pre-elflibs )
					case $ARCH in
						x86_64 )
							pre_elflibs64_c
							[ $? != 0 ] && exit 1 ;;
						* )
							pre_elflibs_c
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				post-elflibs )
					case $ARCH in
						x86_64 )
							post_elflibs64_c
							[ $? != 0 ] && exit 1 ;;
						* )
							post_elflibs_c
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				QScintilla )
					case $LQSC in
						1 )
							execute_qscint_sed && build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							update_slackbuild && LQSC=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				readline )
					case $LREA in
						1 )
							execute_readline_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1
							update_slackbuild && LREA=2 ;;
						2 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LREA=3 ;;

						* )
							rm /sfspacks/l/readline*.t?z
 							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				subversion )
					case $LISTFILE in
						build3_s.list )
							execute_subversion_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1 
							update_slackbuild ;;

						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				texlive )
					case $LISTFILE in
						build2_s.list )
							execute_texlive_sed && build $SRCDIR $PACKNAME 
							[ $? != 0 ] && exit 1 
							update_slackbuild ;;
				
						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				utempter )
					touch /var/run/utmp
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				test-glibc )
					test_1
					answer
					test_2
					answer
					test_3
					answer
					test_4
					answer
					test_5
					answer
					test_6
					answer
					test_7
					answer ;;

				x11-group1 )
					build_x11_group1
					[ $? != 0 ] && exit 1 ;;

				x11-group2 )
					build_x11_group2
					[ $? != 0 ] && exit 1 ;;

				x11-lib )
					build_x11_lib
					[ $? != 0 ] && exit 1 ;;

				x11-xcb )
					build_x11_xcb
					[ $? != 0 ] && exit 1 ;;

				x11-app-post )
					build_x11_app_post
					[ $? != 0 ] && exit 1 ;;

				xfce )
					execute_xfce_sed && build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					update_xfce ;;
	
				* )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

			esac
done

echo
