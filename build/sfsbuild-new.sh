################################  sfsbuild.sh ##############################
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

update_slackbuild () {
#****************************************************************
# rename SlackBuild.old to original SlackBuild
#****************************************************************
cd /source/"$SRCDIR"/"$PACKNAME" || exit 1 
mv "$PACKNAME".SlackBuild.old "$PACKNAME".SlackBuild
cd /scripts || exit 1
}

build_package () {
#****************************************************************
# build a special $PACKAGE with build_$PACKNAME in slackware
# source tree like gettext-tools, seamonkey....
#****************************************************************
cd  /source/"$SRCDIR"/"$PACKNAME"

# test the existence of build_$PACKANME to decide whether the 
# build is special (with build_$PACKANME) or normal with the 
# SlackBuild
if [ -f /source/"$SRCDIR"/"$PACKNAME"/build_"$PACKNAME" ]; then
	if ! (source build_"$PACKNAME" ); then
		exit 1
	fi
elif
# normal build with the SlackBuild
	if ! ( build "$SRCDIR" "$PACKNAME" ); then
		exit 1
	fi
fi

return
}

#****************************************************************
#****************************************************************
# MAIN CORE SCRIPT of sfsbuild
#****************************************************************
#****************************************************************
test_arch
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

# special build package or just utilities 

				test-glibc )
					cd /source/l/glibc && source build_test-glibc ;;

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

				linux-faqs )
					cd /source/f && source build_linux-faqs ;;

				linux-howtos )
					cd /source/f && source build_linux-howtos ;;

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

# package built with build_package
				* )
					build_package ;;
			esac
done
echo
