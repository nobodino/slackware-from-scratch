#!/bin/bash

# Copyright 2021  Heinz Wiesinger, Amsterdam, The Netherlands
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

BRANCH="5.15.3"

rm -f qt-everywhere-src-*.tar*

git clone https://invent.kde.org/qt/qt/qt5.git

cd qt5
  git checkout kde/5.15
  ./init-repository

  for i in $(find . -type d -name "qt*" -maxdepth 1); do
    cd $i
      ../qtbase/bin/syncqt.pl -version $BRANCH
    cd ..
  done

  # Not in the release tarball for 5.15.2
  rm -rf qtqa qtrepotools qtsystems qtpim qtfeedback qtdocgallery qtcanvas3d
  rm -rf qtdatavis3d/tools qtcharts/tools
  rm -f init-repository README.git .commit-template

  VERSION="${BRANCH}_$(git log --format="%ad_%h" --date=short | head -n 1 | tr -d -)"
  LONGDATE="$(git log -1 --format=%cd --date=format:%c )"

cd ..

mv qt5 qt-everywhere-src-$VERSION

tar --exclude-vcs -cf qt-everywhere-src-$VERSION.tar qt-everywhere-src-$VERSION
tar -cf qt5-gitmodules.tar qt-everywhere-src-$VERSION/**/.gitmodules qt-everywhere-src-$VERSION/.gitmodules
tar --concatenate --file=qt-everywhere-src-$VERSION.tar qt5-gitmodules.tar
plzip -9 -v qt-everywhere-src-$VERSION.tar
touch -d "$LONGDATE" qt-everywhere-src-$VERSION.tar.lz

rm -rf qt-everywhere-src-$VERSION
rm -f qt5-gitmodules.tar
