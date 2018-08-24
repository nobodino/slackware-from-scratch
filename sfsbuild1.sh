################################  sfsbuild1.sh #################################
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
# Note: The adjust and link_tools procedures of this script are 
#       inspired from the LFS manual chapter 6.10
#       Copyright © 1999-2018 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
#
#	sfsbuild1.sh
#
#	This script builds part of the Slackware from Scratch system using the
#	source directory from the Slackware sources
#
#	Revision 0				12042018					nobodino
#		-initial release for slackware-current boostrap (can't build slackware-14.2)
#	Revision 1				20042018					nobodino
#		-modified for 'third mass rebuild'
#	Revision 2				12052018					nobodino
#		-modified build_post_kde2 (only 3 packages left)
#		-modified jdk build: switch to extra/java
#		-added linux-faqs treatment
#		-added openssl10 treatment
#		-restored libpng14.so.14
#	Revision 3			03072018		nobodino
#		-restored cxxlibs-6.0.18 (libstdc++.so.5)
#		-removed end{1 to 4}		
#		-modified readline
#		-added harfbuzz and freetype two pass building
#		-added alsa-lib (two pass building: without pulseaudio and with pulseaudio)
#	Revision 4			20072018		nobodino
#		-removed first build of baloo, baloo-widgets and gwenview
#		-removed first build of xf86-video-geode, xf86-input-libinput and xf86-video-vboxvideo
#		-added QScintilla two pass building
#		-added vituoso-ose building (disable openssl-1.1. temporary))
#		-changed intel-gpu-tools to igt-gpu-tools
#	Revision 5			28072018		nobodino
#		-modified message_end4 (added pkill dhcpcd)
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
		
	linuxdoc-tools)
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x trackbuild.linuxdoc-tools && chmod +x linuxdoc-tools.build && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozilla-firefox )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-firefox.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozilla-thunderbird )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-thunderbird.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	seamonkey )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./seamonkey.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	xfce )
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
		# install aspell-en
		$INSTALLPRG /tmp/j*.txz
		[ $? != 0 ] && exit 1 ;;

	php )
		# php builds also alpine and imapd
		rm /tmp/imapd*.t?z
		rm /tmp/alpine*.t?z
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	xfce )
		echo ;;

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

	seamonkey )
		# don't forget to mv seamonkey-solibs in l/
		cd /tmp
		mv /tmp/$PACKNAME-solibs*.t?z /sfspacks/l/
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

	vim )
		cd /slacksrc/$SRCDIR/$PACKNAME
		chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		chmod +x vim-gvim.SlackBuild && ./vim-gvim.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	* )
		# every other package treatment
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild.old && ./$PACKNAME.SlackBuild.old
		[ $? != 0 ] && exit 1 ;;

esac

cd /tmp

case $PACKNAME in
	vim )
		$INSTALLPRG /tmp/vim-gvim*.t?z
		$INSTALLPRG /tmp/$PACKNAME-*.t?z
		[ $? != 0 ] && exit 1 ;;
	* )
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;
esac
#******************************************************************
# remove the temporary package *_sfs and replace it with a normal one
#******************************************************************
rm /sfspacks/$SRCDIR/$PACKNAME*_sfs.txz

case $PACKNAME in

	vim )
		mv -v /tmp/vim-gvim*.txz /sfspacks/xap
		mv -v /tmp/$PACKNAME-*.txz /sfspacks/ap
		[ $? != 0 ] && exit 1 ;;
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
#       Copyright © 1999-2018 Gerard Beekmans and may be
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
#       Copyright © 1999-2018 Gerard Beekmans and may be
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
#******************************************************************
# Install gnat-gpl to be able to build gnat-ada package
#
# Note: Much of this script is copied from the LFS manual.
#       Copyright © 1999-2018 Gerard Beekmans and may be
#       copied under the MIT License.
#******************************************************************
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


#****************************************************************
# X11 SUB-SYSTEM BUILDING
#****************************************************************


build_x11_doc () {
#***********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild doc xorg-sgml-doctools
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild doc xorg-docs
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild util util-macros
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_proto () {
#***********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild proto bigreqsproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto compositeproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto damageproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto dmxproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto dri2proto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto dri3proto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto evieext
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto fixesproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto fontcacheproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto fontsproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto glproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto inputproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto kbproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto presentproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto printproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto randrproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto recordproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto renderproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto resourceproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto scrnsaverproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto videoproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xcmiscproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xextproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xf86bigfontproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xf86dgaproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xf86driproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xf86miscproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xf86vidmodeproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xineramaproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild proto xproto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_proto_c () {
#***********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild proto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_util () {
#***********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild util xorg-cf-files
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild util gccmakedep
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild util imake
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild util lndir
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild util makedepend
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_lib () {
#*************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild lib libXau
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXdmcp
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-proto
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb libpthread-stubs
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb libxcb
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib xtrans
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libX11
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXext
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libFS
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libICE
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libSM
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXScrnSaver
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXt
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXmu
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXpm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXaw
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXfixes
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXcomposite
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXrender
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXcursor
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXdamage
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXfontenc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXft
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXinerama
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXrandr
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXres
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXtst
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXv
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXvMC
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXpresent
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXxf86dga
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXxf86vm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libdmx
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libfontenc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libpciaccess
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libxkbfile
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libxshmfence
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXcm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXevie
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXxf86misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXp
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXfontcache
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXaw3d
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib pixman
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXfont
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild lib libXfont2
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_xcb () {
#*****************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild xcb xcb-util
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-util-image
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-util-keysyms
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-util-renderutil
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-util-wm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-util-cursor
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xcb-util-errors
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild xcb xpyb
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv  -v *.txz /sfspacks/x
cd /slacksrc/x/x11
}

build_x11_app () {
#**********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild data xbitmaps
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-util
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app bdftopcf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app iceauth
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app mkfontdir
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app mkfontscale
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app sessreg
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app setxkbmap
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app smproxy
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app x11perf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xauth
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xbacklight
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xcmsdb
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xcursorgen
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xdpyinfo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xdriinfo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xev
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xgamma
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xhost
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xinput
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xkbcomp
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xkbevd
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xkbutils
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xkill
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xlsatoms
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xlsclients
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xmessage
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xmodmap
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xpr
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xprop
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xrandr
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xrdb
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xrefresh
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xset
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xsetroot
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xvinfo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xwd
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xwininfo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xwud
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app appres
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app beforelight
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app bitmap
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app editres
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app fonttosfnt
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app fslsfonts
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app fstobdf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app ico
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app listres
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app mkcomposecache
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app oclock
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app rendercheck
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app rgb
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app showfont
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app transset
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app viewres
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xbiff
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xcalc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xclipboard
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xclock
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xcm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xcompmgr
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xconsole
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xdbedizzy
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xditview
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xdm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xedit
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xeyes
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xf86dga
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xfd
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xfontsel
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xfs
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xfsinfo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xgc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xkbprint
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xload
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xlogo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xlsfonts
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xmag
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xman
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xmh
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xmore
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xscope
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xsm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xstdcmap
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xvidtune
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_font () {
#*************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild data xcursor-themes
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-adobe-100dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-adobe-75dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-adobe-utopia-100dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-adobe-utopia-75dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-adobe-utopia-type1
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-alias
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-arabic-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bh-100dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bh-75dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bh-lucidatypewriter-100dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bh-lucidatypewriter-75dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bh-ttf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bh-type1
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bitstream-100dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bitstream-75dpi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bitstream-speedo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-bitstream-type1
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-cronyx-cyrillic
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-cursor-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-daewoo-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-dec-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-ibm-type1
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-isas-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-jis-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-micro-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-misc-cyrillic
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-misc-ethiopic
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-misc-meltho
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-misc-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-mutt-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-schumacher-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-screen-cyrillic
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-sony-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-sun-misc
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-winitzki-cyrillic
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font font-xfree86-type1
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild data xkeyboard-config
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_server () {
#**************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild xserver xorg-server
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}


build_x11_driver () {
#**********************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild driver xf86-input-acecad
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-aiptek
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-evdev
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-joystick
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-keyboard
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-mouse
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-penmount
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-synaptics
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-vmmouse
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-void
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-wacom
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-amdgpu
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-apm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-ark
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-ast
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-ati
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-chips
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-cirrus
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-dummy
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-glint
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-i128
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-i740
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-intel
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-mach64
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-mga
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver  xf86-video-modesetting
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-neomagic
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver  xf86-video-nouveau
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-nv
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-omap
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-openchrome
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-r128
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-rendition
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-s3
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-s3virge
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-savage
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-siliconmotion
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-sis
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-sisusb
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-tdfx
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-tga
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-trident
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-tseng
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-v4l
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-vesa
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver  xf86-video-vmware
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-voodoo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-xgi
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-xgixp
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_x11_app_post () {
#****************************************************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild font encodings
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app compiz
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app luit
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app igt-gpu-tools
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app twm
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild app xinit
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-input-libinput
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-geode
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild driver xf86-video-vboxvideo
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
}

build_kdelibs () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdelibs
[ $? != 0 ] && touch /tmp/kde_build/kdelibs.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdebase () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild  kdebase:nepomuk-core
[ $? != 0 ] && touch /tmp/kde_build/nepomuk-core.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:nepomuk-widgets
[ $? != 0 ] && touch /tmp/kde_build/nepomuk-widgets.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdepimlibs
[ $? != 0 ] && touch /tmp/kde_build/kdepimlibs.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kfilemetadata
[ $? != 0 ] && touch /tmp/kde_build/kfilemetadata.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kde-baseapps
[ $? != 0 ] && touch /tmp/kde_build/kde-baseapps.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kactivities
[ $? != 0 ] && touch /tmp/kde_build/kactivities.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:konsole
[ $? != 0 ] && touch /tmp/kde_build/konsole.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kde-wallpapers
[ $? != 0 ] && touch /tmp/kde_build/kde-wallpapers.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kde-workspace
[ $? != 0 ] && touch /tmp/kde_build/kde-workspace.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kde-runtime
[ $? != 0 ] && touch /tmp/kde_build/kde-runtime.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kde-base-artwork
[ $? != 0 ] && touch /tmp/kde_build/kde-base-artwork.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdesdk () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdesdk:cervisia
[ $? != 0 ] && touch /tmp/kde_build/cervisia.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:dolphin-plugins
[ $? != 0 ] && touch /tmp/kde_build/dolphin-plugins.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kapptemplate
[ $? != 0 ] && touch /tmp/kde_build/kapptemplate.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kcachegrind
[ $? != 0 ] && touch /tmp/kde_build/kcachegrind.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kde-dev-scripts
[ $? != 0 ] && touch /tmp/kde_build/kde-dev-scripts.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kde-dev-utils
[ $? != 0 ] && touch /tmp/kde_build/kde-dev-utils.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kdesdk-kioslaves
[ $? != 0 ] && touch /tmp/kde_build/kdesdk-kioslaves.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kdesdk-strigi-analyzers
[ $? != 0 ] && touch /tmp/kde_build/kdesdk-strigi-analyzers.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kdesdk-thumbnailers
[ $? != 0 ] && touch /tmp/kde_build/kdesdk-thumbnailers.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:libkomparediff2
[ $? != 0 ] && touch /tmp/kde_build/libkomparediff2.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:kompare
[ $? != 0 ] && touch /tmp/kde_build/kompare.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:lokalize
[ $? != 0 ] && touch /tmp/kde_build/lokalize.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:okteta
[ $? != 0 ] && touch /tmp/kde_build/okteta.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:poxml
[ $? != 0 ] && touch /tmp/kde_build/poxml.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdesdk:umbrello
[ $? != 0 ] && touch /tmp/kde_build/umbrello.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdegraphics () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild extragear:libkscreen
[ $? != 0 ] && touch /tmp/kde_build/libkscreen.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:libkipi
[ $? != 0 ] && touch /tmp/kde_build/libkipi.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:libkexiv2
[ $? != 0 ] && touch /tmp/kde_build/libkexiv2.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:libkdcraw
[ $? != 0 ] && touch /tmp/kde_build/libkdcraw.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:libksane
[ $? != 0 ] && touch /tmp/kde_build/libksane.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kdegraphics-mobipocket
[ $? != 0 ] && touch /tmp/kde_build/kdegraphics-mobipocket.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:okular
[ $? != 0 ] && touch /tmp/kde_build/okular.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kdegraphics-strigi-analyzer
[ $? != 0 ] && touch /tmp/kde_build/kdegraphics-strigi-analyzer.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kdegraphics-thumbnailers
[ $? != 0 ] && touch /tmp/kde_build/kdegraphics-thumbnailers.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kamera
[ $? != 0 ] && touch /tmp/kde_build/kamera.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kcolorchooser
[ $? != 0 ] && touch /tmp/kde_build/kcolorchooser.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kgamma
[ $? != 0 ] && touch /tmp/kde_build/kgamma.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kolourpaint
[ $? != 0 ] && touch /tmp/kde_build/kolourpaint.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:kruler
[ $? != 0 ] && touch /tmp/kde_build/kruler.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:ksaneplugin
[ $? != 0 ] && touch /tmp/kde_build/ksaneplugin.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:ksnapshot
[ $? != 0 ] && touch /tmp/kde_build/ksnapshot.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegraphics:svgpart
[ $? != 0 ] && touch /tmp/kde_build/svgpart.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdebindings () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdebindings:smokegen 
[ $? != 0 ] && touch /tmp/kde_build/smokegen.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:smokeqt
[ $? != 0 ] && touch /tmp/kde_build/smokeqt.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:qtruby  
[ $? != 0 ] && touch /tmp/kde_build/qtruby.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:perlqt 
[ $? != 0 ] && touch /tmp/kde_build/perlqt.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:smokekde 
[ $? != 0 ] && touch /tmp/kde_build/smokekde.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:korundum
[ $? != 0 ] && touch /tmp/kde_build/korundum.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:perlkde 
[ $? != 0 ] && touch /tmp/kde_build/perlkde.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:pykde4 
[ $? != 0 ] && touch /tmp/kde_build/pykde4.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:kate 
[ $? != 0 ] && touch /tmp/kde_build/kate.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebindings:kross-interpreters 
[ $? != 0 ] && touch /tmp/kde_build/kross-interpreters.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdeaccessibility () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdeaccessibility:kaccessible 
[ $? != 0 ] && touch /tmp/kde_build/kaccessible.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeaccessibility:kmouth 
[ $? != 0 ] && touch /tmp/kde_build/kmouth.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeaccessibility:kmousetool 
[ $? != 0 ] && touch /tmp/kde_build/kmousetool.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeaccessibility:kmag 
[ $? != 0 ] && touch /tmp/kde_build/kmag.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdeutils () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdeutils:ark 
[ $? != 0 ] && touch /tmp/kde_build/ark.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:filelight  
[ $? != 0 ] && touch /tmp/kde_build/filelight.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kcalc 
[ $? != 0 ] && touch /tmp/kde_build/kcalc.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kcharselect  
[ $? != 0 ] && touch /tmp/kde_build/kcharselect.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kdf  
[ $? != 0 ] && touch /tmp/kde_build/kdf.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kfloppy  
[ $? != 0 ] && touch /tmp/kde_build/kfloppy.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kgpg  
[ $? != 0 ] && touch /tmp/kde_build/kgpg.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:print-manager  
[ $? != 0 ] && touch /tmp/kde_build/print-manager.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kremotecontrol  
[ $? != 0 ] && touch /tmp/kde_build/kremotecontrol.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:ktimer  
[ $? != 0 ] && touch /tmp/kde_build/ktimer.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:kwalletmanager  
[ $? != 0 ] && touch /tmp/kde_build/kwalletmanager.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:superkaramba  
[ $? != 0 ] && touch /tmp/kde_build/superkaramba.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeutils:sweeper  
[ $? != 0 ] && touch /tmp/kde_build/sweeper.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdemultimedia () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdemultimedia:libkcddb
[ $? != 0 ] && touch /tmp/kde_build/libkcddb.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdemultimedia:libkcompactdisc  
[ $? != 0 ] && touch /tmp/kde_build/libkcompactdisc.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdemultimedia:audiocd-kio
[ $? != 0 ] && touch /tmp/kde_build/audiocd-kio.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdemultimedia:dragon
[ $? != 0 ] && touch /tmp/kde_build/dragon.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdemultimedia:mplayerthumbs  
[ $? != 0 ] && touch /tmp/kde_build/mplayerthumbs.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdemultimedia:juk 
[ $? != 0 ] && touch /tmp/kde_build/juk.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdemultimedia:kmix
[ $? != 0 ] && touch /tmp/kde_build/kmix.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdenetwork () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild extragear:libktorrent
[ $? != 0 ] && touch /tmp/kde_build/libktorrent.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:kdenetwork-filesharing
[ $? != 0 ] && touch /tmp/kde_build/kdenetwork-filesharing.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:kdenetwork-strigi-analyzers
[ $? != 0 ] && touch /tmp/kde_build/kdenetwork-strigi-analyzers.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:zeroconf-ioslave
[ $? != 0 ] && touch /tmp/kde_build/zeroconf-ioslave.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:kget
[ $? != 0 ] && touch /tmp/kde_build/kget.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:kopete
[ $? != 0 ] && touch /tmp/kde_build/kopete.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:kppp
[ $? != 0 ] && touch /tmp/kde_build/kppp.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:krdc
[ $? != 0 ] && touch /tmp/kde_build/krdc.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdenetwork:krfb
[ $? != 0 ] && touch /tmp/kde_build/krfb.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdeadmin () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild oxygen-icons
[ $? != 0 ] && touch /tmp/kde_build/oxygen-icons.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeadmin:kcron
[ $? != 0 ] && touch /tmp/kde_build/kcron.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeadmin:ksystemlog
[ $? != 0 ] && touch /tmp/kde_build/ksystemlog.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeadmin:kuser
[ $? != 0 ] && touch /tmp/kde_build/kuser.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdegames () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdeartwork
[ $? != 0 ] && touch /tmp/kde_build/kdeartwork.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:libkdegames
[ $? != 0 ] && touch /tmp/kde_build/libkdegames.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:libkmahjongg
[ $? != 0 ] && touch /tmp/kde_build/libkmahjongg.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:klickety
[ $? != 0 ] && touch /tmp/kde_build/klickety.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:ksudoku
[ $? != 0 ] && touch /tmp/kde_build/ksudoku.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:ksquares
[ $? != 0 ] && touch /tmp/kde_build/ksquares.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kpat
[ $? != 0 ] && touch /tmp/kde_build/kpat.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:klines
[ $? != 0 ] && touch /tmp/kde_build/klines.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:ksnakeduel
[ $? != 0 ] && touch /tmp/kde_build/ksnakeduel.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kollision
[ $? != 0 ] && touch /tmp/kde_build/kollision.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kshisen
[ $? != 0 ] && touch /tmp/kde_build/kshisen.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kblocks
[ $? != 0 ] && touch /tmp/kde_build/kblocks.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:lskat
[ $? != 0 ] && touch /tmp/kde_build/lskat.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kreversi
[ $? != 0 ] && touch /tmp/kde_build/kreversi.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:bovo
[ $? != 0 ] && touch /tmp/kde_build/bovo.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kajongg
[ $? != 0 ] && touch /tmp/kde_build/kajongg.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:granatier
[ $? != 0 ] && touch /tmp/kde_build/granatier.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kmines
[ $? != 0 ] && touch /tmp/kde_build/kmines.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kiriki
[ $? != 0 ] && touch /tmp/kde_build/kiriki.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kigo
[ $? != 0 ] && touch /tmp/kde_build/kigo.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:bomber
[ $? != 0 ] && touch /tmp/kde_build/bomber.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kolf
[ $? != 0 ] && touch /tmp/kde_build/kolf.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kdiamond
[ $? != 0 ] && touch /tmp/kde_build/kdiamond.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kbounce
[ $? != 0 ] && touch /tmp/kde_build/kbounce.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:konquest
[ $? != 0 ] && touch /tmp/kde_build/konquest.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kapman
[ $? != 0 ] && touch /tmp/kde_build/kapman.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:knavalbattle
[ $? != 0 ] && touch /tmp/kde_build/knavalbattle.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde
./kde.SlackBuild kdegames:killbots
[ $? != 0 ] && touch /tmp/kde_build/killbots.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kubrick
[ $? != 0 ] && touch /tmp/kde_build/kubrick.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kgoldrunner
[ $? != 0 ] && touch /tmp/kde_build/kgoldrunner.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:knetwalk
[ $? != 0 ] && touch /tmp/kde_build/knetwalk.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kbreakout
[ $? != 0 ] && touch /tmp/kde_build/kbreakout.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:ksirk
[ $? != 0 ] && touch /tmp/kde_build/ksirk.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kfourinline
[ $? != 0 ] && touch /tmp/kde_build/kfourinline.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:picmi
[ $? != 0 ] && touch /tmp/kde_build/picmi.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kblackbox
[ $? != 0 ] && touch /tmp/kde_build/kblackbox.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:palapeli
[ $? != 0 ] && touch /tmp/kde_build/kdevelop-php.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:katomic
[ $? != 0 ] && touch /tmp/kde_build/katomic.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:ktuberling
[ $? != 0 ] && touch /tmp/kde_build/ktuberling.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kjumpingcube
[ $? != 0 ] && touch /tmp/kde_build/kjumpingcube.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kmahjongg
[ $? != 0 ] && touch /tmp/kde_build/kmahjongg.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdegames:kspaceduel
[ $? != 0 ] && touch /tmp/kde_build/kspaceduel.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdetoys () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdetoys:amor
[ $? != 0 ] && touch /tmp/kde_build/amor.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdetoys:kteatime
[ $? != 0 ] && touch /tmp/kde_build/kteatime.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdetoys:ktux
[ $? != 0 ] && touch /tmp/kde_build/ktux.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdepim () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdepim
[ $? != 0 ] && touch /tmp/kde_build/kdepim.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdepim-runtime
[ $? != 0 ] && touch /tmp/kde_build/kdepim-runtime.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdeedu () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdeedu:libkdeedu
[ $? != 0 ] && touch /tmp/kde_build/libkdeedu.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:analitza
[ $? != 0 ] && touch /tmp/kde_build/analitza.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:artikulate
[ $? != 0 ] && touch /tmp/kde_build/artikulate.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:blinken
[ $? != 0 ] && touch /tmp/kde_build/blinken.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:cantor
[ $? != 0 ] && touch /tmp/kde_build/cantor.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kalgebra
[ $? != 0 ] && touch /tmp/kde_build/kalgebra.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kalzium
[ $? != 0 ] && touch /tmp/kde_build/kalzium.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kanagram
[ $? != 0 ] && touch /tmp/kde_build/kanagram.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kbruch
[ $? != 0 ] && touch /tmp/kde_build/kbruch.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kgeography
[ $? != 0 ] && touch /tmp/kde_build/kgeography.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:khangman
[ $? != 0 ] && touch /tmp/kde_build/khangman.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kig
[ $? != 0 ] && touch /tmp/kde_build/kig.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kiten
[ $? != 0 ] && touch /tmp/kde_build/kiten.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:klettres
[ $? != 0 ] && touch /tmp/kde_build/klettres.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kmplot
[ $? != 0 ] && touch /tmp/kde_build/kmplot.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kstars
[ $? != 0 ] && touch /tmp/kde_build/kstars.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kqtquickcharts
[ $? != 0 ] && touch /tmp/kde_build/kqtquickcharts.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:ktouch
[ $? != 0 ] && touch /tmp/kde_build/ktouch.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kturtle
[ $? != 0 ] && touch /tmp/kde_build/kturtle.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:kwordquiz
[ $? != 0 ] && touch /tmp/kde_build/kwordquiz.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:marble
[ $? != 0 ] && touch /tmp/kde_build/marble.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:parley
[ $? != 0 ] && touch /tmp/kde_build/parley.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:pairs
[ $? != 0 ] && touch /tmp/kde_build/pairs.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:rocs
[ $? != 0 ] && touch /tmp/kde_build/rocs.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeedu:step
[ $? != 0 ] && touch /tmp/kde_build/step.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdeextragear () {
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild kdewebdev
[ $? != 0 ] && touch /tmp/kde_build/kdewebdev.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdebase:kde-baseapps
[ $? != 0 ] && touch /tmp/kde_build/kde-baseapps.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild kdeplasma-addons
[ $? != 0 ] && touch /tmp/kde_build/kdeplasma-addons.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild polkit-kde:polkit-kde-agent-1
[ $? != 0 ] && touch /tmp/kde_build/polkit-kde-agent-1.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild polkit-kde:polkit-kde-kcmodules-1
[ $? != 0 ] && touch /tmp/kde_build/polkit-kde-kcmodules-1.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:bluedevil
[ $? != 0 ] && touch /tmp/kde_build/bluedevil.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kaudiocreator
[ $? != 0 ] && touch /tmp/kde_build/kaudiocreator.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kplayer
[ $? != 0 ] && touch /tmp/kde_build/kplayer.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kwebkitpart
[ $? != 0 ] && touch /tmp/kde_build/kwebkitpart.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:oxygen-gtk2
[ $? != 0 ] && touch /tmp/kde_build/oxygen-gtk2.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdevplatform
[ $? != 0 ] && touch /tmp/kde_build/kdevplatform.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdevelop-pg-qt
[ $? != 0 ] && touch /tmp/kde_build/kdevelop-pg-qt.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdevelop
[ $? != 0 ] && touch /tmp/kde_build/kdevelop.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdev-python
[ $? != 0 ] && touch /tmp/kde_build/kdev-python.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdevelop-php
[ $? != 0 ] && touch /tmp/kde_build/kdevelop-php.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdevelop-php-docs
[ $? != 0 ] && touch /tmp/kde_build/kdevelop-php-docs.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:wicd-kde
[ $? != 0 ] && touch /tmp/kde_build/wicd-kde.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:libmm-qt
[ $? != 0 ] && touch /tmp/kde_build/libmm-qt.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:libnm-qt
[ $? != 0 ] && touch /tmp/kde_build/libnm-qt.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:plasma-nm
[ $? != 0 ] && touch /tmp/kde_build/plasma-nm.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:skanlite
[ $? != 0 ] && touch /tmp/kde_build/skanlite.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kio-mtp
[ $? != 0 ] && touch /tmp/kde_build/kio-mtp.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:libktorrent
[ $? != 0 ] && touch /tmp/kde_build/libktorrent.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:ktorrent
[ $? != 0 ] && touch /tmp/kde_build/ktorrent.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:amarok
[ $? != 0 ] && touch /tmp/kde_build/amarok.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:calligra
[ $? != 0 ] && touch /tmp/kde_build/calligra.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:libkscreen
[ $? != 0 ] && touch /tmp/kde_build/libkscreen.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kscreen
[ $? != 0 ] && touch /tmp/kde_build/kscreen.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:kdeconnect-kde
[ $? != 0 ] && touch /tmp/kde_build/kdeconnect-kde.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:partitionmanager
[ $? != 0 ] && touch /tmp/kde_build/partitionmanager.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild extragear:k3b
[ $? != 0 ] && touch /tmp/kde_build/k3b.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}

build_kdei () {
#****************************************************************
cd /slacksrc/kdei/kde-l10n

export UPGRADE_PACKAGES=always

PKGLANG=ar ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ar.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=bg ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-bg.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=bs ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-bs.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ca ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ca.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ca@valencia ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ca@valencia.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=cs ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-cs.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=da ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-da.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=de ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-de.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=el ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-el.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=en_GB ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-en_GB.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=es ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-es.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=et ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-et.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=eu ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-eu.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=fa ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-fa.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=fi ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-fi.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=fr ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-fr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ga ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ga.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=gl ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-gl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=he ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-he.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=hi ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-hi.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=hr ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-hr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=hu ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-hu.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ia ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ia.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=id ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-id.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=is ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-is.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=it ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-it.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ja ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ja.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=kk ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-kk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=km ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-km.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ko ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ko.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=lt ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-lt.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=lv ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-lv.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=mr ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-mr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=nb ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-nb.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=nds ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-nds.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=nl ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-nl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=nn ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-nn.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=pa ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-pa.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=pl ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-pl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=pt ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-pt.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=pt_BR ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-pt_BR.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ro ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ro.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ru ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ru.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=sk ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-sk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=sl ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-sl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=sr ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-sr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=sv ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-sv.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=tr ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-tr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=ug ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-ug.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=uk ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-uk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=wa ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-wa.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=zh_CN ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-zh_CN.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
cd /slacksrc/kdei/kde-l10n

PKGLANG=zh_TW ./kde-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/kdei-l10n-zh_TW.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei/
rm -rf /tmp/kde_build
cd /sources

}

build_calligra () {
#****************************************************************
cd /slacksrc/kdei/calligra-l10n

export UPGRADE_PACKAGES=always

PKGLANG=bs ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-bs.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=ca ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-ca.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=ca@valencia ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-ca@valencia.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=cs ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-cs.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=da ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-da.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=de ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-de.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=el ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-el.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=en_GB ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-en_GB.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=es ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-es.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=et ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-et.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=fi ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-fi.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=fr ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-fr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=gl ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-gl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=hu ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-hu.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=it ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-fi.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=ja ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-ja.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=kk ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-kk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=nb ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-nb.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=nl ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-nl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=pl ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-pl.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
cd /slacksrc/kdei/calligra-l10n

PKGLANG=pt ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-pt.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=pt_BR ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-pt_BR.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=ru ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-sk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=sk ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-sk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=sv ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-sv.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=tr ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-tr.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=uk ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-uk.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=zh_CN ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-zh_CN.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
cd /slacksrc/kdei/calligra-l10n

PKGLANG=zh_TW ./calligra-l10n.SlackBuild
[ $? != 0 ] && touch /tmp/kde_build/calligra-l10n-TW_CN.failed
cd /tmp/kde_build
upgradepkg --install-new --reinstall *.txz
mv *.txz /sfspacks/kdei
rm -rf /tmp/kde_build
cd /sources

}

build_post_kde2 () {
#****************************************************************
# this part exist because some kde packages don't build directly
#****************************************************************
cd /slacksrc/kde

export UPGRADE_PACKAGES=always

./kde.SlackBuild  kdebase:baloo
[ $? != 0 ] && touch /tmp/kde_build/baloo.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild  kdebase:baloo-widgets
[ $? != 0 ] && touch /tmp/kde_build/baloo-widgets.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

./kde.SlackBuild  kdegraphics:gwenview
[ $? != 0 ] && touch /tmp/kde_build/gwenview.failed
cd /tmp/kde_build
mv *.txz /sfspacks/kde
cd /slacksrc/kde

}


message_end1 () {
#****************************************************************
echo
echo "sfsbuild1.sh has finished to build the first part of SFS."
echo "You now have a bare slackware system able to boot."
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
cd /sources && pkill dhcpcd
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
cd /sources && pkill dhcpcd
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
cd /sources && pkill dhcpcd
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
cd /sources && pkill dhcpcd
}

#****************************************************************
# END OF X11 SUB-SYSTEM BUILDING
#****************************************************************





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

# init libusb variable
LUSB=1
# init pkg-config variable
LPKG=1
# init libcap variable
LCAP=1
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

				alsa-lib )
					case $LISTFILE in
						build2_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_s.list )
							rm /sfspacks/l/alsa-lib*.t?z
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				ca-certificates )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					update-ca-certificates ;;

				cmake )
					case $LISTFILE in
						build1_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build4_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				dbus )
					case $LISTFILE in
						build2_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							dbus-uuidgen --ensure ;;

						build3_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				dhcpcd_up )
					dhcpcd -t 10 eth0 && echo
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
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LFIN=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				fontconfig )
					case $LISTFILE in
						build2_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				freetype )
					case $LFRE in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LFRE=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				gd )
					case $LGD in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LGD=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				glib-networking )
					update-ca-certificates
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				gucharmap )
					update-ca-certificates --fresh
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				harfbuzz )
					case $LHAR in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LHAR=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
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

				java )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				kdelibs )
					build_kdelibs
					[ $? != 0 ] && exit 1 ;;

				kdebase )
					build_kdebase
					[ $? != 0 ] && exit 1 ;;

				kdesdk )
					build_kdesdk
					[ $? != 0 ] && exit 1 ;;

				kdegraphics )
					build_kdegraphics
					[ $? != 0 ] && exit 1 ;;

				kdebindings )
					build_kdebindings
					[ $? != 0 ] && exit 1 ;;

				kdemultimedia )
					build_kdemultimedia
					[ $? != 0 ] && exit 1 ;;

				kdeaccessibility )
					build_kdeaccessibility
					[ $? != 0 ] && exit 1 ;;

				kdeutils )
					build_kdeutils
					[ $? != 0 ] && exit 1 ;;

				kdenetwork )
					build_kdenetwork
					[ $? != 0 ] && exit 1 ;;

				kdeadmin )
					build_kdeadmin
					[ $? != 0 ] && exit 1 ;;

				kdegames )
					build_kdegames
					[ $? != 0 ] && exit 1 ;;

				kdetoys )
					build_kdetoys
					[ $? != 0 ] && exit 1 ;;

				kdepim )
					build_kdepim
					[ $? != 0 ] && exit 1 ;;

				kdeedu )
					build_kdeedu
					[ $? != 0 ] && exit 1 ;;

				extragear )
					build_kdeextragear
					[ $? != 0 ] && exit 1 ;;

				kde-l10n )
					build_kdei
					[ $? != 0 ] && exit 1 ;;

				calligra-l10n )
					build_calligra
					[ $? != 0 ] && exit 1 ;;

				post-kde2 )
					build_post_kde2
					[ $? != 0 ] && exit 1 ;;

				kernel-all )
					kernel_build_all
					[ $? != 0 ] && exit 1 ;;

				kernel-headers )
					kernel_headers_build_c
					[ $? != 0 ] && exit 1 ;;

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
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LCAC=2 ;;
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

				libusb )
					case $LUSB in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LUSB=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
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
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LPVM=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				mesa )
					case $LMES in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LMES=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
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
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LPKG=2 ;;
						2 )
							build1 $SRCDIR $PACKNAME
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

				pre-gcc )
					pre_gcc
					[ $? != 0 ] && exit 1 ;;

				post-gcc )
					post_gcc
					[ $? != 0 ] && exit 1 ;;

				QScintilla )
					case $LQSC in
						1 )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LQSC=2 ;;
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

				subversion )
					case $LISTFILE in
						build3_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build4_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				texlive )
					case $LISTFILE in
						build2_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				utempter )
					touch /var/run/utmp
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				virtuoso-ose )
					case $ARCH in
						x86_64 )
							# remove temporaly openssl-1.1.x to enable building
							removepkg openssl-1.1.0i-x86_64-2 openssl-solibs-1.1.0i-x86_64-2
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
						* )
							# remove temporaly openssl-1.1.x to enable building
							removepkg openssl-1.1.0i-i586-2 openssl-solibs-1.1.0i-i586-2
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

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

				vim )
					case $LISTFILE in
						build1_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build4_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

					esac
					continue ;;

				x11-doc )
					build_x11_doc
					[ $? != 0 ] && exit 1 ;;

				x11-proto )
					build_x11_proto_c
					[ $? != 0 ] && exit 1 ;;

				x11-util )
					build_x11_util
					[ $? != 0 ] && exit 1 ;;

				x11-lib )
					build_x11_lib
					[ $? != 0 ] && exit 1 ;;

				x11-xcb )
					build_x11_xcb
					[ $? != 0 ] && exit 1 ;;

				x11-app )
					build_x11_app
					[ $? != 0 ] && exit 1 ;;

				x11-font )
					build_x11_font
					[ $? != 0 ] && exit 1 ;;

				x11-server )
					build_x11_server
					[ $? != 0 ] && exit 1 ;;

				x11-driver )
					build_x11_driver
					[ $? != 0 ] && exit 1 ;;

				x11-app-post )
					build_x11_app_post
					[ $? != 0 ] && exit 1 ;;
	
				* )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

			esac
done

echo
