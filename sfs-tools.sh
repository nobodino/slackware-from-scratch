#!/bin/bash
########################## sfs-tools.sh #############################
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
# Note: Much of this script is inspired from the LFS manual chapter 5
#       Copyright © 1999-2021 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
#
# script to build 'tools' for Slackware From Scratch (SFS)
# script to be executed once 'su - sfs' has been performed.
#
#
# It doesn't respect exactly the list of the packages given in the LFS book.
# Some packages needed for testing in the chapter 6 have been skipped.
# Some other packages have been added to be able to build slackware.
#
# Everything will be done automatically in this script.
#--------------------------------------------------------------------------
#
#	Above july 2018, revisions made through github project: 
#	https://github.com/nobodino/slackware-from-scratch 
# 
#*******************************************************************
# set -xv
#*******************************************************************
# the directory where will be built slackware from scratch
#*******************************************************************
export SFS=/mnt/sfs
#*******************************************************************
# the directory where is stored the resynced slackware sources
#*******************************************************************
export RDIR=$SFS/source
#*******************************************************************
# the directory where will be stored the slackware source for SFS
#*******************************************************************
export SRCDIR=$SFS/scripts
SFS_TGT=$(uname -m)-sfs-linux-gnu
export SFS_TGT
#*******************************************************************
# set your own MAKEFLAGS
#*******************************************************************
export MAKEFLAGS='-j 9'
#*******************************************************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#*******************************************************************

echo_begin () {
#*****************************
    echo
    echo "You have decided to build 'tools' for sfs (aka Slackware From Scratch)."
    echo
    echo "You are at the end of paragraph 4.4 of LFS-8.1 book"
    echo
    echo "The last command you executed was:"
    echo
    echo -e "$GREEN" "source ~/.bash_profile" "$NORMAL" 
    echo
    echo "Your Slackware source packages are in: $RDIR"
    echo "Your MAKEFLAGS are: $MAKEFLAGS"
    echo "Are you ok with this?"
    echo
    echo "From now everything will be built automatically until the end."
    echo "When you're ready just press <1> for begin or <2> for quit."
    echo

    PS3="Your choice:"
    select build in begin quit
    do
        if [[ "$build" = "begin" ]]
        then
            break
        else [[ "$build" = "quit" ]]
            echo  -e "$GREEN" "You have decided to quit. Goodbye."  "$NORMAL" && exit 1
        fi
    done
    echo -e "$RED" "You chose to build 'tools' for SFS." "$NORMAL"
}

ada_choice () {
#*****************************
	PS3="Your choice:"
	echo
	echo -e "$GREEN" "Do you want to build the tools with gnat ada: yes or no." "$NORMAL"
	echo
	select ada_enable in yes no
	do
		if [[ "$ada_enable" = "yes" ]]
		then
			echo
			echo -e "$RED" "You decided to build the tools with gnat ada. It will be quiet long" "$NORMAL"
			echo
			break
		elif [[ "$ada_enable" = "no" ]]
		then
			echo
			echo -e "$RED" "You decided to build the tools without gnat ada." "$NORMAL"
			echo -e "$YELLOW" "You may chose that option when building a minimal SFS system with no gnat compiler." "$NORMAL"
			echo
			break
		fi
	done
}

copy_src () {
#*****************************
	cd $SRCDIR && cp -rv $SRCDIR/build/* $RDIR
    cd $RDIR/l/gmp || exit 1
	export GMPVER=${VERSION:-$(echo gmp-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/gmp/gmp-"$GMPVER".tar.?z "$RDIR/d/gcc" || exit 1
    cd $RDIR/l/libmpc || exit 1
	export LIBMPCVER=${VERSION:-$(echo mpc-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/l/libmpc/mpc-"$LIBMPCVER".tar.?z "$RDIR/d/gcc" || exit 1
    cd $RDIR/l/mpfr || exit 1
	export MPFRVER=${VERSION:-$(echo mpfr-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/mpfr/mpfr-"$MPFRVER".tar.?z "$RDIR/d/gcc" || exit 1
	if [[ "$ada_enable" = "yes" ]]
	then
		case $(uname -m) in
			i686 ) 
				if [ -f "$RDIR"/others/gnat-gpl-2014-x86-linux-bin.tar.gz ]; then
					cd "$RDIR"/others || exit 1
					cp -v "$RDIR"/others/gnat-gpl-2014-x86-linux-bin.tar.gz "$RDIR/d/gcc" || exit 1
				fi
				return ;;
			x86_64 )
				if [ -f "$RDIR"/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz ]; then
					cd "$RDIR"/others || exit 1 
					cp -v "$RDIR"/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz "$RDIR/d/gcc" || exit 1
				fi
				return ;;
		esac
	elif [[ "$ada_enable" = "no" ]]
	then
		echo
	fi
}

test_to_go () {
#*****************************
    echo
    echo "Are you to go on ok?"
    echo
    PS3="Your choice:"
    select build in go-on quit
    do
        if [[ "$build" = "go-on" ]]
        then
            break
        else [[ "$build" = "quit" ]]
            echo -e "$RED" "You have decided to quit. Goodbye." "$NORMAL" && exit 1
        fi
    done
    echo -e "$GREEN" "You chose to continue the process of building 'tools' for SFS." "$NORMAL" 
}

strip_libs () {
#*****************************
    /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
    rm -rf /tools/{,share}/{info,man,doc}
	find /tools/{lib,libexec} -name \*.la -delete
}

echo_end () {
#*****************************
chown -fR root:root $SFS/source
#*****************************
    echo "The building of tools for sfs is finished."
    echo
	if [[ "$ada_enable" = "yes" ]]
		then
		echo "Now you can 'exit' from 'sfs environment"
		echo
		echo "Just type:"
		echo
		echo -e "$GREEN" "exit" "$NORMAL"
		echo
	elif [[ "$ada_enable" = "no" ]]
		then
			echo "Just type:"
			echo
			echo -e "$GREEN" "exit" "$NORMAL"
	fi
    echo "then type:"
	echo
	echo -e "$GREEN" "./chroot_sfs.sh" "$NORMAL"
    echo
}

#*****************************
# core script
#*****************************
echo_begin
ada_choice
copy_src
test_to_go
cd "$SRCDIR" || exit 1 
cd $RDIR/d/binutils && source tools_binutils_sp1
cd $RDIR/d/gcc && source tools_gcc_sp1
cd $RDIR/k && source tools_linux-headers
cd $RDIR/l/glibc && source tools_glibc
cd $RDIR/d/gcc && source tools_libstdc
cd $RDIR/d/binutils && source tools_binutils_sp2
cd $RDIR/l/gmp && source tools_gmp
cd $RDIR/l/isl && source tools_isl
cd $RDIR/d/gcc && source tools_gcc_sp2
cd $RDIR/d/m4 && source tools_m4
cd $RDIR/l/ncurses && source tools_ncurses
cd $RDIR/a/bash/ && source tools_bash
cd $RDIR/d/bison && source tools_bison
cd $RDIR/a/bzip2 && source tools_bzip2
cd $RDIR/a/coreutils && source tools_coreutils
cd $RDIR/ap/diffutils && source tools_diffutils
cd $RDIR/a/file && source tools_file
cd $RDIR/a/findutils && source findutils_build
cd $RDIR/a/gawk && source tools_gawk
cd $RDIR/a/gettext && source tools_gettext
cd $RDIR/a/grep && source tools_grep
cd $RDIR/a/gzip && source tools_gzip
cd $RDIR/d/automake && source tools_automake
cd $RDIR/d/make && source tools_make
cd $RDIR/a/patch && source tools_patch
cd $RDIR/d/perl && source tools_perl
cd $RDIR/l/zlib && source tools_zlib
cd $RDIR/a/xz && source tools_xz
cd $RDIR/d/python3 && source tools_python
cd $RDIR/a/sed && source tools_sed
cd $RDIR/a/tar && source tools_tar
cd $RDIR/ap/texinfo && source tools_texinfo
cd $RDIR/a/lzip && source tools_lzip
cd $RDIR/a/tar && source tools_tar_slack
cd $RDIR/a/which && source tools_which
cd $RDIR/a/util-linux && source tools_util-linux
cd $RDIR/l/zstd && source tools_zstd
cd $RDIR/l/glibc && source tools_glibc_repair
#*****************************
if [[ "$ada_enable" = "yes" ]]
then
	cd $RDIR/d/gcc && source gnat_build_sp2
elif [[ "$ada_enable" = "no" ]]
 then
	echo
fi
#*****************************
strip_libs
echo_end
exit 0
