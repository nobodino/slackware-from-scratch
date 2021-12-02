################################  sfsbuild.sh #################################
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
#       Copyright © 1999-2021 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
#
#	sfsbuild.sh
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
echo 	"Usage: ./sfsbuild.sh build1.list"
echo
echo	"The build.list of programs to build, and their source directories is required."
echo
echo	"The packages will not be processed until the end of the build{1,4}.list."
echo
exit 255
}

adjust_links () {
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
case $(uname -m) in
	x86_64 )
		gcc -dumpspecs | sed -e 's@/tools@@g'                   \
			-e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib64/ @}' \
			-e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
			`dirname $(gcc --print-libgcc-file-name)`/specs ;;
	* )
		gcc -dumpspecs | sed -e 's@/tools@@g'                   \
			-e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
			-e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
			`dirname $(gcc --print-libgcc-file-name)`/specs ;;
esac
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
# build the $PACKAGE
cd "$SLACKSRC"/"$SRCDIR"/"$PACKNAME" || exit 1
chmod +x "$PACKNAME".SlackBuild
if ! ./"$PACKNAME".SlackBuild
then
	exit 1
fi
# install the $PACKAGE
export TERM=xterm && cd /tmp || exit 1
if ! $INSTALLPRG /tmp/"$PACKNAME"*.t?z;
then
	exit 1
fi
# move the $PACKAGE where it should be
case $(uname -m) in
	x86_64 )
		if ! ( mv -v /tmp/"$PACKNAME"*.t?z /slackware64/"$SRCDIR" ); then
			exit 1
		fi ;;
	* )
		if ! ( mv -v /tmp/"$PACKNAME"*.t?z /slackware/"$SRCDIR" ); then
			exit 1
		fi ;;
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
echo -e "$YELLOW" "time ./sfsbuild.sh build1.list" "$NORMAL"
echo
echo "Either, you can also do it in one step, by executing the"
echo "following command, it will build the entire system till the end:"
echo
echo -e "$BLUE" "time ./full-sfs.sh" "$NORMAL"
echo
echo "Either, you can also build a small slackware system with no X11 system, "
echo "by executing the following command:"
echo
echo -e "$RED" "time ./sfsbuild.sh build0.list" "$NORMAL"
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
# if not, modify build1.list to have 
# 'd pre-gcc' and 'd post-gcc' to build gcc
#******************************************
(! /tools/bin/gnat) 1> /dev/null && sed -i -e 's/# d/d/g' build1.list
(! /tools/bin/gnat) 1> /dev/null && sed -i -e 's/# d/d/g' build0.list
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

case $ARCH in
	x86_64 )
		ln -sv /tools/lib64/libgcc_s.so{,.1} /usr/lib64
		ln -sv /tools/lib64/libstdc++.{a,so{,.6}} /usr/lib64 ;;
	* )
		ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
		ln -sv /tools/lib/libstdc++.{a,so{,.6}} /usr/lib ;;
esac

ln -sv bash /bin/sh
ln -sv /proc/self/mounts /etc/mtab

echo_message_slackware && echo
}

message_end1 () {
#****************************************************************
echo
echo "sfsbuild.sh has finished to build the first part of SFS."
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
echo -e "$YELLOW" "time ./sfsbuild.sh build2.list" "$NORMAL"
echo
echo "After that, you should have an X11 system with blackbox."
echo
echo
cd /scripts && killall -9 dhcpcd
}

message_end2 () {
#****************************************************************
echo
echo "sfsbuild.sh has finished to build the second part of SFS."
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
echo -e "$YELLOW" "time ./sfsbuild.sh build3.list" "$NORMAL"
echo
echo "After that you should have an X11 system with xfce."
echo
echo
cd /scripts && killall -9 dhcpcd
}

message_end3 () {
#****************************************************************
echo
echo "sfsbuild.sh has finished to build the third part of SFS."
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
echo -e "$YELLOW"  "time ./sfsbuild.sh build4.list" "$NORMAL"
echo
echo "After that you should have a complete Slackware system"
echo
echo
cd /scripts && killall -9 dhcpcd
}

message_end4 () {
#****************************************************************
echo
echo "sfsbuild.sh has finished to build the fourth part of SFS."
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
ls */*.t?z > /scripts/list-sfs
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
#****************************************************************
# modify the original SlackBuild
#****************************************************************
cd  /source/"$SRCDIR"/"$PACKNAME" && source execute_sed_"$PACKNAME"
if ! ( build "$SRCDIR" "$PACKNAME" ); then
	exit 1
fi
update_slackbuild
}

build_pkg_2 () {
#****************************************************************
# build a normal $PACKAGE with SlackBuild
#****************************************************************
if ! ( build "$SRCDIR" "$PACKNAME" ); then
	exit 1
fi
return
}

build_pkg_3 () {
#****************************************************************
# build a special $PACKAGE with build_$PACKNAME in slackware
# source tree like gettext-tools, seamonkey....
#****************************************************************
cd  /source/"$SRCDIR"/"$PACKNAME"
if ! (source build_"$PACKNAME" ); then
	exit 1
fi
return
}

#****************************************************************
#****************************************************************
# MAIN CORE SCRIPT of sfsbuild
#****************************************************************
#****************************************************************
test_arch
test_gnat
define_path_lib

#****************************************************************
# Ensure that the /{slackware;salckware64}/$SAVDIRs exists.
#****************************************************************
case $(uname -m) in
	x86_64 )
		mkdir -pv /slackware64/{others,a,ap,d,e,extra,f,installer,k,kde,l,n,t,tcl,x,xap,xfce,y}
		mkdir -pv /slackware64/extra/{aspell-words-list,bash-completion,bittornado,brltty,fltk,getty-ps,java,php8,sendmail,tigervnc,xf86-video-fbdev,xfractint,xv};;

	* )
		mkdir -pv /slackware/{others,a,ap,d,e,extra,f,installer,k,kde,l,n,t,tcl,x,xap,xfce,y}
		mkdir -pv /slackware/extra/{aspell-words-list,bash-completion,bittornado,brltty,fltk,getty-ps,java,php8,sendmail,tigervnc,xf86-video-fbdev,xfractint,xv};;
esac
#******************************************************************
# Some packages need two pass to be built completely.
# Alteration of the slackware sources is made "on the fly" during
# the first build. On the second pass, the old SlackBuild is 
# renamed to its original version, and package can be built normally. 
#	execute_sed_cmake # 2 pass
#	execute_sed_dbus # 2 pass
#	execute_sed_findutils # 2 pass
#	execute_sed_fontconfig # 2 pass
#	execute_sed_freetype # 2 pass
#	execute_sed_gd # 2 pass
#	execute_sed_glib2 # 2 pass
#	execute_sed_gobject # 2 pass
#	execute_sed_harfbuzz # 2 pass
#	execute_sed_kmod # 2 pass
#	execute_sed_libusb # 2 pass
#	execute_sed_llvm # 2 pass
#	execute_sed_pkg_config # 2 pass
#	execute_sed_readline # 3 pass
#	execute_sed_subversion # 2 pass
#	execute_sed_texlive # 2 pass
#	execute_sed_zstd # 2 pass
#	execute_sed_perl # 2 pass
#	execute_sed_openldap # 2 pass
# 	execute_sed_libtirpc variable # 2 pass
# 	execute_sed_elogind variable # 2 pass
# 	execute_sed_libxkbcommon variable # 2 pass
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

				aaa_terminfo )
					build_pkg_3 ;;

				adjust)
					adjust_links ;;

				alpine )
					build_pkg_3 ;;

				alsa-lib )
					case $LISTFILE in
						build2.list )
							build_pkg_1 ;;
						* )
							rm /slackware64/l/alsa-lib*.t?z
							build_pkg_1 ;;
					esac
					continue ;;

				aspell-word-lists )
					cd /source/extra/aspell-word-lists && source build_aspell-dict ;;

				bash-completion )
					build_pkg_3 ;;

				ca-certificates )
					build_pkg_2
					update-ca-certificates ;;

				cmake )
					case $LISTFILE in
						build1.list )
							build_pkg_1 ;; 
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				cyrus-sasl )
					case $LISTFILE in
						build1.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				dbus )
					case $LISTFILE in
						build2.list )
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
						build1.list )
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
						build2.list )
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

				gettext-tools )
					cd /source/a/gettext && source build_gettext-tools ;;

				glib2 )
					case $LISTFILE in
						build1.list )
							build_pkg_1 ;;
						build2.list )
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
						build1.list )
							build_pkg_1 ;; 
						build2.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				gpgme )
					case $LISTFILE in
						build3.list )
							build_pkg_1 ;;
						build4.list )
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

				java )
					build_pkg_3 ;;

				extra-cmake-modules )
					cd /source/kde/kde && source build_extra-cmake-modules ;;

				kde )
					cd /source/kde/kde && source build_kde ;;  

				kernel-all )
					cd /source/k
					if ! (source build_kernel-all ); then
						exit 1
					fi ;;

				kernel-headers )
					cd /source/k
					if ! (source build_kernel-headers ); then
						exit 1
					fi ;; 

				kernel-source )
					cd /source/k
					if ! (source build_kernel-source ); then
						exit 1
					fi ;;

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
					test_progs && link_tools ;;

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
					cd /source/f && source build_linux-faqs ;;

				linux-howtos )
					cd /source/f && source build_linux-howtos ;;

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

				mozjs78 )
					build_pkg_3 ;;

				mozilla-firefox )
					build_pkg_3 ;;

				mozilla-thunderbird )
					build_pkg_3 ;;

				openldap )
					case $LOPE in
						1 )
							build_pkg_1
							LOPE=2 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				openssl )
					build_pkg_3 ;;

				pam )
					case $LISTFILE in
						build1.list )
							build_pkg_1 ;;
						build2.list )
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

				php )
					build_pkg_3 ;;

				pkg-config )
					case $LISTFILE in
						build1.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				aaa_libraries_pre )
					cd /source/a/aaa_libraries && source build_aaa_libraries_pre ;; 

				aaa_libraries_post )
					cd /source/a/aaa_libraries && source build_aaa_libraries_post ;; 

				gcc-pre )
					cd /source/d/gcc && source build_gcc_pre ;; 

				gcc-post )
					cd /source/d/gcc && source build_gcc_post ;; 

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

				seamonkey )
					build_pkg_3 ;;

				snownews )
					build_pkg_3 ;;

				subversion )
					case $LISTFILE in
						build3.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				texlive )
					case $LISTFILE in
						build2.list )
							build_pkg_1 ;;
						* )
							build_pkg_2 ;;
					esac
					continue ;;

				utempter )
					touch /var/run/utmp && build_pkg_2 ;;

				vim )
					build_pkg_3 ;;

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
					cd /source/x/x11 && source build_x11-group1 ;; 

				x11-group2 )
					cd /source/x/x11 && source build_x11-group2 ;;  

				x11-app-post )
					cd /source/x/x11 && source build_x11-app-post ;;    

				x11-lib )
					cd /source/x/x11 && source build_x11-lib ;;  

				x11-xcb )
					cd /source/x/x11 && source build_x11-xcb ;;

				xz )
					build_pkg_3 ;;   

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
