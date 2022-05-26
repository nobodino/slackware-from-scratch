#!/bin/sh
# Environment variables for the Qt package.
#
# It's best to use the generic directory to avoid
# compiling in a version-containing path:
if [ -d /usr/lib@LIBDIRSUFFIX@/qt5 ]; then
  QT5DIR=/usr/lib@LIBDIRSUFFIX@/qt5
else
  # Find the newest Qt directory and set $QT5DIR to that:
  for qtd in /usr/lib@LIBDIRSUFFIX@/qt5-* ; do
    if [ -d $qtd ]; then
      QT5DIR=$qtd
    fi
  done
fi
PATH="$PATH:$QT5DIR/bin"
export QT5DIR
# Unfortunately Chromium and derived projects (including QtWebEngine) seem
# to be suffering some bitrot when it comes to 32-bit support, so we are
# forced to disable the seccomp filter sandbox on 32-bit or else all of these
# applications crash. If anyone has a patch that gets these things running on
# 32-bit without this workaround, please let volkerdi or alienBOB know, or
# post your solution on LQ. Thanks. :-)
if file /bin/cat | grep -wq 32-bit ; then
  export QTWEBENGINE_CHROMIUM_FLAGS="--disable-seccomp-filter-sandbox"
fi
