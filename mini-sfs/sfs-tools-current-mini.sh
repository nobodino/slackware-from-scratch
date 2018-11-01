####################### sfs-tools-current-mini.sh ##############################
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
# Note: Much of this script is inspired from the LFS manual chapter 5
#       Copyright © 1999-2018 Gerard Beekmans and may be
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
#-------------------------------------------------------------------------
#
# Revision 	0 		25072016		nobodino
# Revision	1		28072016		nobodino
#		-add dialog box before beginning to build
#		-add md5sum for each slackware package
#		-test integrity of each package
#	Revision	2		30072016		nobodino
#		-cosmetic: used 'beautify_bash' to indent
#--------------------------------------------------------------------------
# 	Slackware-14.2 released. New revision will be for slackware-current > 14.2
#--------------------------------------------------------------------------
#	Revision	3		27082016		nobodino
#		-build tools for current (> 14.2)
#	Revision 4		25092016		nobodino
#		-change lfs to sfs
#		-updated to bash-4.4, linux-4.4.22, gawk-4.1.4,
#		texinfo-6.3, and util-linux-2.28.2
#	Revision 5		29092016		nobodino
#		-remove test_integrity (simplification)
#		-update to mpfr-3.1.5 doesn't work, so keep mpfr-3.1.4)
#	Revision 6		27022017		nobodino
#		-updated to LFS-8.0 and most up to date packages
#	Revision 7		27052017		nobodino
#		-updated to LFS-8.0 and most up to date packages
#		-glibc-2.25, gcc-7.1.0
#		-created $PRGVER for each package
#		-created tools_version which summurizes the packages used
#	Revision 8		16062017		nobodino
#		-added cmake, llvm and rust
#	Revision 9		21012018		nobodino
#		-modified diffutils build (removed sed line)
#		-added patch to glibc
#	Revision 10		02022018		nobodino
#		-removed rust (didn't work)
#	Revision 11		18022018		nobodino
#		-now sub-script of sfs-bootstrap.sh
#		-no more external variable script (self suffisant)
#	Revision 12		22022018		nobodino
#		-added bison and reordered according to LFS-8.1 chapter 5
#	Revision 13		27032018		nobodino
#		-modified for ncurses-6.1
#		-removed date version for SFS boostrap comparison
#	Revision 14		13042018		nobodino
#		-added ada_build for gcc (need isl-0.19)
#	Revision 15		09052018		nobodino
#		-modified ada build
#		-modified strip_libs
#	Revision 16			03072018		nobodino
#		-colorized the script
#		-disabled ada build
#		-modified GCCVER for gcc-8.1.1
#
#	Above july 2018, revisions made through github project: https://github.com/nobodino/slackware-from-scratch 
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
	cp -v $RDIR/a/bash/bash-$BASHVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/d/binutils
	export BINUVER=${VERSION:-$(echo binutils-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/binutils/binutils-$BINUVER.tar.lz $SRCDIR || exit 1
    cd $RDIR/d/bison
	export BISONVER=${VERSION:-$(echo bison-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/d/bison/bison-$BISONVER.tar.?z $SRCDIR || exit 1
    cd $RDIR/a/bzip2
	export BZIP2VER=${VERSION:-$(echo bzip2-*.tar.?z* | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}
    cp -v $RDIR/a/bzip2/bzip2-$BZIP2VER.tar.gz $SRCDIR || exit 1
    cd $RDIR/a/coreutils
	export COREVER=${VERSION:-$(echo coreutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/coreutils/coreutils-$COREVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/ap/diffutils
	export DIFFVER=${VERSION:-$(echo diffutils-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/ap/diffutils/diffutils-$DIFFVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/file
	export FILEVER=${VERSION:-$(echo file-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/file/file-$FILEVER.tar.?z $SRCDIR || exit 1
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
    cp -v $RDIR/l/gmp/gmp-$GMPVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/grep
	export GREPVER=${VERSION:-$(echo grep-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/grep/grep-$GREPVER.tar.xz $SRCDIR || exit 1
    cd $RDIR/a/gzip
	export GZIPVER=${VERSION:-$(echo gzip-*.tar.?z | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/a/gzip/gzip-$GZIPVER.tar.xz $SRCDIR || exit 1
	cp -v $RDIR/a/gzip/gzip.glibc228.diff.gz $SRCDIR || exit 1
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
	export MAKEVER=${VERSION:-$(echo make-*.tar.?z2 | cut -d - -f 2 | rev | cut -f 3- -d . | rev)}
    cp -v $RDIR/d/make/make-$MAKEVER.tar.bz2 $SRCDIR || exit 1
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
    tar xvf ../gmp-$GMPVER.tar.xz
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
    tar xvf gmp-$GMPVER.tar.xz && cd gmp-$GMPVER

    ./configure --prefix=/tools || exit 1

    make || exit 1
    make install || exit 1
    cd ..
    rm -rf gmp-$GMPVER
	echo gmp-$GMPVER >> $SFS/tools/etc/tools_version
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
    tar xvf ../gmp-$GMPVER.tar.xz
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
    cd /mnt/sfs/tools/lib && ln -sf libncursesw.so libcursesw.so
	cd /mnt/sfs/sources
    rm -rf ncurses-$NCURVER
	echo ncurses-$NCURVER >> $SFS/tools/etc/tools_version
}

bash_build () {
#*****************************
    tar xvf bash-$BASHVER.tar.xz && cd bash-$BASHVER

    ./configure --prefix=/tools --without-bash-malloc || exit 1

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
    tar xvf bzip2-$BZIP2VER.tar.gz && cd bzip2-$BZIP2VER

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

# 	patch to build with glibc-2.28 (from LFS)
	sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
	sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
	echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

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

    cd gettext-tools
    EMACS="no" ./configure --prefix=/tools --disable-shared || exit 1

    make -C gnulib-lib || exit 1
    make -C intl pluralx.c || exit 1
    make -C src msgfmt || exit 1
    make -C src msgmerge || exit 1
    make -C src xgettext || exit 1

    cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin || exit 1
    cd ../..
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
	
	zcat ../gzip.glibc228.diff.gz | patch -Esp1 --verbose || exit 1

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
    tar xvf make-$MAKEVER.tar.bz2 && cd make-$MAKEVER

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

    sh Configure -des -Dprefix=/tools -Dlibs=-lm || exit 1
    make || exit 1
    cp -v perl cpan/podlators/scripts/pod2man /tools/bin || exit 1
    mkdir -pv /tools/lib/perl5/$PERLVER || exit 1
    cp -Rv lib/* /tools/lib/perl5/$PERLVER || exit 1
    cd ..
    rm -rf perl-$PERLVER
	echo perl-$PERLVER >> $SFS/tools/etc/tools_version
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
	echo tar-1.13.bzip2.diff.gz >> $SFS/tools/etc/tools_version
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
sed_build
tar_build
texinfo_build
util_linux_build
xz_build
lzip_build
tar_slack_build
which_build
strip_libs
clean_sources
echo_end
exit 0




