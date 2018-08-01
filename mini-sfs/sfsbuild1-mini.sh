############################ sfsbuild1-mini.sh #################################
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
#-------------------------------------------------------------------------------
#
#	sfsbuild1-mini.sh is a subset of sfsbuild1.sh limited to build bare system
#
#	This script builds part of the Slackware from Scratch system using the
#	source directory from the Slackware sources
#
#	Revision 0				13072018					nobodino
#		-initial release for slackware-current boostrap
#		-only to build list1 (bare slackware system)
#
################################################################################
# set -x
#*********************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#**********************************
on_error () {
#***********************************************************
# recalls the usage of the main script in case of error
#***********************************************************
echo 	"Usage: sfsbuild1.sh build1.list"
echo
echo	"The build.list of programs to build, and their source directories is required."
echo
echo	"The packages will not be processed until the end of the build.list."
echo
exit -1
}

adjust_i686 () {
#***********************************************************
# First, backup the /tools linker, and replace it with the
# adjusted linker we made in chapter 5. We'll also create a
# link to its counterpart in /tools/$(gcc -dumpmachine)/bin:
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
# files. A sed command accomplishes this:build1d.list
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

kernel_headers_build_c () {
#********************************************************
# build kernel_headers
#********************************************************
PKGNAM=linux
VERSION=${VERSION:-$(echo /slacksrc/k/$PKGNAM-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
BUILD=${BUILD:-1}
CWD=$(pwd)
TMP=${TMP:-/tmp}
PKG=$TMP/kernel-headers
cd /usr/src
tar xf /slacksrc/k/$PKGNAM-$VERSION.tar.xz
cd /usr/src/$PKGNAM-$VERSION
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
# the kernel-headers will be in $PKG
mkdir -pv $PKG/usr/include/{asm,asm-generic,drm,linux,mtd,rdma,scsi,sound,video,xen}
mkdir -pv $PKG/install
cp -rv dest/include/* /tmp/kernel-headers/usr/include
cat /slacksrc/d/kernel-headers/slack-desc > $PKG/install/slack-desc
cd /tmp/kernel-headers
case $(uname -m) in
	x86_64 )
		VERSION1=${VERSION1:-$(echo /slacksrc/k/$PKGNAM-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)} ;;
	*  )
		VERSION1=${VERSION1:-$(echo /slacksrc/k/$PKGNAM-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)_smp} ;;
esac
makepkg -l y -c n /tmp/kernel-headers-$VERSION1-x86-$BUILD.txz
upgradepkg --install-new --reinstall /tmp/kernel-headers-$VERSION1-x86-$BUILD.t?z
mv -v /tmp/kernel-headers-$VERSION1-x86-$BUILD.txz /sfspacks/d
rm -rf /tmp/kernel-headers/
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
# main build procedure for normal package
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
	gettext-tools )
		# two packages in gettext: gettext and gettext-tools
		DIRNAME=gettext
		cd /slacksrc/$SRCDIR/$DIRNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
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
	etc )
		# remove mini /etc/group and etc/passwd
		rm /etc/group && rm /etc/passwd
		cd /tmp
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	* )
		# every other package is built in /tmp
		cd /tmp
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

esac

case $PACKNAME in
#****************************
# MOVE package treatment
#****************************

	gettext-tools )
		# don't forget to mv gettext-tools in d/
		cd /tmp
		mv /tmp/$PACKNAME*.t?z /sfspacks/d/
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

build1 () {
#*******************************************************************
# build procedure for normal package after a first build with build
# procedure these packages are only upgraded when built with SlackBuild.old
#*******************************************************************

INSTALLPRG="upgradepkg --install-new --reinstall"
SRCDIR=$1
shift
PACKNAME=$1
shift

#******************************************************************
# this package $PACKNAME has been already built in a
# preliminary form, but now in its definitive form with SlackBuild.old
#******************************************************************
case $PACKNAME in
#**************************
# BUILD package treatment
#**************************
	* )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild.old && ./$PACKNAME.SlackBuild.old
		[ $? != 0 ] && exit 1 ;;

esac

cd /tmp

case $PACKNAME in

	* )
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;
esac

case $PACKNAME in

	* )
		mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
		[ $? != 0 ] && exit 1 ;;
esac

cd /tmp
#******************************************************************
# Note that the following removes any SBo directory.
#******************************************************************
for i in *; do
    [ -d "$i" ] && rm -rf $i
done
cd /sources
}

clean_tmp1 () {
#*************************
# cleanup /tmp directory
#*************************
cd / && rm localtime
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
# Note: Much of this script is copied from the LFS-8.1 manual.
#       Copyright © 1999-2015 Gerard Beekmans and may be
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
# Note: Much of this script is copied from the LFS-8.1 manual.
#       Copyright © 1999-2015 Gerard Beekmans and may be
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
installpkg libtermcap-1.2.3-i486-7.txz
installpkg ncurses-5.9-i486-4.txz
installpkg libpng-1.4.12-i486-1.txz
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
installpkg libtermcap-1.2.3-x86_64-7.txz
installpkg ncurses-5.9-x86_64-4.txz
installpkg libpng-1.4.12-x86_64-1.txz
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
installpkg /sfspacks/l/libpng-1.6.*.txz
cd /sources
}

post_elflibs64_c () {
#******************************************************************
# Remove packages temporary installed after
# aaa_elflibs has been built and installed
#******************************************************************
removepkg cxxlibs-6.0.18-x86_64-1.txz readline-6.3-x86_64-2 ncurses-5.9-x86_64-4
removepkg gmp-5.1.3-x86_64-1 libtermcap-1.2.3-x86_64-7 libpng-1.4.12-x86_64-1.txz
installpkg /sfspacks/l/libpng-1.6.*.txz
cd /sources
}

pre_gcc () {
#***************************************************************
cd /tmp
case $(uname -m) in
	x86_64)
		tar xf /slacksrc/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz
		if [ $? != 0 ]; then
			echo
			echo "Tar extraction of gnat-gpl-2017-x86_64-linux-bin failed."
			echo
		exit 1
		fi
		cd gnat-gpl-2017-x86_64-linux-bin
		[ $? != 0 ] && exit 1 ;;
	i686)
		tar xf /slacksrc/others/gnat-gpl-2014-x86-linux-bin.tar.gz
		if [ $? != 0 ]; then
			echo
			echo "Tar extraction of gnat-gpl-2014-x86-linux-bin failed."
			echo
		exit 1
		fi
		cd gnat-gpl-2014-x86-linux-bin
		[ $? != 0 ] && exit 1 ;;
esac

mkdir -pv /tools/opt/gnat
make ins-all prefix=/tools/opt/gnat
PATH_HOLD=$PATH && export PATH=/tools/opt/gnat/bin:$PATH_HOLD
echo $PATH
find /tools/opt/gnat -name ld -exec mv -v {} {}.old \;
find /tools/opt/gnat -name ld -exec as -v {} {}.old \;

cd /sources
}

post_gcc () {
#***************************************************************
export PATH=$PATH_HOLD
rm -rf /opt/gnat
cd /tmp && rm gcc.build.log
}

message_end1 () {
#****************************************************************
echo
echo "sfsbuild1.sh has finished to build the first part of SFS."
echo "You now have a bare slackware system able to boot."
echo "You can modify your bootloader to test your new environment."
echo "Or you can:"
echo
echo -e "$YELLOW"  "exit" "$NORMAL"
echo
echo
cd /sources
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
mkdir -pv /sfspacks/{others,a,ap,d,e,extra,f,k,kde,kdei,l,n,t,tcl,x,xap,xfce,y}

#******************************************************************
# BUILDN: defines if package will be installed or upgraded
#******************************************************************

# init pkg-config variable
LPKG=1
# init libcap variable
LCAP=1
# init kmod variable
LKMO=1
# init readline variable
LREA=1

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

				end1 )
					message_end1
					clean_tmp1 ;;

				kernel-all )
					kernel_build_all
					[ $? != 0 ] && exit 1 ;;

				kernel-headers )
					kernel_headers_build_c
					[ $? != 0 ] && exit 1 ;;

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

				pre-gcc )
					pre_gcc
					[ $? != 0 ] && exit 1 ;;

				post-gcc )
					post_gcc
					[ $? != 0 ] && exit 1 ;;

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

				kmod )
					case $LKMO in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LKMO=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				libcap )
					case $LCAP in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LCAP=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				pkg-config )
					case $LPKG in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LPKG=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				readline )
					case $LREA in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LREA=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 
							LREA=3 ;;

						3 )
							rm /sfspacks/l/readline*.t?z
							build1 $SRCDIR $PACKNAME
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
	
				* )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

			esac
done

echo
