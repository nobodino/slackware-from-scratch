###############################  sfsbuild1.sh #############################
#!/bin/bash
###########################################################################
# set -x

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

kernel_build () {
#***********************************************************
# build kernel and modules before packaging with SlackBuild
#***********************************************************
cd /slacksrc/k
PKGNAM=linux
VERSION=${VERSION:-$(echo $PKGNAM-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
BUILD=${BUILD:-1}
CWD=$(pwd)
NUMJOBS=${NUMJOBS:-" -j7 "}
cd /usr/src
tar xf $CWD/$PKGNAM-$VERSION.tar.xz
cd /usr/src/$PKGNAM-$VERSION
make mrproper && make distclean

case $(uname -m) in
	x86_64 )
		cp $CWD/config-x86_64/config-huge-$VERSION.x64 .config ;;
	*  )
		cp $CWD/config-x86/config-huge-smp-$VERSION-smp .config ;;
esac

make oldconfig
make $NUMJOBS bzImage || exit 1
make $NUMJOBS modules || exit 1
make $NUMJOBS modules_install || exit 1
#***********************************************************
# packaging the kernel
#***********************************************************

case $(uname -m) in
	x86_64 )
		cd /slacksrc/k/packaging-x86_64/kernel-huge
		./kernel-huge.SlackBuild
		[ $? != 0 ] && exit 1 ;;
	* )
		cd /slacksrc/k/packaging-x86/kernel-huge-smp
		./kernel-huge-smp.SlackBuild
		[ $? != 0 ] && exit 1 ;;
esac

#***********************************************************
# packaging the modules
#***********************************************************

case $(uname -m) in
	x86_64 )
		cd /slacksrc/k/packaging-x86_64/kernel-modules
		./kernel-modules.SlackBuild
		[ $? != 0 ] && exit 1 ;;
	* )
		cd /slacksrc/k/packaging-x86/kernel-modules-smp
		./kernel-modules-smp.SlackBuild
		[ $? != 0 ] && exit 1 ;;
esac

#***********************************************************
# installing the kernel and modules
#***********************************************************
upgradepkg --install-new --reinstall /tmp/kernel-*.t?z
mv -v /tmp/kernel*.t?z /sfspacks/a
}

kernel_headers_build () {
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
cat $CWD/slack-desc > $PKG/install/slack-desc
cd /tmp/kernel-headers
VERSION1=${VERSION1:-$(echo /slacksrc/k/$PKGNAM-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)_smp}
makepkg -l y -c n /tmp/kernel-headers-$VERSION1-x86-$BUILD.txz
upgradepkg --install-new /tmp/kernel-headers-$VERSION1-x86-$BUILD.t?z
mv -v /tmp/kernel-headers-$VERSION1-x86-$BUILD.txz /sfspacks/d
rm -rf /tmp/kernel-headers/
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
	gcc )
		# Build only c, c++, and fortran
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild c,c++,fortan
		[ $? != 0 ] && exit 1 ;;

	gettext-tools )
		# two packages in gettext: gettext and gettext-tools
		DIRNAME=gettext
		cd /slacksrc/$SRCDIR/$DIRNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	libcaca )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && ./libcaca.SlackBuild
		[ $? != 0 ] && exit 1
		export LCAC=2 ;;

	libtheora )
		case $(name -m) in
			x86_64 )
			   installpkg /slacksrc/others/libpng-1.4.12-x86_64-1.txz
			   cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
				$INSTALLPRG /tmp/$PACKNAME*.t?z && mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
			   removepkg libpng-1.4.12-x86_64-1 && installpkg /sfspacks/l/libpng-1.6.2*-x86_64*.txz
			   [ $? !=0 ] && exit 1 ;;
			* )
			   installpkg /slacksrc/others/libpng-1.4.12-i486-1.txz
			   cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
				$INSTALLPRG /tmp/$PACKNAME*.t?z && mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
			   removepkg libpng-1.4.12-i486-1 && installpkg /sfspacks/l/libpng-1.6.2*-i586-1.txz
			   [ $? !=0 ] && exit 1 ;;
		esac
		continue ;;

	mozilla-firefox )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-firefox.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	mozilla-thunderbird )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./mozilla-thunderbird.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	seamonkey )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && SHELL=/bin/sh ./seamonkey.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	wireless-tools )
		cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x *.SlackBuild && ./wireless_tools.SlackBuild
		[ $? != 0 ] && exit 1 ;;

	xpaint )
		case $(name -m) in
			x86_64 )
			   installpkg /slacksrc/others/libpng-1.4.12-x86_64-1.txz
			   cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
				$INSTALLPRG /tmp/$PACKNAME*.t?z && mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
			   removepkg libpng-1.4.12-x86_64-1 && installpkg /sfspacks/l/libpng-1.6.2*-x86_64*.txz
			   [ $? !=0 ] && exit 1 ;;
			* )
			   installpkg /slacksrc/others/libpng-1.4.12-i486-1.txz
			   cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
				$INSTALLPRG /tmp/$PACKNAME*.t?z && mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
			   removepkg libpng-1.4.12-i486-1 && installpkg /sfspacks/l/libpng-1.6.2*-i586-1.txz
			   [ $? !=0 ] && exit 1 ;;
		esac
		continue ;;

	xpdf )
		case $(name -m) in
			x86_64 )
			   installpkg /slacksrc/others/libpng-1.4.12-x86_64-1.txz
			   cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
				$INSTALLPRG /tmp/$PACKNAME*.t?z && mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
			   removepkg libpng-1.4.12-x86_64-1 && installpkg /sfspacks/l/libpng-1.6.2*-x86_64*.txz
			   [ $? !=0 ] && exit 1 ;;
			* )
			   installpkg /slacksrc/others/libpng-1.4.12-i486-1.txz
			   cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
				$INSTALLPRG /tmp/$PACKNAME*.t?z && mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
			   removepkg libpng-1.4.12-i486-1 && installpkg /sfspacks/l/libpng-1.6.2*-i586-1.txz
			   [ $? !=0 ] && exit 1 ;;
		esac
		continue ;;


	xfce )
		cd /slacksrc/$SRCDIR && chmod +x xfce-build-all.sh && ./xfce-build-all.sh
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

	bind )
		# bind is not built in /tmp but in /bind*
		$INSTALLPRG /bind*/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	etc )
		# remove mini /etc/group and etc/passwd
		rm /etc/group && rm /etc/passwd
		cd /tmp
		$INSTALLPRG /tmp/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	gcc )
		# gcc is not built in /tmp but in /gcc*
		$INSTALLPRG /gcc*/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	glibc )
		# glibc is not built in /tmp but in /glibc*
		$INSTALLPRG /glibc*/$PACKNAME*.t?z
		[ $? != 0 ] && exit 1 ;;

	xfce )
		continue ;;

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
		mv /tmp/imapd*.txz /sfspacks/$SRCDIR
		mv /tmp/alpine*.txz /sfspacks/$SRCDIR
		cd /sources ;;

	bind )
		cd /bind*
		mv bind*.t?z /sfspacks/$SRCDIR
		rm -rf /bind*
		cd /sources ;;

	gcc )
		cd /gcc*
		mv gcc*.t?z /sfspacks/$SRCDIR
		rm -rf /gcc*
		cd /sources ;;

	gettext-tools )
		# don't forget to mv gettext-tools in d/
		cd /tmp
		mv /tmp/$PACKNAME*.t?z /sfspacks/d/
		cd /sources ;;

	glibc )
		cd /glibc*
		mv glibc*.t?z /sfspacks/$SRCDIR
		rm -rf /glibc*
		cd /sources ;;

	openssl )
		# don't forget to mv opennsl-solibs in a/
		cd /tmp
		mv /tmp/$PACKNAME-solibs*.t?z /sfspacks/a/
		mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR
		cd /sources ;;

	xz )
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

cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild.old

cd /tmp
$INSTALLPRG /tmp/$PACKNAME*.t?z
[ $? != 0 ] && exit 1
#******************************************************************
# remove the temporary package *_sfs and replace it with a normal one
#******************************************************************
rm /sfspacks/$SRCDIR/$PACKNAME*_sfs.txz
mv -v /tmp/$PACKNAME*.t?z /sfspacks/$SRCDIR

cd /tmp
#******************************************************************
# Note that the following removes any SBo directory.
#******************************************************************
for i in *; do
    [ -d "$i" ] && rm -rf $i
done
cd /sources
}

build_s () {
#*******************************************************************
# build procedure for dlackware package
#*******************************************************************
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

#**************************
# BUILD package treatment
#**************************
cd /slacksrc/$SRCDIR/$PACKNAME && chmod +x $PACKNAME.SlackBuild && ./$PACKNAME.SlackBuild
[ $? != 0 ] && exit 1

#**************************
# INSTALL package treatment
#**************************
cd /var/cache/dlackware
$INSTALLPRG /var/cache/dlackware/$PACKNAME*.t?z
[ $? != 0 ] && exit 1
#******************************************************************
# MOVE package treatment in dlackware
#******************************************************************
mv -v /var/cache/dlackware/$PACKNAME*.t?z /sfspacks/$SRCDIR

cd /tmp
#******************************************************************
# Note that the following removes any SBo directory.
#******************************************************************
for i in *; do
    [ -d "$i" ] && rm -rf $i
done
cd /sources
}

clean_tmp () {
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

dlackware_path () {
#*****************************
mkdir -pv /sfspacks/dlackware
}

echo_message_slackware () {
#****************************************************************
echo "-------------------------------------------"
echo
echo "By now, you are ready to build Slackware From Scratch."
echo "and wait a long time, a few hours."
echo
echo "You can do it by hand, by building packwage, one by one."
echo "./package.SlackBuild && installpkg /tmp/package*.t?z"
echo
echo "You can also do it with only one script, for ordinary slackware"
echo 
echo "time (./sfsbuild1.sh build1_s.list)"
echo
echo "You may want a bare slackware system. In that case,"
echo "if you choose it, you will have a self sufficient system,"
echo "able to build without the 'tools', but no internet."
echo
echo "time (./sfsbuild1.sh build0_s.list)"
echo
echo "After that, you can recover the normal path to build"
echo "Slackware from scratch by executing the following:"
echo
echo "time (./sfsbuild1.sh build1_s0.list)"
echo
}

echo_message_dlackware () {
#****************************************************************
echo "-------------------------------------------"
echo
echo "By now, you are ready to build Slackware From Scratch."
echo "and wait a long time, a few hours."
echo
echo "You can do it by hand, by building packwage, one by one."
echo "./package.SlackBuild && installpkg /tmp/package*.t?z"
echo
echo "You can also do it with only one script, for dlackware."
echo
echo "(aka slackware with systemd init system)"
echo
echo "time (./sfsbuild1.sh build1_d.list)"
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
echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

echo
echo "There should be no errors, and the output of the last command"
echo "will be (allowing for platform-specific differences in dynamic"
echo "linker name):"
echo "[Requesting program interpreter: /lib/ld-linux.so.2]"
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
echo -n "Enter <Enter> to continue:"
}

test_6 () {
# Lastly, make sure GCC is using the correct dynamic linker:
grep found dummy.log

echo
echo "The output of the last commnand should be (allowing for"
echo "platform-specific differences in dynamic linker name and"
echo "a lib64 directory on 64-bit hosts):"
echo "	found ld-linux.so.2 at /lib/ld-linux.so.2"
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
# Note: Much of this script is copied from the LFS-7.9 manual.
#       Copyright © 1999-2015 Gerard Beekmans and may be
#       copied under the MIT License.
#****************************************************************
mkdir -pv /usr/lib && mkdir -v /bin && mkdir -pv /usr/include
mkdir -pv /usr/src
ln -sv /tools/bin/{bash,cat,du,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh
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
# Note: Much of this script is copied from the LFS-7.9 manual.
#       Copyright © 1999-2015 Gerard Beekmans and may be
#       copied under the MIT License.
#****************************************************************
mkdir -pv /usr/lib64 && mkdir -v /bin && mkdir -pv /usr/include
mkdir -pv /usr/src
ln -sv /tools/bin/{bash,cat,du,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib64/libgcc_s.so{,.1} /usr/lib64
ln -sv /tools/lib64/libstdc++.so{,.6} /usr/lib64
sed 's/tools/usr/' /tools/lib64/libstdc++.la > /usr/lib64/libstdc++.la
ln -sv bash /bin/sh
}

pre_elflibs () {
#******************************************************************
# Install packages from slackware-14.1 to be able
# to build aaa_alflibs
#******************************************************************
cd /slacksrc/others
installpkg cxxlibs-6.0.18-i486-1.txz
installpkg gdbm-1.8.3-i486-4.txz
installpkg gmp-5.1.3-i486-1.txz
installpkg libjpeg-v8a-i486-1.txz
installpkg libpng-1.4.12-i486-1.txz
installpkg libtiff-3.9.7-i486-1.txz
installpkg readline-5.2-i486-4.txz
installpkg udev-182-i486-7.txz
installpkg /sfspacks/d/gcc-g++-5*.txz
installpkg /sfspacks/l/libpng-1.6.2*.txz
installpkg /sfspacks/l/gmp-6.1*.txz
cd /sources
}

pre_elflibs64 () {
#******************************************************************
# Install packages from slackware-14.1 to be able
# to build aaa_alflibs
#******************************************************************
cd /slacksrc/others
installpkg cxxlibs-6.0.18-x86_64-1.txz
installpkg gdbm-1.8.3-x86_64-4.txz
installpkg gmp-5.1.3-x86_64-1.txz
installpkg libjpeg-v8a-x86_64-1.txz
installpkg libpng-1.4.12-x86_64-1.txz
installpkg libtiff-3.9.7-x86_64-1.txz
installpkg readline-5.2-x86_64-4.txz
installpkg udev-182-x86_64-7.txz
installpkg /sfspacks/d/gcc-g++-5*-x86_64*.txz
installpkg /sfspacks/l/libpng-1.6.2*-x86_64*.txz
installpkg /sfspacks/l/gmp-6.1*-x86_64*.txz
cd /sources
}

post_elflibs () {
#******************************************************************
# Remove packages temporary installed after
# aaa_elflibs has been built and installed
# libpng14.la is needed to build Imagemagick and GConf.
#******************************************************************
cd /usr/lib && cp libpng14.la libpng14.la.orig
removepkg libpng-1.4.12-i486-1 libjpeg-v8a-i486-1 readline-5.2-i486-4 libtiff-3.9.7-i486-1
removepkg gdbm-1.8.3-i486-4 gmp-5.1.3-i486-1 udev-182-i486-7 cxxlibs-6.0.18-i486-1
mv libpng14.la.orig libpng14.la
installpkg /sfspacks/l/libpng-1.6.2*.txz
cd /sources
}

post_elflibs64 () {
#******************************************************************
# Remove packages temporary installed after
# aaa_elflibs has been built and installed
# libpng14.la is needed to build Imagemagick and GConf.
#******************************************************************
cd /usr/lib64 && cp libpng14.la libpng14.la.orig
removepkg libpng-1.4.12-x86_64-1 libjpeg-v8a-x86_64-1 readline-5.2-x86_64-4 libtiff-3.9.7-x86_64-1
removepkg gdbm-1.8.3-x86_64-4 gmp-5.1.3-x86_64-1 udev-182-x86_64-7 cxxlibs-6.0.18-x86_64-1
mv libpng14.la.orig libpng14.la
installpkg /sfspacks/l/libpng-1.6.2*.txz
cd /sources
}

gcc_build () {
#***************************************************************
#!/bin/bash
#***************************************************************
#
#	sfsbuildgcc.sh
#
#	This script builds the complete Slackware gcc system.
#
#  Revision 0	  20160223						J. E. Garrott, Sr
#  Revision 1     20160603						nobodino
#	Revision	2		27052016						nobodino
#		-make it work again!
#
#***************************************************************
# First remove the current gcc packages
removepkg gcc-5.3.0-i586-1
removepkg gcc-g++-5.3.0-i586-1
removepkg gcc-gfortran-5.3.0-i586-1
# Then open the extra tar package in gnuada
cd /tmp
tar xf /slacksrc/others/gnuada/gnat-gpl-2014-x86-linux-bin.tar.gz
if [ $? != 0 ]; then
	echo
	echo "Tar extraction of gnat-gpl-2014-x86-linux-bin failed."
	echo
	exit 1
fi

# Now prepare the environment
cd gnat-gpl-2014-x86-linux-bin
make ins-all prefix=/opt/gnat
PATH_HOLD=$PATH && export PATH=/opt/gnat/bin:$PATH_HOLD
echo $PATH
find /opt/gnat -name ld -exec mv -v {} {}.old \;
find /opt/gnat -name ld -exec as -v {} {}.old \;
cd /opt/gnat/bin
ln -sf gcc cc
cd /slacksrc/d/gcc

# Finally we get to build.
time (./gcc.SlackBuild.old 2>&1 |tee gcc.log)
[ $? != 0 ] && exit 1

# If everything went right now we install packages and clean up.
installpkg /gcc*/gcc*.txz
mv /gcc*/gcc*.txz /sfspacks/d
export PATH=$PATH_HOLD
rm -rf /opt/gnat
cd /tmp
rm -rf *
cd /
rm -rf gcc*
}

gcc_build64 () {
#***************************************************************
#!/bin/bash
#***************************************************************
#
#	sfsbuildgcc.sh
#
#	This script builds the complete Slackware gcc system.
#
#  Revision 0	  20160223						J. E. Garrott, Sr
#  Revision 1     20160603						nobodino
#	Revision	2		27052016						nobodino
#		-make it work again!
#
#***************************************************************
# First remove the current gcc packages
removepkg gcc-5.3.0-x86_64-1
removepkg gcc-g++-5.3.0-x86_64-1
removepkg gcc-gfortran-5.3.0-x86_64-1
# Then open the extra tar package in gnuada
cd /tmp
tar xf /slacksrc/others/gnuada64/gnat-gpl-2015-x86_64-linux-bin.tar.gz
if [ $? != 0 ]; then
	echo
	echo "Tar extraction of gnat-gpl-2015-x86_64-linux-bin failed."
	echo
	exit 1
fi

# Now prepare the environment
cd gnat-gpl-2015-x86_64-linux-bin
make ins-all prefix=/opt/gnat
PATH_HOLD=$PATH && export PATH=/opt/gnat/bin:$PATH_HOLD
echo $PATH
find /opt/gnat -name ld -exec mv -v {} {}.old \;
find /opt/gnat -name ld -exec as -v {} {}.old \;
cd /opt/gnat/bin
ln -sf gcc cc
cd /slacksrc/d/gcc

# Finally we get to build.
time (./gcc.SlackBuild.old 2>&1 |tee gcc.log)
[ $? != 0 ] && exit 1

# If everything went right now we install packages and clean up.
installpkg /gcc*/gcc*.txz
mv /gcc*/gcc*.txz /sfspacks/d
export PATH=$PATH_HOLD
rm -rf /opt/gnat
cd /tmp
rm -rf *
cd /
rm -rf gcc*
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

./x11.SlackBuild driver xf86-video-geode
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

./x11.SlackBuild app intel-gpu-tools
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

cd /sources
}

build_x11_app_post2 () {
#****************************************************************
cd /slacksrc/x/x11

export UPGRADE_PACKAGES=always

./x11.SlackBuild font ttf-indic-fonts
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font sinhala_lklug-font-ttf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font tibmachuni-font-ttf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

./x11.SlackBuild font wqy-zenhei-font-ttf
[ $? != 0 ] && exit 1
cd /tmp/x11-build
mv *.txz /sfspacks/x
cd /slacksrc/x/x11

cd /sources
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
# Ensure that the /sfspacks/$SAVDIRs exist.
#****************************************************************
distribution="slackware"
mkdir -pv /sfspacks/{SBO,others,a,ap,d,e,extra,f,k,kde,kdei,l,n,t,tcl,testing,x,xap,xfce,y}

#******************************************************************
# BUILDN: defines if package will be installed or upgraded
#******************************************************************

# init freetype variable
LFRE=1
# init help2man variable
LHEL=2
# init libusb variable
LUSB=1
# init pkg-config variable
LPKG=1
# init libcap variable
LCAP=1
# init python variable
LPYT=1
# init llvm variable
LPVM=1
# init nasm variable
LPNA=1
# init libcaca variable
LCAC=1

#**************************************************************
# read the length of build.list and affect SRCDIR and PACKNAME
#**************************************************************

[ "$1" == "" ] && on_error
[ ! -f $1 ] && on_error
LISTFILE=$1

FILELEN=$(wc -l $LISTFILE |cut -d' ' -f1)

typeset -i LINE=0

# read the list file into an array
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

	case $SRCDIR in

		dlackware )
			export BUILDN=1
			build_s $SRCDIR $PACKNAME
			[ $? != 0 ] && exit 1 ;;

		* )
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

				ca-certificates )
					export BUILDN=1
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					update-ca-certificates ;;

				cmake )
					case $LISTFILE in
						build1_s.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build1_s0.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build1_d.list )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_d.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				dbus )
					case $LISTFILE in
						build2_s.list )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							dbus-uuidgen --ensure ;;

						build2_d.list )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;

						build3_d.list )
							build_s $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				freetype )
					BUILDN=$LFRE
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					LFRE=2 ;;

				gcc-all )
					case $ARCH in
						x86_64 )
							gcc_build64
							[ $? != 0 ] && exit 1 ;;
						* )
							gcc_build
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				kernel )
					kernel_build
					[ $? != 0 ] && exit 1 ;;
				
				kmod )
					case $BUILDLIST in
						build0_s.list )
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
						* )
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				kernel-headers )
					kernel_headers_build
					[ $? != 0 ] && exit 1 ;;

				link_tools_dlackware )
					test_progs
					distribution="dlackware"
					dlackware_path
					case $ARCH in
						x86_64 )
							link_tools_x64
							echo_message_dlackware && exit 1 ;;
						* )
							link_tools
							echo_message_dlackware && exit 1 ;;
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

				pci-utils )
					export BUILDN=1
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					update-pciids ;;

				pre-elflibs )
					case $ARCH in
						x86_64 )
							pre_elflibs64
							[ $? != 0 ] && exit 1 ;;
						* )
							pre_elflibs
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				post-elflibs )
					case $ARCH in
						x86_64 )
							post_elflibs64
							[ $? != 0 ] && exit 1 ;;
						* )
							post_elflibs
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				help2man )
					BUILDN=$LHEL
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				glib-networking )
					export BUILDN=1
					update-ca-certificates
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

				libcap )
					case $LCAP in
						1 )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LCAP=2 ;;
						2 )
							export BUILDN=2
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;
	
				libusb )
					case $LUSB in
						1 )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LUSB=2 ;;
						2 )
							export BUILDN=2
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				llvm )
					case $LPVM in
						1 )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LPVM=2 ;;
						2 )
							export BUILDN=2
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				nasm )
					case $LPNA in
						1 )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LPNA=2 ;;
						2 )
							export BUILDN=2
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				pkg-config )
					case $LPKG in
						1 )
							export BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1
							LPKG=2 ;;
						2 )
							export BUILDN=2
							build1 $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				python )
					export BUILDN=$LPYT
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1
					LPYT=2 ;;

				utempter )
					export BUILDN=1
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

				upower )
					case $ARCH in
						x86_64 )
							BUILDN=1
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
						* )
							BUILDN=1
							# upower doesn't build without than symlink
							ln -sf /usr/lib/libgudev-1.0.so.0.2.0 /usr/lib/libgudev-1.0.so.0
							ln -sf /usr/lib/libgudev-1.0.so.0.2.0 /usr/lib/libgudev-1.0.so
							ln -sf /lib/libgudev-1.0.so.0 /usr/lib/libgudev-1.0.so.0.2.0
							ldconfig
							build $SRCDIR $PACKNAME
							[ $? != 0 ] && exit 1 ;;
					esac
					continue ;;

				x11-doc )
					build_x11_doc
					[ $? != 0 ] && exit 1 ;;

				x11-proto )
					build_x11_proto
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
					export BUILDN=1
					build $SRCDIR $PACKNAME
					[ $? != 0 ] && exit 1 ;;

			esac
	esac
done
clean_tmp
echo
echo "sfsbuild1.sh has finished his job!"
echo "Slackware is ready to boot."
echo "Modify your bootloader to test your new environment."
echo
