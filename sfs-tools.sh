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
    echo -e "$RED" "You choose to build 'tools' for SFS." "$NORMAL"
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
    cd $RDIR/d/gcc || exit 1	
	export SRCVER=${VERSION:-$(echo gcc-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
	GCCVER=$(echo "$SRCVER" | cut -f 1 -d _)
	export GCCVER
    cp -v $RDIR/d/gcc/gcc-"$SRCVER".tar.?z "$SRCDIR" || exit 1
	if [[ "$ada_enable" = "yes" ]]
	then
		case $(uname -m) in
			i686 ) 
				if [ -f "$RDIR"/others/gnat-gpl-2014-x86-linux-bin.tar.gz ]; then
					cd "$RDIR"/others || exit 1
					cp -v "$RDIR"/others/gnat-gpl-2014-x86-linux-bin.tar.gz "$SRCDIR" || exit 1
				fi
				return ;;
			x86_64 )
				if [ -f "$RDIR"/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz ]; then
					cd "$RDIR"/others || exit 1 
					cp -v "$RDIR"/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz "$SRCDIR" || exit 1
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
    echo -e "$GREEN" "You choose to continue the process of building 'tools' for SFS." "$NORMAL" 
}

gnat_build_sp2 () {
#*****************************
	cd "$SFS"/scripts || exit 1 
	tar xvf gcc-"$SRCVER".tar.xz || exit 1
	cd gcc-"$SRCVER" || exit 1 

	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
	  "dirname $("$SFS_TGT"-gcc -print-libgcc-file-name)"/include-fixed/limits.h

	for file in gcc/config/{linux,i386/linux{,64}}.h
	do
	  cp -uv $file{,.orig}
	  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
		  -e 's@/usr@/tools@g' $file.orig > $file
	  echo '
	#undef STANDARD_STARTFILE_PREFIX_1
	#undef STANDARD_STARTFILE_PREFIX_2
	#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
	#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
	  touch $file.orig
	done

	case $(uname -m) in
	  x86_64)
		sed -e '/m64=/s/lib64/lib/' \
		    -i.orig gcc/config/i386/t-linux64
	  ;;
	esac

    tar xvf ../mpfr-"$MPFRVER".tar.xz
    mv -v mpfr-"$MPFRVER" mpfr
    tar xvf ../gmp-"$GMPVER".tar.xz
    mv -v gmp-"$GMPVER" gmp
    tar xvf ../mpc-"$LIBMPCVER".tar.lz
    mv -v mpc-"$LIBMPCVER" mpc

   	mkdir -v build
	cd build || exit 1 

	../configure \
		--prefix=/tools \
		--disable-multilib \
		--enable-bootstrap \
		--enable-languages=ada || exit 1

    make || exit 1
	make bootstrap || exit 1
	make -C gcc gnatlib || exit 1
	make -C gcc gnattools || exit 1
    make install || exit 1
	export PATH=$PATH_HOLD
    cd ../..
	rm -rf gnat-gpl*
	rm -rf /tools/opt/gnat
	rm -rf /tools/tmp
}

glibc_repair () {
#*****************************
	case $GLIBCVER in
		2.33 )
			cd /tools/lib
			cp -v libc-$GLIBCVER.so.backup libc-$GLIBCVER.so
			ln -sf libc-$GLIBCVER.so libc.so.6
			rm libc-$GLIBCVER.so.backup
			cd $SFS/scripts ;;
		2.34 )
			echo ;;
	esac
}

strip_libs () {
#*****************************
    /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
    rm -rf /tools/{,share}/{info,man,doc}
	find /tools/{lib,libexec} -name \*.la -delete
}

clean_sources () {
#*****************************
echo "clean sources packages"
rm *.xz *.lz *.gz
chown -fR root:root $SFS/source
}

echo_end () {
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
		echo "then type:"
		echo
		echo -e "$GREEN" "cd gcc*/build && make install 2>&1 | tee > /dev/null" "$NORMAL"
		echo
		echo "then type:"
		echo
		echo -e "$GREEN" "cd ../.. && rm -rf gcc*" "$NORMAL"
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
# ada_choice
copy_src
test_to_go
cd "$SRCDIR" || exit 1 
cd $RDIR/d/binutils && source binutils_build_sp1
cd $RDIR/d/gcc && source gcc_build_sp1
cd $RDIR/k && source linux_headers_build
cd $RDIR/l/glibc && source glibc_build
cd $RDIR/d/gcc && source libstdc_build
cd $RDIR/d/binutils && source binutils_build_sp2
cd $RDIR/l/gmp && source gmp_build
cd $RDIR/l/isl && source isl_build
cd $RDIR/d/gcc && source gcc_build_sp2
cd $RDIR/d/m4 && source m4_build
cd $RDIR/l/ncurses && source ncurses_build
cd $RDIR/a/bash/ && source bash_build
cd $RDIR/d/bison && source bison_build
cd $RDIR/a/bzip2 && source bzip2_build
cd $RDIR/a/coreutils && source coreutils_build
cd $RDIR/ap/diffutils && source diffutils_build
cd $RDIR/a/file && source file_build
cd $RDIR/a/findutils && source findutils_build
cd $RDIR/a/gawk && source gawk_build
cd $RDIR/a/gettext && source gettext_build
cd $RDIR/a/grep && source grep_build
cd $RDIR/a/gzip && source gzip_build
cd $RDIR/d/automake && source automake_build
cd $RDIR/d/make && source make_build
cd $RDIR/a/patch && source patch_build
cd $RDIR/d/perl && source perl_build
cd $RDIR/l/zlib && source zlib_build
cd $RDIR/a/xz && source xz_build
cd $RDIR/d/python3 && source python_build
cd $RDIR/a/sed && source sed_build
cd $RDIR/a/tar && source tar_build
cd $RDIR/ap/texinfo && source texinfo_build
cd $RDIR/a/lzip && source lzip_build
cd $RDIR/a/tar && source tar_slack_build
cd $RDIR/a/which && source which_build
cd $RDIR/a/util-linux && source util_linux_build
cd $RDIR/l/zstd && source zstd_build
glibc_repair
#*****************************
if [[ "$ada_enable" = "yes" ]]
then
	case $(uname -m) in
		x86_64 )
			if ! tar xf gnat-gpl-2017-x86_64-linux-bin.tar.gz; then
				echo
				echo "Tar extraction of gnat-gpl-2017-x86_64-linux-bin failed."
				echo
			exit 1
			fi
			# Now prepare the environment
			cd gnat-gpl-2017-x86_64-linux-bin || exit 1
			echo ;;  
		i686 )
			if ! tar xf gnat-gpl-2014-x86-linux-bin.tar.gz; then
				echo
				echo "Tar extraction of gnat-gpl-2014-x86-linux-bin failed."
				echo
			exit 1
			fi
			# Now prepare the environment
			cd gnat-gpl-2014-x86-linux-bin || exit 1
			echo ;; 
	esac
	mkdir -pv /tools/opt/gnat
	make ins-all prefix=/tools/opt/gnat
	PATH_HOLD=$PATH && export PATH=/tools/opt/gnat/bin:$PATH_HOLD
	echo "$PATH"
	find /tools/opt/gnat -name ld -exec mv -v {} {}.old \;
	find /tools/opt/gnat -name ld -exec as -v {} {}.old \;
	gnat_build_sp2
elif [[ "$ada_enable" = "no" ]]
 then
	echo
fi
#*****************************
strip_libs
clean_sources
echo_end
exit 0
