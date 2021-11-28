################################  sfsbuild1.sh #################################
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
# Note: The adjust and link_tools procedures of this script are 
#       inspired from the LFS manual chapter 6.10
#       Copyright © 1999-2020 Gerard Beekmans and may be
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
# set -xv
#*********************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#**********************************
export TERM=linux
export SLACKSRC=/source
#**********************************
on_error () {
#***********************************************************
# recalls the usage of the main script in case of error
#***********************************************************
echo 	"Usage: ./sfsbuild1.sh build1.list"
echo
echo	"The build.list of programs to build, and their source directories is required."
echo
echo	"The packages will not be processed until the end of the build{1,4}.list."
echo
exit 255
}

adjust_i686 () {
#***********************************************************
# First, backup the /tools linker, and replace it with the
# adjusted linker we made in chapter 5. We'll also create a
# link to its counterpart in /tools/$(gcc -dumpmachine)/bin:
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2021 Gerard Beekmans and may be
#       copied under the MIT License.
#***********************************************************
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/"$(uname -m)"-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/"$(uname -m)"-pc-linux-gnu/bin/ld
#***********************************************************
# Next, amend the GCC specs file so that it points to the
# new dynamic linker. Simply deleting all instances of
# '/tools' should leave us with the correct path to the
# dynamic linker. Also adjust the specs file so that GCC
# knows where to find the correct headers and Glibc start
# files. A sed command accomplishes this:
#***********************************************************
# shellcheck disable=SC2006,SC2046
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
#       Copyright © 1999-2021 Gerard Beekmans and may be
#       copied under the MIT License.
#***********************************************************
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/"$(uname -m)"-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/"$(uname -m)"-pc-linux-gnu/bin/ld
#***********************************************************
# Next, amend the GCC specs file so that it points to the
# new dynamic linker. Simply deleting all instances of
# '/tools' should leave us with the correct path to the
# dynamic linker. Also adjust the specs file so that GCC
# knows where to find the correct headers and Glibc start
# files. A sed command accomplishes this:
#***********************************************************
# shellcheck disable=SC2006,SC2046
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib64/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
}

answer () {
#****************************
local testvar
read -r testvar
if [ "$testvar" != "" ]; then
	exit
fi
echo
}

#*******************************************************************
# sub-system of execution of patches on the fly
#*******************************************************************

execute_sed_cmake () {
#******************************************************************
# delete "--qt-gui" line in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/d/cmake/cmake.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/d/cmake/cmake.SlackBuild "$SLACKSRC"/d/cmake/cmake.SlackBuild.old
	(
		cd "$SLACKSRC"/d/cmake || exit 1
		sed -i -e "/--qt-gui/d" cmake.SlackBuild
	)
fi
}

execute_sed_cyrus-sasl () {
#******************************************************************
# delete several lines in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/n/cyrus-sasl/cyrus-sasl.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/n/cyrus-sasl/cyrus-sasl.SlackBuild "$SLACKSRC"/n/cyrus-sasl/cyrus-sasl.SlackBuild.old
	(
		cd "$SLACKSRC"/n/cyrus-sasl || exit 1
		sed -i -e "/--enable-sql/d" cyrus-sasl.SlackBuild
		sed -i -e "/--without-pgsql/d" cyrus-sasl.SlackBuild
		sed -i -e "/--with-mysql/d" cyrus-sasl.SlackBuild
		sed -i -e "/--with-sqlite3/d" cyrus-sasl.SlackBuild
	)
fi
}

execute_sed_doxygen () {
#******************************************************************
# change "-Dbuild_wizard=yes" to "no" line in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/d/doxygen/doxygen.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/d/doxygen/doxygen.SlackBuild "$SLACKSRC"/d/doxygen/doxygen.SlackBuild.old
	(
		cd "$SLACKSRC"/d/doxygen || exit 1
		sed -i -e "s/Dbuild_wizard=ON/Dbuild_wizard=OFF/g" doxygen.SlackBuild
	)
fi
}

execute_sed_dbus () {
#******************************************************************
# delete "--enable-x11-autolaunch" line in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/a/dbus/dbus.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/a/dbus/dbus.SlackBuild "$SLACKSRC"/a/dbus/dbus.SlackBuild.old
	(
		cd "$SLACKSRC"/a/dbus || exit 1
		sed -i -e "/--enable-x11-autolaunch/d" dbus.SlackBuild
	)
fi
}

execute_sed_elogind () {
#******************************************************************
# change all "true" options to "false" options in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/a/elogind/elogind.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/a/elogind/elogind.SlackBuild "$SLACKSRC"/a/elogind/elogind.SlackBuild.old
	(
		cd "$SLACKSRC"/a/elogind || exit 1
		sed -i -e "s/Dman=true/Dman=false/g" elogind.SlackBuild
	)
fi
}

execute_sed_efivar () {
#******************************************************************
# remove '|| exit 1' on first build
#******************************************************************
if [ ! -f "$SLACKSRC"/a/efivar/efivar.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/a/efivar/efivar.SlackBuild "$SLACKSRC"/a/efivar/efivar.SlackBuild.old
	(
		cd $SLACKSRC/a/efivar
		sed -i -e 's/man\/\ || exit 1/man\/\ /' efivar.SlackBuild
	)
fi
}

execute_sed_findutils () {
#******************************************************************
# disable the patch and autoreconf in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/a/findutils/findutils.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/a/findutils/findutils.SlackBuild "$SLACKSRC"/a/findutils/findutils.SlackBuild.old
	(
		cd $SLACKSRC/a/findutils || exit 1
		sed -i -e "s/zcat/# zcat/g" findutils.SlackBuild
		sed -i -e "s/autoreconf/# autoreconf/g" findutils.SlackBuild
	)
fi
}

execute_sed_fontconfig () {
#******************************************************************
# add "--disable-docs" to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/x/fontconfig/fontconfig.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/x/fontconfig/fontconfig.SlackBuild "$SLACKSRC"/x/fontconfig/fontconfig.SlackBuild.old
	(
		cd "$SLACKSRC"/x/fontconfig || exit 1
		sed -i -e "/--sysconfdir/p" fontconfig.SlackBuild
		sed -i -e "0,/sysconfdir/! s/sysconfdir=\/\etc/disable-docs/" fontconfig.SlackBuild
	)
fi
}

execute_sed_freetype () {
#******************************************************************
# remove "exit 1" code and add headers (ft2build.h and ftoption.h) to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/freetype/freetype.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/freetype/freetype.SlackBuild "$SLACKSRC"/l/freetype/freetype.SlackBuild.old
	(
		cd "$SLACKSRC"/l/freetype || exit 1
		# shellcheck disable=SC2016
		sed -i -e 's/make $NUMJOBS || make || exit 1/make $NUMJOBS/' freetype.SlackBuild
		# shellcheck disable=SC2016
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' freetype.SlackBuild
		sed -i -e "/make install DESTDIR=$PKG/p" freetype.SlackBuild
		sed -i -e "0,/make install DESTDIR=$PKG/ s/make install DESTDIR=$PKG/make/" freetype.SlackBuild
		sed -i -e "/make install DESTDIR=$PKG/a # install freetype headers to build harfbuzz/" freetype.SlackBuild
		sed -i -e "/# install freetype headers/a mkdir -pv $PKG/usr/include/freetype2/" freetype.SlackBuild
		sed -i -e "/mkdir -pv/a cp devel/ft2build.h $PKG/usr/include/freetype2/ft2build.h" freetype.SlackBuild
		sed -i -e "/cp devel\/\ft2build.h/a cp devel/ftoption.h $PKG/usr/include/freetype2/ftoption.h" freetype.SlackBuild
		sed -i -e "/ft2build.h/a cp devel/ftoption.h $PKG/usr/include/freetype2/ftoption.h" freetype.SlackBuild
	)
fi
}

execute_sed_gd () {
#******************************************************************
# add "--without-fontconfig" and "--without-xpm" to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/gd/gd.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/gd/gd.SlackBuild "$SLACKSRC"/l/gd/gd.SlackBuild.old
	(
		cd "$SLACKSRC"/l/gd || exit 1
		sed -i -e "/--disable-static/p" gd.SlackBuild
		sed -i -e "/--program-prefix=/p" gd.SlackBuild
		sed -i -e "0,/disable-static/ s/disable-static/without-fontconfig/" gd.SlackBuild
		sed -i -e "0,/program-prefix=/ s/program-prefix=/without-xpm/" gd.SlackBuild
		sed -i -e "s/make $NUMJOBS || make || exit 1/make $NUMJOBS || make/" gd.SlackBuild
		sed -i -e "s/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/" gd.SlackBuild
	)
fi
}

execute_sed_glib2 () {
#******************************************************************
# change all "true" options to "false" options in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/glib2/glib2.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/glib2/glib2.SlackBuild "$SLACKSRC"/l/glib2/glib2.SlackBuild.old
	(
		cd "$SLACKSRC"/l/glib2 || exit 1
		sed -i -e "s/true/false/g" glib2.SlackBuild
	)
fi
}

execute_sed_gobject-introspection () {
#******************************************************************
# change all "true" options to "false" options in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/gobject-introspection/gobject-introspection.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/gobject-introspection/gobject-introspection.SlackBuild "$SLACKSRC"/l/gobject-introspection/gobject-introspection.SlackBuild.old
	(
		cd "$SLACKSRC"/l/gobject-introspection || exit 1
		sed -i -e "s/true/false/" gobject-introspection.SlackBuild
	)
fi
}

execute_sed_gpgme () {
#******************************************************************
# remove qt5 option fo the first build in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/n/gpgme/gpgme.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/n/gpgme/gpgme.SlackBuild "$SLACKSRC"/n/gpgme/gpgme.SlackBuild.old
	(
		cd "$SLACKSRC"/n/gpgme || exit 1
		sed -i -e "s/python qt/python/" gpgme.SlackBuild
	)
fi
}

execute_sed_harfbuzz () {
#******************************************************************
# remove "exit 1" code and add harfbuzz headers to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/harfbuzz/harfbuzz.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/harfbuzz/harfbuzz.SlackBuild "$SLACKSRC"/l/harfbuzz/harfbuzz.SlackBuild.old
	(
		cd "$SLACKSRC"/l/harfbuzz || exit 1
		# shellcheck disable=SC2016
		sed -i -e 's/\"\${NINJA:=ninja}\"\ $NUMJOBS || exit 1/\"\${NINJA:=ninja}\"\ $NUMJOBS/' harfbuzz.SlackBuild
		# shellcheck disable=SC2016
		sed -i -e 's/DESTDIR=$PKG $NINJA install || exit 1/DESTDIR=$PKG $NINJA install || exit 1/' harfbuzz.SlackBuild
	)
fi
}

execute_sed_kmod () {
#******************************************************************
# remove "exit 1" code in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/a/kmod/kmod.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/a/kmod/kmod.SlackBuild "$SLACKSRC"/a/kmod/kmod.SlackBuild.old
	(
		cd "$SLACKSRC"/a/kmod || exit 1
		sed -i -e "s/make || exit 1/make/" kmod.SlackBuild
		# shellcheck disable=SC2016
		sed -i -e 's/make install DESTDIR=$PKG || exit 1/make install DESTDIR=$PKG/' kmod.SlackBuild
	)
fi
}

execute_sed_libusb () {
#******************************************************************
# add "--disable-dev" to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/libusb/libusb.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/libusb/libusb.SlackBuild \
		"$SLACKSRC"/l/libusb/libusb.SlackBuild.old
	(
		cd "$SLACKSRC"/l/libusb || exit 1
		sed -i -e "/--disable-static/p" libusb.SlackBuild
		sed -i -e "0,/disable-static/ s/static/udev/" libusb.SlackBuild
	)
fi
}

execute_sed_libxkbcommon () {
#******************************************************************
# add "-Denable-docs=false" to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/libxkbcommon/libxkbcommon.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/libxkbcommon/libxkbcommon.SlackBuild \
		"$SLACKSRC"/l/libxkbcommon/libxkbcommon.SlackBuild.old
	(
		cd "$SLACKSRC"/l/libxkbcommon || exit 1
		sed -i -e "/-Denable-wayland=true/p" libxkbcommon.SlackBuild
		sed -i -e "s/wayland=true/docs=false/" libxkbcommon.SlackBuild
	)
fi
}

execute_sed_llvm () {
#******************************************************************
# change "clang++" to "g++" and "clang" to "gcc" in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/d/llvm/llvm.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/d/llvm/llvm.SlackBuild "$SLACKSRC"/d/llvm/llvm.SlackBuild.old
	(
		cd "$SLACKSRC"/d/llvm || exit 1
		# shellcheck disable=SC2016
		sed -i -e 's/"clang++"/"g++"/' llvm.SlackBuild
		sed -i -e 's/"clang"/"gcc"/' llvm.SlackBuild
		sed -i -e "s/-GNinja/-Wno-dev -GNinja/" llvm.SlackBuild
		sed -i -e "s/-DBUILD_SHARED_LIBS=ON/-DLLVM_BUILD_LLVM_DYLIB=ON/" llvm.SlackBuild
		sed -i -e "s/-DLLVM_USE_LINKER=gold/-DLLVM_LINK_LLVM_DYLIB=ON/" llvm.SlackBuild
		sed -i -e "/-DLLVM_ENABLE_RTTI=ON/d" llvm.SlackBuild
		sed -i -e "/-DLLVM_ENABLE_ASSERTIONS=OFF/d" llvm.SlackBuild
		sed -i -e "/-DLLVM_INSTALL_UTILS=ON/d" llvm.SlackBuild
	)
fi
}

execute_sed_openldap () {
#******************************************************************
# disable some options in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/n/openldap/openldap.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/n/openldap/openldap.SlackBuild \
		"$SLACKSRC"/n/openldap/openldap.SlackBuild.old
	(
		cd "$SLACKSRC"/n/openldap || exit 1
		sed -i -e "s/--enable-wrappers/--disable-wrappers/" openldap.SlackBuild
		sed -i -e "s/--enable-backends=mod/--enable-backends=no/" openldap.SlackBuild
		sed -i -e "s/--enable-perl=yes/--enable-perl=no/" openldap.SlackBuild
	)
fi
}

execute_sed_pam () {
#******************************************************************
# delete lines that doesn't allow build in build1_.list
#******************************************************************
if [ ! -f "$SLACKSRC"/a/pam/pam.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/a/pam/pam.SlackBuild "$SLACKSRC"/a/pam/pam.SlackBuild.old
	(
		cd "$SLACKSRC"/a/pam || exit 1
		sed -i -e "/xmlto man/d" pam.SlackBuild
	)
fi
}

execute_sed_perl () {
#******************************************************************
# delete several lines in SlackBuild (disable DBD-mysql build on first pass)
#******************************************************************
if [ ! -f "$SLACKSRC"/d/perl/perl.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/d/perl/perl.SlackBuild "$SLACKSRC"/d/perl/perl.SlackBuild.old
	(
		cd "$SLACKSRC"/d/perl || exit 1
		sed -i -e "237,250d" perl.SlackBuild
	)
fi
}

execute_sed_pkg-config () {
#******************************************************************
# add "--with-internel-glib" to SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/d/pkg-config/pkg-config.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/d/pkg-config/pkg-config.SlackBuild \
		"$SLACKSRC"/d/pkg-config/pkg-config.SlackBuild.old
	(
		cd "$SLACKSRC"/d/pkg-config || exit 1
		sed -i -e "/--prefix=\/\usr/p" pkg-config.SlackBuild
		sed -i -e "0,/--prefix=\/\usr/ s/--prefix=\/\usr/--with-internal-glib/" pkg-config.SlackBuild
	)
fi
}

execute_sed_readline () {
#******************************************************************
# disable shared SHLIBS code in SlackBuild
# delete examples/rlfe lines in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/readline/readline.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/readline/readline.SlackBuild "$SLACKSRC"/l/readline/readline.SlackBuild.old
	(
		cd "$SLACKSRC"/l/readline || exit 1
		sed -i -e "/make $NUMJOBS static shared SHLIB_LIBS=-ltinfo/d" readline.SlackBuild
		sed -i -e "/# Link with libtinfo:/a make $NUMJOBS static" readline.SlackBuild
		sed -i -e "/# build rlfe/,+16d" readline.SlackBuild
	)
fi
}

execute_sed_rsync () {
#******************************************************************
# disable shared SHLIBS code in SlackBuild
# delete examples/rlfe lines in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/n/rsync/rsync.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/n/rsync/rsync.SlackBuild "$SLACKSRC"/n/rsync/rsync.SlackBuild.old
	(
		cd "$SLACKSRC"/n/rsync || exit 1
		sed -i -e "/--prefix=\/\usr/p" rsync.SlackBuild
		sed -i -e "0,/--prefix=\/\usr/ s/--prefix=\/\usr/--disable-lz4/" rsync.SlackBuild
		sed -i -e "/--prefix=\/\usr/p" rsync.SlackBuild
		sed -i -e "0,/--prefix=\/\usr/ s/--prefix=\/\usr/--disable-zstd/" rsync.SlackBuild
		sed -i -e "/--prefix=\/\usr/p" rsync.SlackBuild
		sed -i -e "0,/--prefix=\/\usr/ s/--prefix=\/\usr/--disable-xxhash/" rsync.SlackBuild
		sed -i -e "/--prefix=\/\usr/p" rsync.SlackBuild
		sed -i -e "0,/--prefix=\/\usr/ s/--prefix=\/\usr/--disable-openssl/" rsync.SlackBuild
	)
fi
}

execute_sed_subversion () {
#******************************************************************
# delete "--with-kwallet" line in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/d/subversion/subversion.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/d/subversion/subversion.SlackBuild \
		"$SLACKSRC"/d/subversion/subversion.SlackBuild.old
	(
		cd "$SLACKSRC"/d/subversion || exit 1
		sed -i -e "/--with-kwallet/d" subversion.SlackBuild
		sed -i -e "s/\$\NUMJOBS\ install/install/" subversion.SlackBuild
	)
fi
}

execute_sed_texlive () {
#******************************************************************
# change some options from "--with-xxx" in "--without-xxx",
# and add "--disable-web2c" and "--disable-xetex" in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/t/texlive/texlive.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/t/texlive/texlive.SlackBuild "$SLACKSRC"/t/texlive/texlive.SlackBuild.old
	(
		cd "$SLACKSRC"/t/texlive || exit 1
		sed -i -e "s/with-x/without-x/" texlive.SlackBuild
		sed -i -e "s/enable-xindy/disable-xindy/" texlive.SlackBuild
		sed -i -e "s/with-system-pixman/without-system-pixman/" texlive.SlackBuild
		sed -i -e "s/with-system-cairo/without-system-cairo/" texlive.SlackBuild
		sed -i -e "s/with-system-gmp/without-system-gmp/" texlive.SlackBuild
		sed -i -e "s/with-system-mpfr/without-system-mpfr/" texlive.SlackBuild
		sed -i -e "s/with-system-fontconfig/without-system-fontconfig/" texlive.SlackBuild
		sed -i -e "/disable-xindy-rules/p" texlive.SlackBuild
		sed -i -e "0,/disable-xindy-rules/ s/disable-xindy-rules/disable-web2c/" texlive.SlackBuild
		sed -i -e "/disable-web2c/p" texlive.SlackBuild
		sed -i -e "0,/disable-web2c/ s/disable-web2c/disable-xetex/" texlive.SlackBuild
	)
fi
}

execute_sed_zstd () {
#******************************************************************
# delete "zcat" patch line in SlackBuild
#******************************************************************
if [ ! -f "$SLACKSRC"/l/zstd/zstd.SlackBuild.old ]; then
	cp -v "$SLACKSRC"/l/zstd/zstd.SlackBuild "$SLACKSRC"/l/zstd/zstd.SlackBuild.old
	(
		cd "$SLACKSRC"/l/zstd || exit 1
		sed -i -e "/zcat/d" zstd.SlackBuild
	)
fi
}

#*******************************************************************
# End of sub-system of execution of patches
#*******************************************************************

kernel_source_build () {
#********************************************************
# remove everything related to building the kernel image
#********************************************************
cd "$SLACKSRC"/k || exit 1
chmod +x kernel-source.SlackBuild
cp -v kernel-source.SlackBuild kernel-source.SlackBuild.old
sed -i -e "55,92d;111,113d;140,181d" kernel-source.SlackBuild && ./kernel-source.SlackBuild 
upgradepkg --install-new --reinstall /tmp/kernel-source*.txz && mv -v /tmp/kernel-source*.txz /slackware64/k
rm -rf /tmp/package-kernel-source/
mv kernel-source.SlackBuild.old kernel-source.SlackBuild
}

kernel_headers_build () {
#********************************************************
# remove everything related to .config and PRINT_PACKAGE_NAME
#********************************************************
cd "$SLACKSRC"/k || exit 1
chmod +x kernel-headers.SlackBuild
cp -v kernel-headers.SlackBuild kernel-headers.SlackBuild.old
sed -i -e "45,47d;57,64d" kernel-headers.SlackBuild && ./kernel-headers.SlackBuild 
upgradepkg --install-new --reinstall /tmp/kernel-headers*.txz && mv -v /tmp/kernel-headers*.txz /slackware64/d
rm -rf /tmp/package-kernel-headers/
mv kernel-headers.SlackBuild.old kernel-headers.SlackBuild
}

kernel_build_all () {
#***********************************************************
# build kernel and modules before packaging with SlackBuild
#***********************************************************
cd "$SLACKSRC"/k || exit 1

chmod +x build-all-kernels.sh 
chmod +x kernel-*.SlackBuild
if ! ./build-all-kernels.sh;
then 
	exit 1
fi

case $(uname -m) in
	x86_64 )
		cd /tmp/output-x86_64* || exit 1
		mv kernel-source*.t?z /slackware64/k
		mv kernel-headers*.t?z /slackware64/d
		if ! mv kernel-*.t?z /slackware64/a ;
		then 
			exit 1
		fi ;;
	* )
		cd /tmp/output-ia32* || exit 1
		mv kernel-source*.t?z /slackware/k
		mv kernel-headers*.t?z /slackware/d
		if ! mv kernel-*.t?z /slackware/a ;
		then 
			exit 1
		fi ;;
esac
cd /tmp || exit 1
rm -rf ./*
}

build () {
#***********************************************************
# main build procedure for slackware package
#***********************************************************
if { command -v upgradepkg > /dev/null; } 2>&1; 
then
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
# special BUILD package treatment
#**************************

	aspell-word-lists )
		cd "$SLACKSRC"/extra/aspell-word-lists || exit 1
		chmod +x aspell-dict.SlackBuild
		if ! ./aspell-dict.SlackBuild;
		then
			exit 1
		fi ;;

	gettext-tools )
		# two packages in gettext: gettext and gettext-tools
		DIRNAME=gettext
		cd "$SLACKSRC"/"$SRCDIR"/"$DIRNAME" || exit 1
		chmod +x "$PACKNAME".SlackBuild
		if ! ./"$PACKNAME".SlackBuild;
		then
			exit 1
		fi ;;

	installer )
		case "$(uname -m)" in
			i?86)
			  mkdir -pv /root/slackware-current ;;
			x86_64)
			  mkdir -pv /root/slackware64-current ;;
		esac
		cd "$SLACKSRC"/installer || exit 1
		chmod +x installer.SlackBuild
		if ! ./installer.SlackBuild;
		then
			exit 1
		fi ;;

	java )
		cd "$SLACKSRC"/extra/"$PACKNAME" || exit 1
		chmod +x "$PACKNAME".SlackBuild
		if ! ./"$PACKNAME".SlackBuild
		then
			exit 1
		fi ;;
		
	linuxdoc-tools )
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x trackbuild.linuxdoc-tools && chmod +x linuxdoc-tools.build && chmod +x "$PACKNAME".SlackBuild
		if ! ./"$PACKNAME".SlackBuild;
		then
			exit 1
		fi ;;

	mozilla-firefox )
		# need sh shell to be built
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x build-deps/autoconf/autoconf.build
		chmod +x build-deps/cbindgen/cbindgen.build
		chmod +x build-deps/nodejs/nodejs.build
		chmod +x ./*.SlackBuild 
		if ! ( SHELL=/bin/sh ./"$PACKNAME".SlackBuild );
		then
			exit 1
		fi ;;

	mozjs78 )
		# need sh shell to be built
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x autoconf/autoconf.build
		chmod +x ./*.SlackBuild
		if ! ( SHELL=/bin/sh ./"$PACKNAME".SlackBuild );
		then
			exit 1
		fi ;;

	mozilla-thunderbird )
		# need sh shell to be built
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x build-deps/autoconf/autoconf.build
		chmod +x build-deps/cbindgen/cbindgen.build
		chmod +x build-deps/nodejs/nodejs.build
		chmod +x ./*.SlackBuild
		if ! ( SHELL=/bin/sh ./"$PACKNAME".SlackBuild );
		then
			exit 1
		fi ;;

	seamonkey )
		# need sh shell to be built
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x autoconf/autoconf.build 
		chmod +x ./*.SlackBuild
		if ! ( SHELL=/bin/sh ./"$PACKNAME".SlackBuild );
		then
			exit 1
		fi ;;

	snownews )
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x ./*.SlackBuild && gzip -d ./*.diff.gz && sed -i 's/root//' ./*.diff && gzip -9 ./*.diff
		if ! ./"$PACKNAME".SlackBuild
		then
			exit 1
		fi ;;
	
	vim )
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x "$PACKNAME".SlackBuild && chmod +x vim-gvim.SlackBuild
		if ! ( ./"$PACKNAME".SlackBuild && ./vim-gvim.SlackBuild )
		then
			exit 1
		fi ;;

	* )
		# every other package treatment
		cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
		chmod +x "$PACKNAME".SlackBuild
		if ! ./"$PACKNAME".SlackBuild
		then
			exit 1
		fi ;;
esac

case $PACKNAME in
#****************************
# special INSTALL package treatment
#****************************

	aaa_terminfo )
		# remove extra ncurses packages
		rm /tmp/ncurses*.t?z
		if ! $INSTALLPRG /tmp/"$PACKNAME"*.t?z;
		then
			exit 1
		fi ;;

	alpine )
		# package name is not alpine but imapd
		$INSTALLPRG /tmp/imapd*.txz
		if ! $INSTALLPRG /tmp/alpine*.txz;
		then
			exit 1
		fi ;;

	aspell-word-lists )
		# install aspell-en
		if ! $INSTALLPRG /tmp/aspell-en*.txz;
		then
			exit 1
		fi ;;

	etc )
		# remove mini /etc/group and etc/passwd
		rm /etc/group && rm /etc/passwd
		cd /tmp || exit 1
		if ! $INSTALLPRG /tmp/"$PACKNAME"*.t?z
		then
			exit 1
		fi ;;

	installer )
		# doesn't neeed any install
		echo ;;

	java )
		# install java
		if ! $INSTALLPRG /tmp/j*.txz;
		then
			exit 1
		fi ;;

	php )
		# remove extra alpine and imapd packages
		rm /tmp/imapd*.t?z
		rm /tmp/alpine*.t?z
		if ! $INSTALLPRG /tmp/"$PACKNAME"*.t?z;
		then
			exit 1
		fi ;;

	vim )
		# install both vim and vim-gvim packages
		if ! ( $INSTALLPRG /tmp/"$PACKNAME"-*.t?z )
		then
			exit 1
		fi ;;

	* )
		# every other package is built in /tmp
		export TERM=xterm && cd /tmp || exit 1
		if ! $INSTALLPRG /tmp/"$PACKNAME"*.t?z;
		then
			exit 1
		fi ;;

esac

case $PACKNAME in
#****************************
# special MOVE package treatment
#****************************

	alpine )
		# package name is not 'alpine' but 'imapd'
		if ! ( mv -v /tmp/alpine*.txz /slackware64/"$SRCDIR"); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	aspell-word-lists )
		# don't forget to move aspell-en in l/
		mv -v /tmp/aspell-en*.txz /slackware64/l
		# don't forget to move others aspell in extra/
		mkdir -pv /slackware64/extra/aspell-words-list
		if ! ( mv /tmp/aspell*.txz /slackware64/extra/aspell-words-list); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	bash-completion )
		mkdir -pv /slackware64/extra/bash-completion
		if ! ( mv /tmp/bash*.txz /slackware64/extra/bash-completion); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	gettext-tools )
		# don't forget to mv gettext-tools in d/
		if ! ( mv -v /tmp/"$PACKNAME"*.t?z /slackware64/d/ ); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	installer )
		# only move the package to installer directory
		if ! ( mv -v /tmp/installer*.txz /slackware64/installer); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	java )
		# don't forget to mv java in extra/
		if ! ( mv -v /tmp/j*.t?z /slackware64/extra/ ); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	glibc )
		# don't forget to mv glibc-solibs in a/
		mv -v /tmp/aaa_glibc-solibs*.t?z /slackware64/a/
		if ! ( mv -v /tmp/glibc*.t?z /slackware64/"$SRCDIR"); then
			exit 1
		fi
		rm -rf /tmp/*
		cd /scripts || exit 1 ;;

	openssl )
		# don't forget to mv opennsl-solibs in a/
		mv -v /tmp/"$PACKNAME"-solibs*.t?z /slackware64/a/
		if ! ( mv -v /tmp/"$PACKNAME"*.t?z /slackware64/"$SRCDIR" ); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	openssl10 )
		# don't forget to mv opennsl-solibs in a/
		if ! ( mv /tmp/"$PACKNAME"-solibs*.t?z /slackware64/a/ ); then
		mv -v /tmp/"$PACKNAME"*.t?z /slackware64/"$SRCDIR"
			exit 1
		fi
		cd /scripts || exit 1 ;;

	vim )
		# don't forget to mv vim-gvim in xap/ and vim in ap/
		if ! ( mv -v /tmp/vim-gvim*.txz /slackware64/xap && mv -v /tmp/"$PACKNAME"-*.txz /slackware64/ap ); then
			exit 1
		fi
		cd /scripts || exit 1 ;;

	xz )
		# package built in /tmp 
		if ! ( mv /tmp/xz*.txz /slackware64/"$SRCDIR" ); then
			exit 1
		fi
		cd /scripts || exit 1 ;;
	* )
		# mv every built package in its destination directory
		if ! ( mv -v /tmp/"$PACKNAME"*.t?z /slackware64/"$SRCDIR" ); then
			exit 1
		fi
esac

cd /tmp || exit 1
#***************************************************
# Note that the following removes any directory in /tmp.
#***************************************************
for i in *; do
    [ -d "$i" ] && rm -rf "$i"
done
cd /scripts || exit 1
}

build_linux_howtos () {
#*******************************************************************
BUILD=${BUILD:-1}

TMP=${TMP:-/tmp}
PKG=$TMP/package-Linux-HOWTOS

cd "$TMP" || exit 1
mkdir -pv "$PKG"/usr/doc/Linux-HOWTOs
cd "$PKG"/usr/doc/Linux-HOWTOs || exit 1
wget -c http://www.tldp.org/Linux-HOWTO-text.tar.gz
tar xf ./*.tar.gz && rm ./*.tar.gz .htacess

mkdir -p "$PKG"/install
cat /source/f/slack-desc.linux-howtos > "$PKG"/install/slack-desc.linux-howtos

cd "$PKG" || exit 1
chown -R root:root .
/sbin/makepkg -l y -c n "$TMP"/linux-howtos-20160401-noarch-"$BUILD".txz
installpkg "$TMP"/linux-howtos-20160401-noarch-"$BUILD".txz
mv -v "$TMP"/linux-howtos-20160401-noarch-"$BUILD".txz /slackware64/f
rm -rf "$PKG"
cd /scripts || exit 1
}

build_linux_faqs () {
#*******************************************************************
BUILD=${BUILD:-1}

TMP=${TMP:-/tmp}
PKG=$TMP/package-Linux-FAQS

cd "$TMP" || exit 1
mkdir -pv "$PKG"/usr/doc/Linux-FAQs
cd "$PKG"/usr/doc/Linux-FAQs || exit 1
mkdir -pv AfterStep-FAQ && cd AfterStep-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/AfterStep-FAQ/AfterStep-FAQ
cd .. && mkdir -pv Ftape-FAQ && cd Ftape-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/Ftape-FAQ/Ftape-FAQ
cd .. && mkdir -pv LDP-FAQ && cd LDP-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/LDP-FAQ/LDP-FAQ
cd .. && mkdir -pv Linux-FAQ && cd Linux-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/Linux-FAQ/Linux-FAQ
cd .. && mkdir -pv Linux-RAID-FAQ && cd Linux-RAID-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/Linux-RAID-FAQ/Linux-RAID-FAQ
cd .. && mkdir -pv PPP-FAQ && cd PPP-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/PPP-FAQ/PPP-FAQ
cd .. && mkdir -pv Threads-FAQ/html && cd Threads-FAQ/html || exit 1
wget -c www.tldp.org/pub/Linux/docs/faqs-archived/Threads-FAQ/Threads-FAQ-html.tar.gz
tar xf ./*.tar.gz && rm ./*.tar.gz
cd .. && mkdir -pv WordPerfect-Linux-FAQ && cd WordPerfect-Linux-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/WordPerfect-Linux-FAQ/WordPerfect-Linux-FAQ
cd .. && mkdir -pv linux-FAQ && cd linux-FAQ || exit 1
wget -c http://www.tldp.org/pub/Linux/docs/faqs-archived/linux-faq/linux-FAQ
cd .. && mkdir -pv security && cd security || exit 1
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

mkdir -p "$PKG"/install
cat /source/f/slack-desc.linux-faqs > "$PKG"/install/slack-desc.linux-faqs

cd "$PKG" || exit 1
chown -R root:root .
/sbin/makepkg -l y -c n "$TMP"/linux-faqs-20060228-noarch-"$BUILD".txz
installpkg "$TMP"/linux-faqs-20060228-noarch-"$BUILD".txz
mv -v "$TMP"/linux-faqs-20060228-noarch-"$BUILD".txz /slackware64/f
rm -rf "$PKG"
cd /scripts || exit 1
}

clean_tmp () {
#*************************
# cleanup /tmp directory
#*************************
cd / && [ -f localtime ] && rm localtime
cd /tmp || exit 1
rm ./*  2>&1 | tee > /dev/null
rm -rf /tmp/./*  2>&1 | tee > /dev/null
cd /scripts || exit 1
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
echo "Now, you can build SFS by hand, by building packages, one by one."
echo "./package.SlackBuild && installpkg /tmp/package*.t?z"
echo
echo "You can also do it with only one script, by executing the"
echo "following command, there will be 4 steps:"
echo
echo -e "$YELLOW" "time ./sfsbuild1.sh build1_s.list" "$NORMAL"
echo
echo "Either, you can also do it in one step, by executing the"
echo "following command, it will build the entire system till the end:"
echo
echo -e "$BLUE" "time ./sfsbuild1.sh build5_s.list" "$NORMAL"
echo
echo "Either, you can also build a small slackware system with no X11 system, "
echo "by executing the following command:"
echo
echo -e "$RED" "time ./sfsbuild1.sh build0_s.list" "$NORMAL"
}

test_arch () {
#******************************************
# test the architecture i686/586/386 or x86_64 we
# will be build the  slackware distribution,
#******************************************
ARCH=$(uname -m)
echo "$ARCH"
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "i686" ] && [ "$ARCH" != "i586" ] && [ "$ARCH" != "i386" ]; then
	boot_mesg "
 >>> This arch ($ARCH) is not supported."
	echo_failure
	exit 1
fi
}

test_gnat () {
#******************************************
# test the existence of gnat in tools
# if not, modify build1_s.list to have 
# 'd pre-gcc' and 'd post-gcc' to build gcc
#******************************************
(! /tools/bin/gnat) 1> /dev/null && sed -i -e 's/# d/d/g' build1_s.list
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
echo "	SEARCH_DIR(/usr/lib)"
echo "	SEARCH_DIR(/lib)"
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

	if ! { command -v which > /dev/null; } 2>&1; then
		error "which was not found on the system, the 'tools' you built are not complete" && exit 1
	fi
	if ! { command -v tar-1.13 > /dev/null; } 2>&1; then
		error "tar-1.13 was not found on the system, the 'tools' you built are not complete" && exit 1
	fi
	if ! { command -v xz > /dev/null; } 2>&1; then
		error "xz was not found on the system, the 'tools' you built are not complete" && exit 1
	fi
	if ! { command -v patch > /dev/null; } 2>&1; then
		error "patch was not found on the system, the 'tools' you built are not complete" && exit 1
	fi
	if ! { command -v makepkg > /dev/null; } 2>&1; then
		error "makepkg was not found on the system, the 'tools' you built are not complete" && exit 1
	fi
	if ! { command -v installpkg > /dev/null; } 2>&1; then
		error "installpkg was not found on the system, the 'tools' you built are not complete" && exit 1
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
#       Copyright © 1999-2021 Gerard Beekmans and may be
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
#       Copyright © 1999-2021 Gerard Beekmans and may be
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

pre_aaa_libraries_c () {
#******************************************************************
# Install packages from previous slackware to be able
# to build aaa_libraries
#******************************************************************
cd /source/others || exit 1
installpkg cxxlibs-6.0.18-i486-1.txz
installpkg gmp-5.1.3-i486-1.txz
installpkg readline-6.3-i586-2.txz
installpkg readline-7.0.005-i586-1.txz
installpkg libtermcap-1.2.3-i486-7.txz
installpkg ncurses-5.9-i486-4.txz
installpkg libpng-1.4.12-i486-1.txz
installpkg libffi-3.2.1-i586-2.txz
installpkg /slackware/l/libpng-1.6.*.txz
cd /scripts || exit 1
}

pre_aaa_libraries64_c () {
#******************************************************************
# Install packages from previous slackware to be able
# to build aaa_libraries
#******************************************************************
cd /source/others || exit 1
installpkg cxxlibs-6.0.18-x86_64-1.txz
installpkg gmp-5.1.3-x86_64-1.txz
installpkg readline-6.3-x86_64-2.txz
installpkg readline-7.0.005-x86_64-1.txz
installpkg libtermcap-1.2.3-x86_64-7.txz
installpkg ncurses-5.9-x86_64-4.txz
installpkg libpng-1.4.12-x86_64-1.txz
installpkg libffi-3.2.1-x86_64-2.txz
installpkg /slackware64/l/libpng-1.6.*-x86_64*.txz
cd /scripts || exit 1
}

post_aaa_libraries_c () {
#******************************************************************
# Remove packages temporary installed after
# aaa_libraries has been built and installed
#******************************************************************
removepkg cxxlibs-6.0.18-i486-1.txz readline-6.3-i586-2 ncurses-5.9-i486-4
removepkg gmp-5.1.3-i486-1  libtermcap-1.2.3-i486-7 libpng-1.4.12-i486-1.txz
removepkg readline-7.0.005-i586-1.txz
removepkg libffi-3.2.1-i586-2.txz
upgradepkg --reinstall /slackware/l/libpng-1.6.*.txz
upgradepkg --reinstall /slackware/l/readline-8.0.*.txz
cd /scripts || exit 1
}

post_aaa_libraries64_c () {
#******************************************************************
# Remove packages temporary installed after
# aaa_libraries has been built and installed
#******************************************************************
removepkg cxxlibs-6.0.18-x86_64-1.txz readline-6.3-x86_64-2 ncurses-5.9-x86_64-4
removepkg gmp-5.1.3-x86_64-1 libtermcap-1.2.3-x86_64-7 libpng-1.4.12-x86_64-1.txz
removepkg readline-7.0.005-x86_64-1.txz
removepkg libffi-3.2.1-x86_64-2.txz
upgradepkg --reinstall /slackware64/l/libpng-1.6.*.txz
upgradepkg --reinstall /slackware64/l/readline-8.0.*.txz
cd /scripts || exit 1
}

pre_gcc () {
#******************************************************************
# Install gnat-gpl to be able to build gnat-ada package
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2021 Gerard Beekmans and may be
#       copied under the MIT License.
#******************************************************************
cd /tmp || exit 1
case $(uname -m) in
	x86_64)
		if ! tar xf /source/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz; then
			echo
			echo "Tar extraction of gnat-gpl-2017-x86_64-linux-bin failed."
			echo && exit 1
		fi
		cd gnat-gpl-2017-x86_64-linux-bin || exit 1;;
	i686)
		if ! tar xf /source/others/gnat-gpl-2014-x86-linux-bin.tar.gz; then
			echo
			echo "Tar extraction of gnat-gpl-2014-x86-linux-bin failed."
			echo && exit 1
		fi
		cd gnat-gpl-2014-x86-linux-bin || exit 1 ;;
esac

mkdir -pv /tools/opt/gnat
make ins-all prefix=/tools/opt/gnat
PATH_HOLD=$PATH && export PATH=/tools/opt/gnat/bin:$PATH_HOLD
echo "$PATH"
find /tools/opt/gnat -name ld -exec mv -v {} {}.old \;
find /tools/opt/gnat -name ld -exec as -v {} {}.old \;

cd /scripts || exit 1
}

post_gcc () {
#***************************************************************
export PATH=$PATH_HOLD
rm -rf /opt/gnat
}

#****************************************************************
# X11 SUB-SYSTEM BUILDING
#****************************************************************

build_x11_group1 () {
#***********************
cd /source/x/x11 || exit 1

chmod +x x11.SlackBuild

export UPGRADE_PACKAGES=always

for package in \
  xorg-sgml-doctools \
  xorg-docs \
  ; do
   	if ! ./x11.SlackBuild doc $package; then
 		exit 1
	fi
done

if ! ./x11.SlackBuild util util-macros; then
	exit 1
fi

if ! ./x11.SlackBuild xcb libpthread-stubs; then
	exit 1
fi

if ! ./x11.SlackBuild proto xorgproto; then
	exit 1
fi

for package in \
  xorg-cf-files \
  gccmakedep \
  imake \
  lndir \
  makedepend \
  ; do
	if ! ./x11.SlackBuild util $package; then
 		exit 1
	fi
done

mv -v /tmp/x11-build/*.txz /slackware64/x
cd /scripts || exit 1
}

build_x11_lib () {
#***********************
cd /source/x/x11 || exit 1

export UPGRADE_PACKAGES=always

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
	if ! ./x11.SlackBuild lib $package; then
		exit 1
	fi
done

mv -v /tmp/x11-build/*.txz /slackware64/x
cd /scripts || exit 1
}

build_x11_xcb () {
#*****************************
cd /source/x/x11 || exit 1

export UPGRADE_PACKAGES=always

if ! ./x11.SlackBuild proto xcb-proto; then
	exit 1
fi

if ! ./x11.SlackBuild xcb libpthread-stubs; then
	exit 1
fi

for package in \
  libXau \
  libXdmcp \
  libxcb \
  ; do
   	if ! ./x11.SlackBuild lib $package; then
		exit 1
	fi
done

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
   	if ! ./x11.SlackBuild xcb $package; then
 		exit 1
	fi
done

mv -v /tmp/x11-build/*.txz /slackware64/x
cd /scripts || exit 1
}

build_x11_group2 () {
#*****************************
cd /source/x/x11 || exit 1

export UPGRADE_PACKAGES=always

if ! ./x11.SlackBuild data xbitmaps; then
	exit 1
fi

if ! ./x11.SlackBuild font font-util; then
	exit 1
fi

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
   	if ! ./x11.SlackBuild app $package; then
 		exit 1
	fi
done

if ! ./x11.SlackBuild data xcursor-themes; then
	exit 1
fi

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
   	if ! ./x11.SlackBuild font $package; then
 		exit 1
	fi
done

if ! ./x11.SlackBuild data xkeyboard-config; then
	exit 1
fi

for package in \
  xorg-sgml-doctools \
  xorg-docs \
  ; do
   	if ! ./x11.SlackBuild doc $package; then
 		exit 1
	fi
done

if ! ./x11.SlackBuild xserver xorg-server; then
	exit 1
fi

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
   	if ! ./x11.SlackBuild driver $package; then
 		exit 1
	fi
done

if ! ./x11.SlackBuild font encodings; then
	exit 1
fi

for package in \
  luit \
  igt-gpu-tools \
  twm \
  xinit \
  ; do
   	if ! ./x11.SlackBuild app $package; then
 		exit 1
	fi
done

if ! ./x11.SlackBuild driver xf86-video-vboxvideo; then
	exit 1
fi

mv -v /tmp/x11-build/*.txz /slackware64/x
cd /scripts || exit 1
}

build_x11_app_post () {
#*****************************
cd /source/x/x11 || exit 1

export UPGRADE_PACKAGES=always

if ! ./x11.SlackBuild driver xf86-input-libinput; then
	exit 1
fi

if ! ./x11.SlackBuild app xisxwayland; then
	exit 1
fi

mv -v /tmp/x11-build/*.txz /slackware64/x
cd /scripts || exit 1
}

build_extra-cmake-modules () {
#********************************************************
cd /source/kde/kde || exit 1

chmod +x kde.SlackBuild

export UPGRADE_PACKAGES=always
if ! ./kde.SlackBuild frameworks:extra-cmake-modules; then 
	touch /tmp/kde_build/extra-cmake-modules.failed && exit 1
fi

mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /scripts || exit 1
}

build_frameworks () {
#********************************************************
#  frameworks/portaingAids \
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
cd /source/kde/kde || exit 1

export UPGRADE_PACKAGES=always

# build all frameworks first

for package in \
	extra-cmake-modules \
	attica \
	kitemmodels \
	kitemviews \
	kplotting \
	threadweaver \
	kcodecs \
	kdbusaddons \
	kcoreaddons \
	kguiaddons \
	kidletime \
	kwidgetsaddons \
	sonnet \
	kconfig \
	kwindowsystem \
	solid \
	karchive \
	ki18n \
	networkmanager-qt \
	modemmanager-qt \
	bluez-qt \
	prison \
	kirigami2 \
	syntax-highlighting \
	kholidays \
	kcalendarcore \
	kcontacts \
	breeze-icons \
	kapidox \
	kdnssd \
	oxygen-icons5 \
	kauth \
	kcrash \
	kjobwidgets \
	kcompletion \
	kdoctools \
	kpackage \
	knotifications \
	kunitconversion \
	kpty \
	kimageformats \
	kfilemetadata \
	syndication \
	kquickcharts \
	kconfigwidgets \
	kservice \
	kglobalaccel \
	kiconthemes \
	kwallet \
	kemoticons \
	kdesu \
	ktextwidgets \
	kxmlgui \
	kbookmarks \
	kded \
	kio \
	knewstuff \
	kparts \
	kdewebkit \
	kdesignerplugin \
	kdeclarative \
	kcmutils \
	kinit \
	knotifyconfig \
	ktexteditor \
	kactivities \
	kactivities-stats \
	plasma-framework \
	kpeople \
	kxmlrpcclient \
	baloo \
	qqc2-desktop-style \
	purpose \
	kjs \
	kjsembed \
	kross \
	kmediaplayer \
	krunner \
	frameworkintegration \
	kdelibs4support \
	khtml \
	kdav \
  ; do
   	if ! ./kde.SlackBuild frameworks:$package; then
		touch /tmp/kde_build/$package.failed && exit 1
	fi
done

for package in \
	kdelibs4support \
	kdesignerplugin \
	kdewebkit \
	khtml \
	kjs \
	kjsembed \
	kmediaplayer \
	kross \
	kxmlrpcclient \
  ; do
   	if ! ./kde.SlackBuild frameworks:$package; then 
		touch /tmp/kde_build/$package.failed && exit 1
	fi
 done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /scripts || exit 1
}

build_kdepim () {
#********************************************************
cd /source/kde/kde || exit 1

export UPGRADE_PACKAGES=always

if ! ./kde.SlackBuild applications-extra:kdiagram; then
	touch /tmp/kde_build/kdiagram.failed
fi

for package in \
	akonadi \
	kpimtextedit \
	kidentitymanagement \
	kcalutils \
	libkgapi \
	kmime \
	ksmtp \
	kimap \
	kmbox \
	kldap \
	kontactinterface \
	ktnef \
	grantleetheme \
	akonadi-mime \
	libkleo \
	akonadi-contacts \
	akonadi-notes \
	akonadi-search \
	kalarmcal \
	kmailtransport \
	akonadi-calendar \
	libkdepim \
	pimcommon \
	libgravatar \
	libksieve \
	mailimporter \
	calendarsupport \
	eventviews \
	incidenceeditor \
	messagelib \
	mailcommon \
	kleopatra \
	kpkpass \
  	kopeninghours \
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
   	if ! ./kde.SlackBuild kdepim:$package; then
		touch /tmp/kde_build/$package.failed && exit 1
	fi
done

if ! ./kde.SlackBuild plasma-extra:plasma-wayland-protocols; then
	touch /tmp/kde_build/$package.failed && exit 1
fi

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /scripts || exit 1
}

build_plasma () {
#********************************************************
cd /source/kde/kde || exit 1

export UPGRADE_PACKAGES=always

if ! ./kde.SlackBuild plasma-extra:plasma-wayland-protocols; then
	touch /tmp/kde_build/$package.failed && exit 1
fi

if ! ./kde.SlackBuild frameworks:kwayland; then 
	touch /tmp/kde_build/kwayland.failed && exit 1
fi

for package in \
	kgamma5 \
	kdecoration \
	breeze \
	breeze-gtk \
	breeze-grub \
	breeze-plymouth \
	qqc2-breeze-style \
	kwayland-integration \
	kwayland-server \
	plasma-integration \
	kinfocenter \
	layer-shell-qt \
	libksysguard \
	kscreenlocker \
	kwin \
	kwrited \
	libkscreen \
	milou \
	oxygen \
	plasma-workspace \
	kde-cli-tools \
	systemsettings \
	plasma-desktop \
	kdeplasma-addons \
	plasma-workspace-wallpapers \
	plasma5-nm \
	powerdevil \
	bluedevil \
	khotkeys \
	kmenuedit \
	polkit-kde-agent-1 \
	kscreen \
	sddm-kcm \
	kde-gtk-config \
	ksshaskpass \
	plasma-sdk \
	plasma-pa \
	kactivitymanagerd \
	xdg-desktop-portal-kde \
	drkonqi \
	plasma-vault \
	plasma-browser-integration \
	kwallet-pam \
	plasma-disks \
	plasma-nm \
	plasma-nano \
	plasma-firewall \
	plasma-phone-components \
	plasma-systemmonitor \
	plasma-tests \
	plasma-thunderbolt \
	plasma-kcm \
	ksystemstats \
  ; do
   	if ! ./kde.SlackBuild plasma:$package; then
		touch /tmp/kde_build/$package.failed && exit 1
	fi
done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /scripts || exit 1
}

build_plasma-extra () {
#********************************************************
cd /source/kde/kde || exit 1

export UPGRADE_PACKAGES=always

for package in \
	sddm \
	kpeoplevcard \
	pulseaudio-qt \
	latte-dock \
	oxygen-fonts \
	plasma-wayland-protocols \
	wacomtablet \
  ; do
   	if ! ./kde.SlackBuild plasma-extra:$package; then
		touch /tmp/kde_build/$package.failed && exit 1
	fi
done

if ! ./kde.SlackBuild applications:libktorrent; then
	touch /tmp/kde_build/libktorrent.failed && exit 1
fi

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

cd /source/kde/kcm-fcitx || exit 1
chmod +x kcm-fcitx.SlackBuild
if ! ./kcm-fcitx.SlackBuild; then
	touch /tmp/kde_build/kcm-fcitx.failed && exit 1
fi

mv -v /tmp/kcm-fcitx*.txz /slackware64/kde
mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /tmp || exit 1
rm ./*
rm -rf /tmp/./*
cd /scripts || exit 1
}

build_applications () {
#********************************************************
cd /source/kde/kde || exit 1

export UPGRADE_PACKAGES=always

for package in \
	libkipi \
	kipi-plugins \
	libkexiv2 \
	libkdcraw \
	libksane \
	gwenview \
	kio-extras \
	kio-gdrive \
	konsole \
	kate \
	kdialog \
	keditbookmarks \
	kfind \
	konqueror \
	ark \
	baloo-widgets \
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
	elisa \
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
	kmplot \
	kqtquickcharts \
	ktouch \
	kturtle \
	kwordquiz \
	marble \
	rocs \
	step \
	minuet \
	kdenlive \
	kimagemapeditor \
	yakuake \
	kdeconnect-kde \
	markdownpart \
	kpublictransport \
	kosmindoormap \
	itinerary \
	kontrast \
	konversation \
	libktorrent \
	ktorrent \
	kpmcore \
	partitionmanager \
	skanlite \
  ; do
   	if ! ./kde.SlackBuild applications:$package; then
		touch /tmp/kde_build/$package.failed && exit 1
	fi
done

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /scripts || exit 1
}

build_applications-extra () {
#********************************************************
cd /source/kde/kde || exit 1

export UPGRADE_PACKAGES=always

for package in \
	calligra \
	calligraplan \
	digikam \
	krita \
	falkon \
	kdevelop-pg-qt \
	kdevelop \
	kdev-php \
	kdev-python \
	kdiagram \
	kjots \
	kstars \
	krusader \
	kile \
	oxygen-gtk2 \
	alkimia \
 	kmymoney \
	okteta \
	krename \
	ktimetracker \
	kid3 \
  ; do
   	if ! ./kde.SlackBuild applications-extra:$package; then
		touch /tmp/kde_build/$package.failed && exit 1
	fi
done

if ! ./kde.SlackBuild applications:umbrello; then
	touch /tmp/kde_build/$package.failed && exit 1
fi 

# Keep MIME database current:
/usr/bin/update-mime-database /usr/share/mime 1>/dev/null 2>/dev/null &

mv -v /tmp/kde_build/*.txz /slackware64/kde
cd /scripts || exit 1
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
echo -e "$YELLOW" "time ./sfsbuild1.sh build2_s.list" "$NORMAL"
echo
echo "After that, you should have an X11 system with blackbox."
echo
echo
cd /scripts && killall -9 dhcpcd
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
echo -e "$YELLOW" "time ./sfsbuild1.sh build3_s.list" "$NORMAL"
echo
echo "After that you should have an X11 system with xfce."
echo
echo
cd /scripts && killall -9 dhcpcd
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
echo -e "$YELLOW"  "time ./sfsbuild1.sh build4_s.list" "$NORMAL"
echo
echo "After that you should have a complete Slackware system"
echo
echo
cd /scripts && killall -9 dhcpcd
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
cd /slackware64 && rm */*_alsa* 2>&1 | tee > /dev/null
cd /scripts && killall -9 dhcpcd
}

update_slackbuild () {
#****************************************************************
# rename SlackBuild.old to original SlackBuild
#****************************************************************
cd /source/"$SRCDIR"/"$PACKNAME" || exit 1 
mv "$PACKNAME".SlackBuild.old "$PACKNAME".SlackBuild
cd /scripts || exit 1
}

build_pkg_1 () {
#**************
execute_sed_"$PACKNAME"
if ! build "$SRCDIR" "$PACKNAME"; then
	exit 1
fi
update_slackbuild
}

build_pkg_2 () {
#**************
if ! build "$SRCDIR" "$PACKNAME"; then
	exit 1
fi
return
}

build_pkg_3 () {
#**************
if ! build_"$PACKNAME"; then
	exit 1
fi
return
}

#****************************************************************
#****************************************************************
# MAIN CORE SCRIPT of sfsbuild1
#****************************************************************
#****************************************************************
test_arch
test_gnat
define_path_lib

#****************************************************************
# Ensure that the /slackware64/$SAVDIRs exists.
#****************************************************************
mkdir -pv /slackware64/{others,a,ap,d,e,extra,f,installer,k,kde,l,n,t,tcl,x,xap,xfce,y}
mkdir -pv /slackware64/extra/{aspell-words-list,bash-completion,bittornado,brltty,fltk,getty-ps,java,php8,sendmail,tigervnc,xf86-video-fbdev,xfractint,xv}
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
#	execute_libusb_sed # 2 pass
#	execute_llvm_sed # 2 pass
#	execute_pkg_config_sed # 2 pass
#	execute_readline_sed # 3 pass
#	execute_subversion_sed # 2 pass
#	execute_texlive_sed # 2 pass
#	execute_zstd_sed # 2 pass
#	execute_perl_sed # 2 pass
#	execute_openldap_sed # 2 pass
# 	execute_libtirpc_sed variable # 2 pass
# 	execute_elogind_sed variable # 2 pass
# 	execute_libxkbcommon_sed variable # 2 pass
#
#******************************************************************
# BUILDN: defines if package will be installed or upgraded
#******************************************************************
# init libusb variable
LUSB=1
# init llvm variable
LPVM=1
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
# init findutils variable
LFIN=1
# init zstd variable
LZST=1
# init rsync variable
LRSY=1
# init perl variable
LPER=1
# init openldap variable
LOPE=1
# init libtirpc variable
LRPC=1
# init libxkbcommon variable
LXKB=1
# init doxygen variable
LDOX=1
# init efivar variable
LEFI=1
# init NUMJOBS variable
NUMJOBS="-j$(( $(nproc) * 2 )) -l$(( $(nproc) + 1 ))"

#**************************************************************
# read the length of build.list and affect SRCDIR and PACKNAME
#**************************************************************

[ "$1" == "" ] && on_error
[ ! -f "$1" ] && on_error
LISTFILE=$1

FILELEN=$(wc -l "$LISTFILE" |cut -d' ' -f1)

typeset -i LINE=0
while read -r RA[LINE]; do
	(( LINE = LINE + 1 ))
done <<< "$(cat "$LISTFILE")"

(( LINE = 0 ))
while (( LINE < FILELEN )); do
	aline=${RA[LINE]}
	echo "$aline"
	SRCDIR=$(echo "$aline" |cut -d' ' -f1)
	PACKNAME=$(echo "$aline" |cut -d' ' -f2)
	(( LINE = LINE + 1 ))
	[ "$SRCDIR" == "#" ] && continue

			case $PACKNAME in

				adjust )
					case $(uname -m) in
						x86_64 )
							if ! adjust_x86_64; then
								exit 1
							fi ;;
						* )
							if ! adjust_i686; then
								exit 1
							fi ;;
					esac
					continue ;;

				alsa-lib )
					case $LISTFILE in
						build2_s.list )
							build_pkg_1 ;;
						* )
							rm /slackware64/l/alsa-lib*.t?z
							build_pkg_1 ;;
					esac
					continue ;;

				ca-certificates )
					build_pkg_2
					update-ca-certificates ;;

				cmake )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;; 
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				cyrus-sasl )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				dbus )
					case $LISTFILE in
						build2_s.list )
							build_pkg_1 
							dbus-uuidgen --ensure ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				doxygen )
					case $LDOX in
						1 )
							build_pkg_1
							LDOX=2 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				dhcpcd_up )
					if ! (dhcpcd -t 15 -L eth0 || dhcpcd -t 15 -L wlan0); then
						exit 1
					fi ;;

				end1 )
					message_"$PACKNAME"
					clean_tmp ;;

				end2 )
					message_"$PACKNAME"
					clean_tmp ;;

				end3 )
					message_"$PACKNAME"
					clean_tmp ;;

				end4 )
					message_"$PACKNAME"
					clean_tmp ;;

				elogind )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;


				efivar )
					case $LEFI in
						1 )
							build_pkg_1
							[ $? != 0 ] && exit 1
							LEFI=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				findutils )
					case $LFIN in
						1 )
							build_pkg_1
							LFIN=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				fontconfig )
					case $LISTFILE in
						build2_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				freetype )
					case $LFRE in
						1 )
							build_pkg_1 
							LFRE=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				gd )
					case $LGD in
						1 )
							build_pkg_1
							LGD=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				glib2 )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;;
						build2_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				glib-networking )
					update-ca-certificates
					build_pkg_2 ;;

				gobject-introspection )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;; 
						build2_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				gpgme )
					case $LISTFILE in
						build3_s.list )
							build_pkg_1 ;;
						build4_s.list )
							build_pkg_2 ;;
					esac
					continue ;;

				gucharmap )
					update-ca-certificates --fresh
					build_pkg_1 ;; 

				harfbuzz )
					case $LHAR in
						1 )
							build_pkg_1
							LHAR=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				installer )
					build_pkg_2 ;;

				isapnptools )
					case $ARCH in
						x86_64 )
							echo ;;
						* )
							build_pkg_1 ;;
					esac
					continue ;;

				extra-cmake-modules )
					build_pkg_3 ;;

				frameworks )
					build_pkg_3 ;;

				kdepim )
					build_pkg_3 ;;

				applications )
					build_pkg_3 ;;

				applications-extra )
					build_pkg_3 ;;

				plasma )
					build_pkg_3 ;;

				plasma-extra )
					build_pkg_3 ;;

				kernel-all )
					if ! kernel_build_all; then
						exit 1
					fi
					return ;;

				kernel-headers )
					if ! kernel_headers_build; then
						exit 1
					fi
					return ;;

				kernel-source )
					if ! kernel_source_build; then
						exit 1
					fi
					return ;;

				kmod )
					case $LKMO in
						1 )
							build_pkg_1
							LKMO=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				ksh93 )
					upgradepkg --install-new /source/others/"$PACKNAME"-*"$ARCH"-*.txz
					build_pkg_2 ;;

				link_tools_slackware )
					test_progs
					case $ARCH in
						x86_64 )
 							if ( link_tools_x64 ); then
								echo_message_slackware && exit 1
							fi
							return ;;
						* )
							if ( link_tools ); then
								echo_message_slackware && exit 1
							fi
							return ;;
					esac
					continue ;;

				libcaca )
					upgradepkg --install-new /source/others/"$PACKNAME"-*"$ARCH"-*.txz
					build_pkg_2 ;;

				libsoup )
					source /root/.bashrc
					build_pkg_2 ;;

				libtirpc )
					case $LRPC in
						1 )
							export WITH_GSS="NO"
							build_pkg_2 
							export WITH_GSS="YES"
							LRPC=2 ;;
						* )
							export WITH_GSS="YES"
							build_pkg_2 ;;
					esac
					continue ;;

				libusb )
					case $LUSB in
						1 )
							build_pkg_1
							LUSB=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				linux-faqs )
					if ! build_linux_faqs; then 
						exit 1
					fi
					return ;;

				linux-howtos )
					if ! build_linux_howtos; then
						exit 1
					fi
					return ;;

				libxkbcommon )
					case $LXKB in
						1 )
							build_pkg_1
							LXKB=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				llvm )
					case $LPVM in
						1 )
							build_pkg_1
							LPVM=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				mesa )
					case $LMES in
						1 )
							export BUILD_DEMOS=NO
							build_pkg_2
							LMES=2 ;;
						2 )
							export BUILD_DEMOS=YES
							build_pkg_2 ;;
					esac
					continue ;;

				openldap )
					case $LOPE in
						1 )
							build_pkg_1
							LOPE=2 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				pam )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;;
						build2_s.list )
							build_pkg_2 ;;
					esac
					continue ;;


				pci-utils )
					build_pkg_2
					update-pciids ;;

				perl )
					case $LPER in
						1 )
							build_pkg_1
							LPER=2 ;;
						2 )
							build_pkg_2 ;;
					esac
					continue ;;

				pkg-config )
					case $LISTFILE in
						build1_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				pre-aaa_libraries )
					case $ARCH in
						x86_64 )
							if ! pre_aaa_libraries64_c; then
								exit 1
							fi
							return ;;
						* )
							if ! pre_aaa_libraries_c; then
								exit 1
							fi
							return ;;
					esac
					continue ;;

				post-aaa_libraries )
					case $ARCH in
						x86_64 )
							if ! post_aaa_libraries64_c; then
								exit 1
							fi
							return ;;
						* )
							if ! post_aaa_libraries_c; then
								exit 1
							fi
							return ;;
					esac
					continue ;;

				pre-gcc )
					if ! pre_gcc; then
						exit 1
					fi
					return ;;

				post-gcc )
					if ! post_gcc; then
						exit 1
					fi
					return ;;

				readline )
					case $LREA in
						1 )
							build_pkg_1
							LREA=2 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				rsync)
					case $LRSY in
						1 )
							build_pkg_1
							LRSY=2 ;;

						* )
							build_pkg_2 ;;
					esac
					continue ;;

				subversion )
					case $LISTFILE in
						build3_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				texlive )
					case $LISTFILE in
						build2_s.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				utempter )
					touch /var/run/utmp && build_pkg_2 ;;

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
					if ! build_x11_group1; then
						exit 1
					fi
					return ;; 

				x11-group2 )
					if ! build_x11_group2; then
						exit 1
					fi
					return ;;  

				x11-lib )
					if ! build_x11_lib; then
						exit 1
					fi
					return ;;  

				x11-xcb )
					if ! build_x11_xcb; then
						exit 1
					fi
					return ;;  

				x11-app-post )
					if ! build_x11_app_post; then
						exit 1
					fi
					return ;;  

				zstd )
					case $LZST in
						1 )
							build_pkg_1
							LZST=2 ;;
						2 )
							build_pkg_2 ;; 
					esac
					continue ;;
	
				* )
					build_pkg_2 ;;
			esac
done
echo
