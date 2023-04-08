#!/bin/sh
# Repacks the ghostscript tarball to remove old unmaintained libraries.
# The SlackBuild would remove them before building anyway, but this way
# we don't waste bandwidth and storage on useless junk.

VERSION=${VERSION:-$(echo ghostscript-*.tar.?z* | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}

tar xf ghostscript-${VERSION}.tar.xz || exit 1
mv ghostscript-${VERSION}.tar.xz ghostscript-${VERSION}.tar.xz.orig
( cd ghostscript-${VERSION} && rm -rf freetype jpeg lcms2 lcms2art/doc/* libpng libtiff png tiff zlib )
# Dump huge PDFs:
( cd ghostscript-${VERSION}
  find . -name GS9_Color_Management.pdf -exec rm {} \;
  rm -f doc/colormanage/figures/*.pdf
  rm -f lcms2mt/doc/*
)
tar cf ghostscript-${VERSION}.tar ghostscript-${VERSION}
rm -r ghostscript-${VERSION}
plzip -9 -n 6 ghostscript-${VERSION}.tar
touch -r ghostscript-${VERSION}.tar.xz.orig ghostscript-${VERSION}.tar.lz
rm ghostscript-${VERSION}.tar.xz.orig
