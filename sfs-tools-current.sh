############ sfs-tools-current-with-ada-builtin.sh #############################
#!/bin/bash
#
# Copyright 2018,2019,2020  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018,2019,2020  "nobodino", Bordeaux, FRANCE
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
export MAKEFLAGS='-j 8'
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

copy_src () {
#*****************************
    cd $RDIR/a/bash/
	export BASHVER=${VERSION:-$(echo bash-*.tar.?z* | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
	cp -v $RDIR/a/bash/bash-$BASHVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/d/binutils
	export BINUVER=${VERSION:-$(echo binutils-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/binutils/binutils-$BINUVER.tar.lz $SRCDIR || exit 1
    cd $RDIR/d/bison
	export BISONVER=${VERSION:-$(echo bison-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/bison/bison-$BISONVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/bzip2
	export BZIP2VER=${VERSION:-$(echo bzip2-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/a/bzip2/bzip2-$BZIP2VER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/coreutils
	export COREVER=${VERSION:-$(echo coreutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/coreutils/coreutils-$COREVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/ap/diffutils
	export DIFFVER=${VERSION:-$(echo diffutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/ap/diffutils/diffutils-$DIFFVER.tar.xz $SRCDIR || exit 1
#    cd $RDIR/a/file
#	file-5.38 doesn't work
	cd $SRCDIR && wget -c https://mirror.eu.oneandone.net/linux/distributions/gentoo/gentoo/distfiles/file-5.37.tar.gz
	export FILEVER=${VERSION:-$(echo file-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
#    cp -v $RDIR/a/file/file-$FILEVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/findutils
	export FINDVER=${VERSION:-$(echo findutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/findutils/findutils-$FINDVER.tar.lz $SRCDIR || exit 1
    cd $RDIR/a/gawk
	export GAWKVER=${VERSION:-$(echo gawk-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gawk/gawk-$GAWKVER.tar.lz $SRCDIR || exit 1
    cd $RDIR/d/gcc
	export SRCVER=${VERSION:-$(echo gcc-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
	export GCCVER=$(echo $SRCVER | cut -f 1 -d _)
    cp -v $RDIR/d/gcc/gcc-$SRCVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/gettext
	export GETTVER=${VERSION:-$(echo gettext-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gettext/gettext-$GETTVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/l/glibc
	export GLIBCVER=${VERSION:-$(echo glibc-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/glibc/glibc-$GLIBCVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/l/gmp
	export GMPVER=${VERSION:-$(echo gmp-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/gmp/gmp-$GMPVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/l/isl
	export ISLVER=${VERSION:-$(echo isl-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
	cp -v $RDIR/l/isl/isl-$ISLVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/grep
	export GREPVER=${VERSION:-$(echo grep-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/grep/grep-$GREPVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/gzip
	export GZIPVER=${VERSION:-$(echo gzip-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gzip/gzip-$GZIPVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/k
	export LINUXVER=${VERSION:-$(echo linux-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/k/linux-$LINUXVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/lzip
	export LZIPVER=${VERSION:-$(echo lzip-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/lzip/lzip-$LZIPVER.tar.lz $SRCDIR || exit 1
    cd $RDIR/d/m4
	export M4VER=${VERSION:-$(echo m4-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/m4/m4-$M4VER.tar.xz $SRCDIR || exit 1
	cp -v $RDIR/d/m4/m4.glibc228.diff.gz $SRCDIR || exit 1
    cd $RDIR/d/automake
	export AUTOMAKEVER=${VERSION:-$(echo automake-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/automake/automake-$AUTOMAKEVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/d/make
	export MAKEVER=${VERSION:-$(echo make-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/make/make-$MAKEVER.tar.?z $SRCDIR || exit 1
    cp -v $RDIR/d/make/make.glibc-2.27.glob.diff.gz $SRCDIR || exit 1
    cp -v $RDIR/d/make/b552b05251980f693c729e251f93f5225b400714.patch.gz $SRCDIR || exit 1
    cd $RDIR/l/libmpc
	export LIBMPCVER=${VERSION:-$(echo libpmc-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/libmpc/mpc-$LIBMPCVER.tar.lz $SRCDIR || exit 1
    cd $RDIR/l/mpfr
	export MPFRVER=${VERSION:-$(echo mpfr-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/l/mpfr/mpfr-$MPFRVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/l/ncurses
	PKGNAM=ncurses && export NCURVER=${VERSION:-$(echo $PKGNAM-*.tar.?z | cut -f 2- -d - | cut -f 1,2 -d .)}
	cp -v $RDIR/l/ncurses/ncurses-$NCURVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/patch
	export PATCHVER=${VERSION:-$(echo patch-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/patch/patch-$PATCHVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/d/python3
	export PYTHVER=${VERSION:-$(echo Python-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/python3/Python-$PYTHVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/d/perl
	export PERLVER=${VERSION:-$(echo perl-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/perl/perl-$PERLVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/sed
	export SEDVER=${VERSION:-$(echo sed-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/sed/sed-$SEDVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/tar
	export TARVER=${VERSION:-$(echo tar-*.tar.xz | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/tar/tar-$TARVER.tar.xz $SRCDIR || exit 1
    cp -v $RDIR/a/tar/tar-1.13.tar.gz $SRCDIR || exit 1
    cp -v $RDIR/a/tar/tar-1.13.bzip2.diff.gz $SRCDIR || exit 1
    cd $RDIR/ap/texinfo
	export TEXINFOVER=${VERSION:-$(echo texinfo-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/ap/texinfo/texinfo-$TEXINFOVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/util-linux
	export UTILVER=${VERSION:-$(echo util-linux*.tar.xz | cut -d - -f 3  | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/util-linux/util-linux-$UTILVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/which
	export WHICHVER=${VERSION:-$(echo which-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/which/which-$WHICHVER.tar.gz $SRCDIR || exit 1
    cd $RDIR/a/xz
	export XZVER=${VERSION:-$(echo xz-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/xz/xz-$XZVER.tar.xz $SRCDIR || exit 1
	case $(uname -m) in
		i686 ) 
			if [ -f $RDIR/others/gnat-gpl-2014-x86-linux-bin.tar.gz ]; then
				cd $RDIR/others
				cp -v $RDIR/others/gnat-gpl-2014-x86-linux-bin.tar.gz $SRCDIR || exit 1
			fi
			[ $? != 0 ] && exit 1 ;;
		x86_64 )
			if [ -f $RDIR/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz ]; then
				cd $RDIR/others 
				cp -v $RDIR/others/gnat-gpl-2017-x86_64-linux-bin.tar.gz $SRCDIR || exit 1
			fi
			[ $? != 0 ] && exit 1 ;;
	esac
   
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
    tar xvf binutils-$BINUVER.tar.lz && cd binutils-$BINUVER

    mkdir -v build && cd build

    ../configure --prefix=/tools            \
    --with-sysroot=$SFS        \
    --with-lib-path=/tools/lib \
    --target=$SFS_TGT          \
    --disable-nls              \
    --disable-werror || exit 1

    make || exit 1

    case $(uname -m) in
        x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
    esac

    make install || exit 1
    cd ../..
    rm -rf binutils-$BINUVER
}

gcc_build_sp1 () {
#*****************************
    tar xvf gcc-$SRCVER.tar.?z && cd gcc-$SRCVER

    tar xvf ../mpfr-$MPFRVER.tar.xz
    mv -v mpfr-$MPFRVER mpfr
    tar xvf ../gmp-$GMPVER.tar.?z
    mv -v gmp-$GMPVER gmp
    tar xvf ../mpc-$LIBMPCVER.tar.lz
    mv -v mpc-$LIBMPCVER mpc

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

	mkdir -v build && cd build

	../configure                                       \
		--target=$SFS_TGT                              \
		--prefix=/tools                                \
		--with-glibc-version=2.11                      \
		--with-sysroot=$SFS                            \
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
	rm -rf gcc-$SRCVER
}

linux_headers_build () {
#*****************************
	tar xvf linux-$LINUXVER.tar.xz && cd linux-$LINUXVER
	make mrproper || exit 1
	make INSTALL_HDR_PATH=dest headers_install || exit 1
	cp -rv dest/include/* /tools/include || exit 1
	cd ..
	rm -rf linux-$LINUXVER
	mkdir $SFS/tools/etc && touch $SFS/tools/etc/tools_version
	echo linux-$LINUXVER >> $SFS/tools/etc/tools_version
}

glibc_build () {
#*****************************
	tar xvf glibc-$GLIBCVER.tar.xz && cd glibc-$GLIBCVER

    zcat ../glibc.libc.texinfo.no.utf8.patch.gz | patch -p1 --verbose || exit 1

	mkdir -v build && cd build

	../configure                             \
		  --prefix=/tools                    \
		  --host=$SFS_TGT                    \
		  --build=$(../scripts/config.guess) \
		  --enable-kernel=2.6.32             \
		  --with-headers=/tools/include      \
		  libc_cv_forced_unwind=yes          \
		  libc_cv_c_cleanup=yes || exit 1

	make || exit 1
	make install || exit 1
	cd ../..
	rm -rf glibc-$GLIBCVER
	echo glibc-$GLIBCVER >> $SFS/tools/etc/tools_version
}

libstdc_build () {
#*****************************
	tar xf gcc-$SRCVER.tar.?z && cd gcc-$SRCVER

	mkdir -v build && cd build

	../libstdc++-v3/configure           \
		--host=$SFS_TGT                 \
		--prefix=/tools                 \
		--disable-multilib              \
		--disable-nls                   \
		--disable-libstdcxx-threads     \
		--disable-libstdcxx-pch         \
		--with-gxx-include-dir=/tools/$SFS_TGT/include/c++/$GCCVER || exit 1

	make || exit 1
	make install || exit 1
	cd ../..
	rm -rf gcc-$SRCVER
}

binutils_build_sp2 () {
#*****************************
	tar xvf binutils-$BINUVER.tar.lz && cd binutils-$BINUVER

	mkdir -v build && cd build

	CC=$SFS_TGT-gcc                \
	AR=$SFS_TGT-ar                 \
	RANLIB=$SFS_TGT-ranlib         \
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
	rm -rf binutils-$BINUVER
	echo binutils-$BINUVER >> $SFS/tools/etc/tools_version
}

gmp_build () {
#*****************************
    tar xvf gmp-$GMPVER.tar.?z && cd gmp-$GMPVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gmp-$GMPVER
	echo gmp-$GMPVER >> $SFS/tools/etc/tools_version
}

isl_build () {
#*****************************
    tar xvf isl-$ISLVER.tar.xz && cd isl-$ISLVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf isl-$ISLVER
	echo isl-$ISLVER >> $SFS/tools/etc/tools_version
}

gcc_build_sp2 () {
#*****************************
tar xvf gcc-$SRCVER.tar.?z && cd gcc-$SRCVER

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($SFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

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

    tar xvf ../mpfr-$MPFRVER.tar.xz
    mv -v mpfr-$MPFRVER mpfr
    tar xvf ../gmp-$GMPVER.tar.?z
    mv -v gmp-$GMPVER gmp
    tar xvf ../mpc-$LIBMPCVER.tar.lz
    mv -v mpc-$LIBMPCVER mpc

   mkdir -v build && cd build

	CC=$SFS_TGT-gcc                                    \
	CXX=$SFS_TGT-g++                                   \
	AR=$SFS_TGT-ar                                     \
	RANLIB=$SFS_TGT-ranlib                             \
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
    rm -rf gcc-$SRCVER
	 echo gcc-$SRCVER >> $SFS/tools/etc/tools_version
}

gnat_build_sp2 () {
#*****************************
cd $SFS/sources
tar xvf gcc-$SRCVER.tar.xz && cd gcc-$SRCVER

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($SFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

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

    tar xvf ../mpfr-$MPFRVER.tar.xz
    mv -v mpfr-$MPFRVER mpfr
    tar xvf ../gmp-$GMPVER.tar.xz
    mv -v gmp-$GMPVER gmp
    tar xvf ../mpc-$LIBMPCVER.tar.lz
    mv -v mpc-$LIBMPCVER mpc

   mkdir -v build && cd build

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
    tar xvf m4-$M4VER.tar.xz && cd m4-$M4VER

	zcat ../m4.glibc228.diff.gz | patch -Esp1 --verbose || exit 1

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf m4-$M4VER
	echo m4-$M4VER >> $SFS/tools/etc/tools_version
}

ncurses_build () {
#*****************************
    tar xvf ncurses-$NCURVER.tar.lz && cd ncurses-$NCURVER
	 
	 sed -i s/mawk// configure
    
	 ./configure --prefix=/tools \
           		 --with-shared   \
            	--without-debug \
            	--without-ada   \
            	--enable-widec  \
            	--enable-overwrite || exit 1

    make || exit 1
    make install || exit 1
    ln -s libncursesw.so /mnt/sfs/tools/lib/libncurses.so
	cd /mnt/sfs/sources
    rm -rf ncurses-$NCURVER
	echo ncurses-$NCURVER >> $SFS/tools/etc/tools_version
}

bash_build () {
#*****************************
    tar xvf bash-$BASHVER.tar.?z && cd bash-$BASHVER

    ./configure --prefix=/tools --without-bash-malloc  || exit 1

    make || exit 1
    make install || exit 1
    ln -sv bash /tools/bin/sh || exit 1
    cd ..
    rm -rf bash-$BASHVER
	echo bash-$BASHVER >> $SFS/tools/etc/tools_version
}

bison_build () {
#*****************************
    tar xvf bison-$BISONVER.tar.?z && cd bison-$BISONVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf bison-$BISONVER
	echo bison-$BISONVER >> $SFS/tools/etc/tools_version
}

bzip2_build () {
#*****************************
    tar xvf bzip2-$BZIP2VER.tar.lz && cd bzip2-$BZIP2VER

    make || exit 1
    make PREFIX=/tools install || exit 1
    cd ..
    rm -rf bzip2-$BZIP2VER
	echo bzip2-$BZIP2VER >> $SFS/tools/etc/tools_version
}

coreutils_build () {
#*****************************
    tar xvf coreutils-$COREVER.tar.xz && cd coreutils-$COREVER

    ./configure --prefix=/tools --enable-install-program=hostname || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf coreutils-$COREVER
	echo coreutils-$COREVER >> $SFS/tools/etc/tools_version
}

diffutils_build () {
#*****************************
    tar xvf diffutils-$DIFFVER.tar.xz && cd diffutils-$DIFFVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf diffutils-$DIFFVER
	echo diffutils-$DIFFVER >> $SFS/tools/etc/tools_version
}

file_build () {
#*****************************
    tar xvf file-$FILEVER.tar.?z && cd file-$FILEVER

	./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf file-$FILEVER
	echo file-$FILEVER >> $SFS/tools/etc/tools_version
}

findutils_build () {
#*****************************
    tar xvf findutils-$FINDVER.tar.lz && cd findutils-$FINDVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf findutils-$FINDVER
	echo findutils-$FINDVER >> $SFS/tools/etc/tools_version
}

gawk_build () {
#*****************************
    tar xvf gawk-$GAWKVER.tar.lz && cd gawk-$GAWKVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gawk-$GAWKVER
	echo gawk-$GAWKVER >> $SFS/tools/etc/tools_version
}

gettext_build () {
#*****************************
    tar xvf gettext-$GETTVER.tar.xz && cd gettext-$GETTVER

    ./configure --disable-shared || exit 1

    make || exit 1

    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin || exit 1
    cd ..
    rm -rf gettext-$GETTVER
	echo gettext-$GETTVER >> $SFS/tools/etc/tools_version
}

grep_build () {
#*****************************
    tar xvf grep-$GREPVER.tar.xz && cd grep-$GREPVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf grep-$GREPVER
	echo grep-$GREPVER >> $SFS/tools/etc/tools_version
}

gzip_build () {
#*****************************
    tar xvf gzip-$GZIPVER.tar.xz && cd gzip-$GZIPVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gzip-$GZIPVER
	echo gzip-$GZIPVER >> $SFS/tools/etc/tools_version
}

automake_build () {
#*****************************
    tar xvf automake-$AUTOMAKEVER.tar.xz && cd automake-$AUTOMAKEVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1

# links necessary to build "make" with patches

	ln -sf /tools/bin/aclocal /tools/bin/aclocal-1.15
	ln -sf /tools/bin/automake /tools/bin/automake-1.15
    cd ..
    rm -rf automake-$AUTOMAKEVER
	echo automake-$AUTOMAKEVER >> $SFS/tools/etc/tools_version
}

make_build () {
#*****************************
    tar xvf make-$MAKEVER.tar.?z && cd make-$MAKEVER

	zcat ../make.glibc-2.27.glob.diff.gz | patch -p1 --verbose || exit 1
	zcat ../b552b05251980f693c729e251f93f5225b400714.patch.gz | patch -p1 --verbose || exit 1

    ./configure --prefix=/tools --without-guile || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf make-$MAKEVER
	echo make-$MAKEVER >> $SFS/tools/etc/tools_version
}

patch_build () {
#*****************************
    tar xvf patch-$PATCHVER.tar.xz && cd patch-$PATCHVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf patch-$PATCHVER
	echo patch-$PATCHVER >> $SFS/tools/etc/tools_version
}

perl_build () {
#*****************************
    tar xvf perl-$PERLVER.tar.?z && cd perl-$PERLVER

    sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth || exit 1
    make || exit 1
    cp -v perl cpan/podlators/scripts/pod2man /tools/bin || exit 1
    mkdir -pv /tools/lib/perl5/$PERLVER || exit 1
    cp -Rv lib/* /tools/lib/perl5/$PERLVER || exit 1
    cd ..
    rm -rf perl-$PERLVER
	echo perl-$PERLVER >> $SFS/tools/etc/tools_version
}

python_build () {
#*****************************
    tar xvf Python-$PYTHVER.tar.?z && cd Python-$PYTHVER

    sed -i '/def add_multiarch_paths/a \        return' setup.py || exit 1
    ./configure --prefix=/tools --without-ensurepip || exit 1
    make || exit 1
    make install || exit 1
    cd ..
    rm -rf Python-$PYTHVER
	echo Python-$PYTHVER >> $SFS/tools/etc/tools_version
}

sed_build () {
#*****************************
    tar xvf sed-$SEDVER.tar.xz && cd sed-$SEDVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf sed-$SEDVER
	echo sed-$SEDVER >> $SFS/tools/etc/tools_version
}

tar_build () {
#*****************************
    tar xvf tar-$TARVER.tar.xz && cd tar-$TARVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf tar-$TARVER
	echo tar-$TARVER >> $SFS/tools/etc/tools_version
}

texinfo_build () {
#*****************************
    tar xvf texinfo-$TEXINFOVER.tar.xz && cd texinfo-$TEXINFOVER

	zcat ../texinfo.fix.unescaped.left.brace.diff.gz | patch -p1 --verbose || exit 1

    ./configure --prefix=/tools --disable-perl-xs || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf texinfo-$TEXINFOVER
	echo texinfo-$TEXINFOVER >> $SFS/tools/etc/tools_version
}

util_linux_build () {
#*****************************
    tar xvf util-linux-$UTILVER.tar.xz && cd util-linux-$UTILVER

    ./configure --prefix=/tools    \
    --without-python               \
    --without-ncurses              \
    --disable-makeinstall-chown    \
    --without-systemdsystemunitdir \
    PKG_CONFIG="" || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf util-linux-$UTILVER
	echo util-linux-$UTILVER >> $SFS/tools/etc/tools_version
}

xz_build () {
#*****************************
    tar xvf xz-$XZVER.tar.xz && cd xz-$XZVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf xz-$XZVER
	echo xz-$XZVER >> $SFS/tools/etc/tools_version
}

lzip_build () {
#*****************************
    tar xvf lzip-$LZIPVER.tar.lz && cd lzip-$LZIPVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf lzip-$LZIPVER
	echo lzip-$LZIPVER >> $SFS/tools/etc/tools_version
}

tar_slack_build () {
#*****************************
    tar xvf tar-1.13.tar.gz && cd tar-1.13

    ./configure --prefix=/usr --disable-nls && zcat ../tar-1.13.bzip2.diff.gz | patch -p1 || exit 1
    make || exit 1
    cd src && mv -v tar tar-1.13
    cp -v tar-1.13 /tools/bin/tar-1.13 || exit 1
    cd ../..
    rm -rf tar-1.13
	echo tar-1.13 >> $SFS/tools/etc/tools_version
}

which_build () {
#*****************************
    tar xvf which-$WHICHVER.tar.gz && cd which-$WHICHVER

    ./configure --prefix=/usr || exit 1
    make || exit 1
    cp -v which /tools/bin/which || exit 1
    cd ..
    rm -rf which-$WHICHVER
    echo which-$WHICHVER >> $SFS/tools/etc/tools_version
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
rm *.xz *.lz *.bz2 *.gz
}

echo_end () {
#*****************************
    echo "The building of tools for sfs is finished."
    echo
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
    echo "then type:"
	echo
	echo -e "$GREEN" "./chroot_sfs.sh" "$NORMAL"
    echo

}

#*****************************
# core script
#*****************************

echo_begin
copy_src
test_to_go
cd $SRCDIR
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
#*****************************
case $(uname -m) in
	x86_64)
		tar xf gnat-gpl-2017-x86_64-linux-bin.tar.gz
		if [ $? != 0 ]; then
			echo
			echo "Tar extraction of gnat-gpl-2017-x86_64-linux-bin failed."
			echo
		exit 1
		fi
		# Now prepare the environment
		cd gnat-gpl-2017-x86_64-linux-bin

		[ $? != 0 ] && exit 1 ;;
	i686)
		tar xf gnat-gpl-2014-x86-linux-bin.tar.gz
		if [ $? != 0 ]; then
			echo
			echo "Tar extraction of gnat-gpl-2014-x86-linux-bin failed."
			echo
		exit 1
		fi
		# Now prepare the environment
		cd gnat-gpl-2014-x86-linux-bin
		[ $? != 0 ] && exit 1 ;;
esac
mkdir -pv /tools/opt/gnat
make ins-all prefix=/tools/opt/gnat
PATH_HOLD=$PATH && export PATH=/tools/opt/gnat/bin:$PATH_HOLD
echo $PATH
find /tools/opt/gnat -name ld -exec mv -v {} {}.old \;
find /tools/opt/gnat -name ld -exec as -v {} {}.old \;
#*****************************
gnat_build_sp2
strip_libs
clean_sources
echo_end
exit 0



