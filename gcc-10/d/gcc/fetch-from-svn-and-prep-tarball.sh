#!/bin/sh
# Copyright 2018, 2019  Patrick J. Volkerding, Sebeka, Minnesota, USA
#
# Parts of this script are based on the gcc_release script by
# Jeffrey Law, Bernd Schmidt, Mark Mitchell.
# Copyright (c) 2001-2015 Free Software Foundation.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

BRANCH=${BRANCH:-gcc-9-branch}

rm -rf tmp-fetch
mkdir tmp-fetch
cd tmp-fetch
# Not sure why, but this emits a different revision when the fetch is done than
# what's returned by "svn log -r COMMITTED". We'll trust the latter.
svn co svn://gcc.gnu.org/svn/gcc/branches/${BRANCH} gcc
cd gcc
echo "Generating LAST_UPDATED..."
svn log -r COMMITTED > LAST_UPDATED.raw
REVISION="$(cat LAST_UPDATED.raw | head -n 2 | tail -n 1 | cut -f 1 -d ' ' | cut -f 2 -d r)"
DATE="$(date -d "$(cat LAST_UPDATED.raw | head -n 2 | tail -n 1 | cut -f 3 -d '|' | cut -f 1 -d '(')" "+%Y%m%d")"
echo "Obtained from SVN: branches/${BRANCH} revision ${REVISION}" > LAST_UPDATED
cat LAST_UPDATED.raw >> LAST_UPDATED
rm LAST_UPDATED.raw
# Remove the .svn data (not packaged):
rm -r .svn
# Get the version number:
VERSION=$(cat gcc/BASE-VER)
# Rename the directory:
cd ..
GCCDIR="gcc-${VERSION}_${DATE}_r${REVISION}"
mv gcc $GCCDIR
cd $GCCDIR
# Now we need to generate some documentation files that would normally be
# created during the GCC release process:
echo "Generating INSTALL/ documentation..."
SOURCEDIR=gcc/doc \
DESTDIR=INSTALL \
gcc/doc/install.texi2html 1> /dev/null 2> /dev/null
echo "Generating NEWS..."
contrib/gennews > NEWS
# Create a "MD5SUMS" file to use for checking the validity of the release.
echo "Generating MD5SUMS..."
echo \
"# This file contains the MD5 checksums of the files in the
# "${GCCDIR}".tar.lz tarball.
#
# Besides verifying that all files in the tarball were correctly expanded,
# it also can be used to determine if any files have changed since the
# tarball was expanded or to verify that a patchfile was correctly applied.
#
# Suggested usage:
# md5sum -c MD5SUMS | grep -v \"OK$\"
#" > MD5SUMS
find . -type f |
sed -e 's:^\./::' -e '/MD5SUMS/d' |
sort |
xargs md5sum >>MD5SUMS
cd ..
# Tar it up:
echo "Creating ${GCCDIR}.tar..."
tar cf ${GCCDIR}.tar ${GCCDIR}
# Compress with (p)lzip:
echo "Compressing ${GCCDIR}.tar.lz..."
plzip -9 ${GCCDIR}.tar
# Move the new archive up a directory:
mv ${GCCDIR}.tar.lz ..
# Move up a directory and then delete the cruft:
cd ..
rm -r tmp-fetch
echo "Done."
