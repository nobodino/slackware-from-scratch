
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
#	Above july 2018, revisions made through github project: https://github.com/nobodino/slackware-from-scratch 
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

kernel_source_build_c () {
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

	mozjs52 )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozjs52.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozilla-thunderbird )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-thunderbird.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	seamonkey )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./seamonkey.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	snownews )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && gzip -d *.diff.gz && sed -i 's/root//' *.diff && gzip -9 *.diff && ./$PACKNAME.SlackBuild
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
  libXfontenc \
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
  libXfont \
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
  mkfontdir \
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
  xf86-input-aiptek \
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
  xf86-video-modesetting \
  xf86-video-neomagic\
  xf86-video-nouveau \
  xf86-video-nv \
  xf86-video-omap \
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
  xf86-video-xgi \
  xf86-video-xgixp \
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

				libsoup )
					source /root/.bashrc
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

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
	
				* )
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

			esac
done

echo
