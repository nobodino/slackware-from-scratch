#!/bin/bash
############ sfs-tools-current-with-ada-builtin.sh #############################
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
#       Copyright © 1999-2019 Gerard Beekmans and may be
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
#   https://github.com/nobodino/slackware-from-scratch 
# 
#*******************************************************************
# set -x
#*******************************************************************
# the directory where will be built slackware from scratch
#*******************************************************************
export SFS=/mnt/sfs
#*******************************************************************
# the directory where is stored the resynced slackware sources
#*******************************************************************
export RDIR=$SFS/slacksrc
#*******************************************************************
# the directory where will be stored the slackware source for SFS
#*******************************************************************
export SRCDIR=$SFS/sources
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
    cd $RDIR/a/bash/ || exit 1
	export BASHVER=${VERSION:-$(echo bash-*.tar.?z* | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
	cp -v $RDIR/a/bash/bash-"$BASHVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/d/binutils || exit 1
	export BINUVER=${VERSION:-$(echo binutils-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/binutils/binutils-"$BINUVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/d/bison || exit 1
	export BISONVER=${VERSION:-$(echo bison-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/bison/bison-"$BISONVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/a/bzip2 || exit 1
	export BZIP2VER=${VERSION:-$(echo bzip2-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/a/bzip2/bzip2-"$BZIP2VER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/a/coreutils || exit 1
	export COREVER=${VERSION:-$(echo coreutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/coreutils/coreutils-"$COREVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/ap/diffutils || exit 1
	export DIFFVER=${VERSION:-$(echo diffutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/ap/diffutils/diffutils-"$DIFFVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/file || exit 1
	export FILEVER=${VERSION:-$(echo file-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/file/file-"$FILEVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/a/findutils || exit 1
	export FINDVER=${VERSION:-$(echo findutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/findutils/findutils-"$FINDVER".tar.lz "$SRCDIR" || exit 1
    cd $RDIR/a/gawk || exit 1
	export GAWKVER=${VERSION:-$(echo gawk-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gawk/gawk-"$GAWKVER".tar.lz "$SRCDIR" || exit 1
    cd $RDIR/d/gcc || exit 1
	export SRCVER=${VERSION:-$(echo gcc-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
	GCCVER=$(echo "$SRCVER" | cut -f 1 -d _)
	export GCCVER
    cp -v $RDIR/d/gcc/gcc-"$SRCVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/a/gettext || exit 1
	export GETTVER=${VERSION:-$(echo gettext-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gettext/gettext-"$GETTVER".tar.lz "$SRCDIR" || exit 1
    cd $RDIR/l/glibc || exit 1
	export GLIBCVER=${VERSION:-$(echo glibc-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/glibc/glibc-"$GLIBCVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/l/gmp || exit 1
	export GMPVER=${VERSION:-$(echo gmp-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/gmp/gmp-"$GMPVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/l/isl || exit 1
	export ISLVER=${VERSION:-$(echo isl-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
	cp -v $RDIR/l/isl/isl-"$ISLVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/grep || exit 1
	export GREPVER=${VERSION:-$(echo grep-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/grep/grep-"$GREPVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/gzip || exit 1
	export GZIPVER=${VERSION:-$(echo gzip-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gzip/gzip-"$GZIPVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/k || exit 1
	export LINUXVER=${VERSION:-$(echo linux-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/k/linux-"$LINUXVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/lzip || exit 1
	export LZIPVER=${VERSION:-$(echo lzip-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/lzip/lzip-"$LZIPVER".tar.lz "$SRCDIR" || exit 1
    cd $RDIR/d/m4 || exit 1
	export M4VER=${VERSION:-$(echo m4-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/m4/m4-"$M4VER".tar.xz "$SRCDIR" || exit 1
	cp -v $RDIR/d/m4/m4.glibc228.diff.gz "$SRCDIR" || exit 1
    cd $RDIR/d/automake || exit 1
	export AUTOMAKEVER=${VERSION:-$(echo automake-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/automake/automake-"$AUTOMAKEVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/d/make || exit 1
	export MAKEVER=${VERSION:-$(echo make-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/make/make-"$MAKEVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/l/libmpc || exit 1
	export LIBMPCVER=${VERSION:-$(echo mpc-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/l/libmpc/mpc-"$LIBMPCVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/l/mpfr || exit 1
	export MPFRVER=${VERSION:-$(echo mpfr-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/mpfr/mpfr-"$MPFRVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/l/ncurses || exit 1
	PKGNAM=ncurses && export NCURVER=${VERSION:-$(echo $PKGNAM-*.tar.?z | cut -f 2- -d - | cut -f 1,2 -d .)}
	cp -v $RDIR/l/ncurses/ncurses-"$NCURVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/a/patch || exit 1
	export PATCHVER=${VERSION:-$(echo patch-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/patch/patch-"$PATCHVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/d/python3 || exit 1
	export PYTHVER=${VERSION:-$(echo Python-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/python3/Python-"$PYTHVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/d/perl || exit 1
	export PERLVER=${VERSION:-$(echo perl-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/perl/perl-"$PERLVER".tar.?z "$SRCDIR" || exit 1
    cd $RDIR/a/sed || exit 1
	export SEDVER=${VERSION:-$(echo sed-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/sed/sed-"$SEDVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/tar || exit 1
	export TARVER=${VERSION:-$(echo tar-*.tar.xz | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/tar/tar-"$TARVER".tar.xz "$SRCDIR" || exit 1
    cp -v $RDIR/a/tar/tar-1.13.tar.gz "$SRCDIR" || exit 1
    cp -v $RDIR/a/tar/tar-1.13.bzip2.diff.gz "$SRCDIR" || exit 1
    cd $RDIR/ap/texinfo || exit 1
	export TEXINFOVER=${VERSION:-$(echo texinfo-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/ap/texinfo/texinfo-"$TEXINFOVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/util-linux || exit 1
	export UTILVER=${VERSION:-$(echo util-linux*.tar.xz | cut -d - -f 3  | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/util-linux/util-linux-"$UTILVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/a/which || exit 1
	export WHICHVER=${VERSION:-$(echo which-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/which/which-"$WHICHVER".tar.gz "$SRCDIR" || exit 1
    cd $RDIR/a/xz || exit 1
	export XZVER=${VERSION:-$(echo xz-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/xz/xz-"$XZVER".tar.xz "$SRCDIR" || exit 1
    cd $RDIR/l/zstd || exit 1
	export ZSTDVER=${VERSION:-$(echo zstd-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/zstd/zstd-"$ZSTDVER".tar.?z "$SRCDIR" || exit 1
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

binutils_build_sp1 () {
#*****************************
    tar xvf binutils-"$BINUVER".tar.?z || exit 1 
	cd binutils-"$BINUVER" || exit 1 
    mkdir -v build
	cd build  || exit 1 

    ../configure --prefix=/tools \
    --with-sysroot=$SFS        \
    --with-lib-path=/tools/lib \
    --target="$SFS_TGT"          \
    --disable-nls              \
    --disable-werror || exit 1

    make || exit 1

    case $(uname -m) in
        x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
    esac

    make install || exit 1
    cd ../..
    rm -rf binutils-"$BINUVER"
}

gcc_build_sp1 () {
#*****************************
    tar xvf gcc-"$SRCVER".tar.?z || exit 1  
	cd gcc-"$SRCVER" || exit 1 

    tar xvf ../mpfr-"$MPFRVER".tar.xz
    mv -v mpfr-"$MPFRVER" mpfr
    tar xvf ../gmp-"$GMPVER".tar.?z
    mv -v gmp-"$GMPVER" gmp
    tar xvf ../mpc-"$LIBMPCVER".tar.lz
    mv -v mpc-"$LIBMPCVER" mpc

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

	mkdir -v build 
	cd build || exit 1 

	../configure                                       \
		--target="$SFS_TGT"                              \
		--prefix=/tools                                \
		--with-glibc-version=2.11                      \
		--with-sysroot="$SFS"                            \
		--with-newlib                                  \
		--without-headers                              \
		--with-local-prefix=/tools                     \
		--with-native-system-header-dir=/tools/include \
		--disable-nls                                  \
		--disable-shared                               \
		--disable-multilib                             \
		--disable-decimal-float                        \
		--disable-threads                              \
		--disable-libatomic                            \
		--disable-libgomp                              \
		--disable-libmpx                               \
		--disable-libquadmath                          \
		--disable-libssp                               \
		--disable-libvtv                               \
		--disable-libstdcxx                            \
		--enable-languages=c,c++ || exit 1

	make || exit 1
	make install || exit 1
	cd ../..
	rm -rf gcc-"$SRCVER"
}

linux_headers_build () {
#*****************************
	tar xvf linux-"$LINUXVER".tar.xz || exit 1  
	cd linux-"$LINUXVER" || exit 1 
	make mrproper || exit 1
	make INSTALL_HDR_PATH=dest headers_install || exit 1
	cp -rv dest/include/* /tools/include || exit 1
	cd ..
	rm -rf linux-"$LINUXVER"
	mkdir "$SFS"/tools/etc && touch "$SFS/"tools/etc/tools_version
	echo linux-"$LINUXVER" >> "$SFS"/tools/etc/tools_version
}

glibc_build () {
#*****************************
	tar xvf glibc-"$GLIBCVER".tar.xz || exit 1  
	cd glibc-"$GLIBCVER" || exit 1 

	case "$GLIBCVER" in
		2.30 )
			patch -p1 --verbose < ../e1d559f.patch
			patch -p1 --verbose < ../glibc.git-cba932a5a9e91cffd7f4172d7e91f9b2efb1f84b.patch
			patch -p1 --verbose < ../glibc.git-84df7a4637be8ecb545df3501cc724f3a4d53c46.patch
			patch -p1 --verbose < ../glibc.git-e21a7867713c87d0b0698254685d414d811d72b2.patch
			patch -p1 --verbose < ../glibc.git-70c6e15654928c603c6d24bd01cf62e7a8e2ce9b.patch
			patch -p1 --verbose < ../glibc-2.30-gcc-10.2.patch
			patch -p1 --verbose < ../glibc.8a80ee5e2bab17a1f8e1e78fab5c33ac7efa8b29.patch
			patch -p1 --verbose < ../glibc.b0f6679bcd738ea244a14acd879d974901e56c8e.patch
			patch -p1 --verbose < ../glibc.b6d2c4475d5abc05dd009575b90556bdd3c78ad0.patch
			patch -p1 --verbose < ../glibc.e1df30fbc2e2167a982c0e77a7ebee28f4dd0800.patch ;;
	
		2.31 )
			sed -e '1161 s|^|//|' -i libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc ;;

		2.32 )
			sed -e '1161 s|^|//|' -i libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc ;;

		2.33 )
			echo ;;
	esac

	mkdir -v build
	cd build || exit 1 

	../configure 							 \
		  --prefix=/tools                    \
		  --host="$SFS_TGT"                    \
		  --build="$(../scripts/config.guess)" \
		  --enable-kernel=2.6.32             \
		  --disable-werror                   \
		  --with-headers=/tools/include || exit 1

	make || exit 1
	make install || exit 1
	cd ../..
	rm -rf glibc-"$GLIBCVER"
	echo glibc-"$GLIBCVER" >> "$SFS"/tools/etc/tools_version
}

libstdc_build () {
#*****************************
	tar xf gcc-"$SRCVER".tar.?z || exit 1  
	cd gcc-"$SRCVER" || exit 1 
	mkdir -v build
	cd build || exit 1 

	../libstdc++-v3/configure           \
		--host="$SFS_TGT"                 \
		--prefix=/tools                 \
		--disable-multilib              \
		--disable-nls                   \
		--disable-libstdcxx-threads     \
		--disable-libstdcxx-pch         \
		--with-gxx-include-dir=/tools/"$SFS_TGT"/include/c++/"$GCCVER" || exit 1

	make || exit 1
	make install || exit 1
	cd ../..
	rm -rf gcc-"$SRCVER"
}

binutils_build_sp2 () {
#*****************************
	tar xvf binutils-"$BINUVER".tar.?z || exit 1
	cd binutils-"$BINUVER" || exit 1 
	mkdir -v build
	cd build || exit 1 

	CC="$SFS_TGT"-gcc                \
	AR="$SFS_TGT"-ar                 \
	RANLIB="$SFS_TGT"-ranlib         \
	../configure                   \
		--prefix=/tools            \
		--disable-nls              \
		--disable-werror           \
		--with-lib-path=/tools/lib \
		--with-sysroot || exit 1

	make || exit 1
	make install || exit 1

	make -C ld clean || exit 1
	make -C ld LIB_PATH=/usr/lib:/lib || exit 1
	cp -v ld/ld-new /tools/bin || exit 1

	cd ../..
	rm -rf binutils-"$BINUVER"
	echo binutils-"$BINUVER" >> "$SFS"/tools/etc/tools_version
}

gmp_build () {
#*****************************
    tar xvf gmp-"$GMPVER".tar.?z || exit 1
	cd gmp-"$GMPVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gmp-"$GMPVER"
	echo gmp-"$GMPVER" >> "$SFS"/tools/etc/tools_version
}

isl_build () {
#*****************************
    tar xvf isl-"$ISLVER".tar.xz || exit 1
	cd isl-"$ISLVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf isl-"$ISLVER"
	echo isl-"$ISLVER" >> "$SFS"/tools/etc/tools_version
}

gcc_build_sp2 () {
#*****************************
	tar xvf gcc-"$SRCVER".tar.?z || exit 1
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
    tar xvf ../gmp-"$GMPVER".tar.?z
    mv -v gmp-"$GMPVER" gmp
    tar xvf ../mpc-"$LIBMPCVER".tar.lz
    mv -v mpc-"$LIBMPCVER" mpc

	# fix a problem introduced by glibc-2.31
	sed -e '1161 s|^|//|' -i libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

   	mkdir -v build
	cd build || exit 1 

	CC="$SFS_TGT"-gcc                                    \
	CXX="$SFS_TGT"-g++                                   \
	AR="$SFS_TGT"-ar                                     \
	RANLIB="$SFS_TGT"-ranlib                             \
	../configure                                       \
		 --prefix=/tools                                \
		 --with-local-prefix=/tools                     \
		 --with-native-system-header-dir=/tools/include \
		 --enable-languages=c,c++                       \
		 --disable-libstdcxx-pch                        \
		 --disable-multilib                             \
		 --disable-bootstrap                            \
		 --disable-libgompp || exit 1

    make || exit 1
    make install || exit 1
    ln -sv gcc /tools/bin/cc || exit 1
    cd ../..
    rm -rf gcc-"$SRCVER"
	 echo gcc-"$SRCVER" >> "$SFS"/tools/etc/tools_version
}

gnat_build_sp2 () {
#*****************************
	cd "$SFS"/sources || exit 1 
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

	# fix a problem introduced by glibc-2.31
	 sed -e '1161 s|^|//|' -i libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc

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

m4_build () {
#*****************************
    tar xvf m4-"$M4VER".tar.xz || exit 1
	cd m4-"$M4VER" || exit 1 

	zcat ../m4.glibc228.diff.gz | patch -Esp1 --verbose || exit 1

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf m4-"$M4VER"
	echo m4-"$M4VER" >> "$SFS"/tools/etc/tools_version
}

ncurses_build () {
#*****************************
    tar xvf ncurses-"$NCURVER".tar.lz || exit 1
	cd ncurses-"$NCURVER" || exit 1 
	 
	sed -i s/mawk// configure
    
	./configure --prefix=/tools \
           		 --with-shared  \
            	--without-debug \
            	--without-ada   \
            	--enable-widec  \
            	--enable-overwrite || exit 1

    make || exit 1
    make install || exit 1
    ln -s libncursesw.so /mnt/sfs/tools/lib/libncurses.so
	cd /mnt/sfs/sources || exit 1 
    rm -rf ncurses-"$NCURVER"
	echo ncurses-"$NCURVER" >> "$SFS"/tools/etc/tools_version
}

bash_build () {
#*****************************
    tar xvf bash-"$BASHVER".tar.?z || exit 1
	cd bash-"$BASHVER" || exit 1 

    ./configure --prefix=/tools --without-bash-malloc  || exit 1

    make || exit 1
    make install || exit 1
    ln -sv bash /tools/bin/sh || exit 1
    cd ..
    rm -rf bash-"$BASHVER"
	echo bash-"$BASHVER" >> "$SFS"/tools/etc/tools_version
}

bison_build () {
#*****************************
    tar xvf bison-"$BISONVER".tar.?z || exit 1
	cd bison-"$BISONVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf bison-"$BISONVER"
	echo bison-"$BISONVER" >> "$SFS"/tools/etc/tools_version
}

bzip2_build () {
#*****************************
    tar xvf bzip2-"$BZIP2VER".tar.lz || exit 1
	cd bzip2-"$BZIP2VER" || exit 1 

	make -f Makefile-libbz2_so
	make clean
    make || exit 1
    make PREFIX=/tools install || exit 1
	cp -v bzip2-shared /tools/bin/bzip2
	cp -av libbz2.so* /tools/lib
	ln -sv libbz2.so.1.0 /tools/lib/libbz2.so
    cd ..
    rm -rf bzip2-"$BZIP2VER"
	echo bzip2-"$BZIP2VER" >> "$SFS"/tools/etc/tools_version
}

coreutils_build () {
#*****************************
    tar xvf coreutils-"$COREVER".tar.xz || exit 1
	cd coreutils-"$COREVER" || exit 1 

    ./configure --prefix=/tools --enable-install-program=hostname || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf coreutils-"$COREVER"
	echo coreutils-"$COREVER" >> "$SFS"/tools/etc/tools_version
}

diffutils_build () {
#*****************************
    tar xvf diffutils-"$DIFFVER".tar.xz || exit 1
	cd diffutils-"$DIFFVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf diffutils-"$DIFFVER"
	echo diffutils-"$DIFFVER" >> "$SFS"/tools/etc/tools_version
}

file_build () {
#*****************************
    tar xvf file-"$FILEVER".tar.?z || exit 1
	cd file-"$FILEVER" || exit 1 

	./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf file-"$FILEVER"
	echo file-"$FILEVER" >> "$SFS"/tools/etc/tools_version
}

findutils_build () {
#*****************************
    tar xvf findutils-"$FINDVER".tar.lz || exit 1
	cd findutils-"$FINDVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf findutils-"$FINDVER"
	echo findutils-"$FINDVER" >> "$SFS"/tools/etc/tools_version
}

gawk_build () {
#*****************************
    tar xvf gawk-"$GAWKVER".tar.lz || exit 1
	cd gawk-"$GAWKVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gawk-"$GAWKVER"
	echo gawk-"$GAWKVER" >> "$SFS"/tools/etc/tools_version
}

gettext_build () {
#*****************************
    tar xvf gettext-"$GETTVER".tar.lz || exit 1
	cd gettext-"$GETTVER" || exit 1 

    ./configure --disable-shared || exit 1

    make || exit 1

    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin || exit 1
    cd ..
    rm -rf gettext-"$GETTVER"
	echo gettext-"$GETTVER" >> "$SFS"/tools/etc/tools_version
}

grep_build () {
#*****************************
    tar xvf grep-"$GREPVER".tar.xz || exit 1
	cd grep-"$GREPVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf grep-"$GREPVER"
	echo grep-"$GREPVER" >> "$SFS"/tools/etc/tools_version
}

gzip_build () {
#*****************************
    tar xvf gzip-"$GZIPVER".tar.xz || exit 1
	cd gzip-"$GZIPVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gzip-"$GZIPVER"
	echo gzip-"$GZIPVER" >> "$SFS"/tools/etc/tools_version
}

automake_build () {
#*****************************
    tar xvf automake-"$AUTOMAKEVER".tar.xz || exit 1
	cd automake-"$AUTOMAKEVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1

# links necessary to build "make" with patches

	ln -sf /tools/bin/aclocal /tools/bin/aclocal-1.15
	ln -sf /tools/bin/automake /tools/bin/automake-1.15
    cd ..
    rm -rf automake-"$AUTOMAKEVER"
	echo automake-"$AUTOMAKEVER" >> "$SFS"/tools/etc/tools_version
}

make_build () {
#*****************************
    tar xvf make-"$MAKEVER".tar.?z || exit 1
	cd make-"$MAKEVER" || exit 1 

    ./configure --prefix=/tools --without-guile || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf make-"$MAKEVER"
	echo make-"$MAKEVER" >> "$SFS"/tools/etc/tools_version
}

patch_build () {
#*****************************
    tar xvf patch-"$PATCHVER".tar.xz || exit 1
	cd patch-"$PATCHVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf patch-"$PATCHVER"
	echo patch-"$PATCHVER" >> "$SFS"/tools/etc/tools_version
}

perl_build () {
#*****************************
    tar xvf perl-"$PERLVER".tar.?z || exit 1
	cd perl-"$PERLVER" || exit 1 

    sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth || exit 1
    make || exit 1
    cp -v perl cpan/podlators/scripts/pod2man /tools/bin || exit 1
    mkdir -pv /tools/lib/perl5/"$PERLVER" || exit 1
    cp -Rv lib/* /tools/lib/perl5/"$PERLVER" || exit 1
    cd ..
    rm -rf perl-"$PERLVER"
	echo perl-"$PERLVER" >> "$SFS"/tools/etc/tools_version
}

python_build () {
#*****************************
    tar xvf Python-"$PYTHVER".tar.?z || exit 1
	cd Python-"$PYTHVER" || exit 1 

    sed -i '/def add_multiarch_paths/a \        return' setup.py || exit 1
    ./configure --prefix=/tools --without-ensurepip || exit 1
    make || exit 1
    make install || exit 1
    cd ..
    rm -rf Python-"$PYTHVER"
	echo Python-"$PYTHVER" >> "$SFS"/tools/etc/tools_version
}

sed_build () {
#*****************************
    tar xvf sed-"$SEDVER".tar.xz || exit 1
	cd sed-"$SEDVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf sed-"$SEDVER"
	echo sed-"$SEDVER" >> "$SFS"/tools/etc/tools_version
}

tar_build () {
#*****************************
    tar xvf tar-"$TARVER".tar.xz || exit 1
	cd tar-"$TARVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf tar-"$TARVER"
	echo tar-"$TARVER" >> "$SFS"/tools/etc/tools_version
}

texinfo_build () {
#*****************************
    tar xvf texinfo-"$TEXINFOVER".tar.xz || exit 1
	cd texinfo-"$TEXINFOVER" || exit 1 

	zcat ../texinfo.fix.unescaped.left.brace.diff.gz | patch -p1 --verbose || exit 1

    ./configure --prefix=/tools --disable-perl-xs || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf texinfo-"$TEXINFOVER"
	echo texinfo-"$TEXINFOVER" >> "$SFS"/tools/etc/tools_version
}

util_linux_build () {
#*****************************
    tar xvf util-linux-"$UTILVER".tar.xz || exit 1
	cd util-linux-"$UTILVER" || exit 1 

    ./configure --prefix=/tools    \
    --without-python               \
    --without-ncurses              \
    --disable-makeinstall-chown    \
    --without-systemdsystemunitdir \
    PKG_CONFIG="" || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf util-linux-"$UTILVER"
	echo util-linux-"$UTILVER" >> "$SFS"/tools/etc/tools_version
}

xz_build () {
#*****************************
    tar xvf "xz-$XZVER".tar.xz || exit 1
	cd xz-"$XZVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf xz-"$XZVER"
	echo xz-"$XZVER" >> "$SFS"/tools/etc/tools_version
}

lzip_build () {
#*****************************
    tar xvf lzip-"$LZIPVER".tar.lz || exit 1 
	cd lzip-"$LZIPVER" || exit 1 

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf lzip-"$LZIPVER"
	echo lzip-"$LZIPVER" >> "$SFS"/tools/etc/tools_version
}

tar_slack_build () {
#*****************************
    tar xvf tar-1.13.tar.gz || exit 1 
	cd tar-1.13 || exit 1 

    ./configure --prefix=/usr --disable-nls && zcat ../tar-1.13.bzip2.diff.gz | patch -p1 || exit 1
    make || exit 1
    cd src || exit 1
	mv -v tar tar-1.13
    cp -v tar-1.13 /tools/bin/tar-1.13 || exit 1
    cd ../..
    rm -rf tar-1.13
	echo tar-1.13 >> "$SFS"/tools/etc/tools_version
}

which_build () {
#*****************************
    tar xvf which-"$WHICHVER".tar.gz || exit 1
	cd which-"$WHICHVER" || exit 1 

    ./configure --prefix=/usr || exit 1
    make || exit 1
    cp -v which /tools/bin/which || exit 1
    cd ..
    rm -rf which-"$WHICHVER"
    echo which-"$WHICHVER" >> "$SFS"/tools/etc/tools_version
}

zstd_build () {
#*****************************
    tar xvf zstd-"$ZSTDVER".tar.?z || exit 1
	cd zstd-"$ZSTDVER" || exit 1 

	make || exit 1
	make  -C contrib/pzstd || exit 1

	make prefix=/tools install || exit 1
    cd ..
    rm -rf zstd-"$ZSTDVER"
    echo zstd-"$ZSTDVER" >> "$SFS"/tools/etc/tools_version
}

strip_libs () {
#*****************************
    strip --strip-debug /tools/lib/*
    /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
    rm -rf /tools/{,share}/{info,man,doc}
	find /tools/{lib,libexec} -name \*.la -delete
}

clean_sources () {
#*****************************
echo "clean sources packages"
rm ./*.xz ./*.lz .:*.bz2 ./*.gz
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
ada_choice
copy_src
test_to_go
cd "$SRCDIR" || exit 1 
binutils_build_sp1
gcc_build_sp1
linux_headers_build
glibc_build
libstdc_build
binutils_build_sp2
gmp_build
isl_build
gcc_build_sp2
m4_build
ncurses_build
bash_build
bison_build
bzip2_build
coreutils_build
diffutils_build
file_build
findutils_build
gawk_build
gettext_build
grep_build
gzip_build
automake_build
make_build
patch_build
perl_build
python_build
sed_build
tar_build
texinfo_build
xz_build
lzip_build
tar_slack_build
which_build
util_linux_build
zstd_build
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
