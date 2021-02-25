#!/bin/bash

# Copyright 2019  Patrick J. Volkerding, Sebeka, Minnesota, USA
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

# Clear out any existing build deps:
rm -rf $TMP/mozilla-firefox-build-deps
mkdir -p $TMP/mozilla-firefox-build-deps
# This will be at the beginning of the $PATH, so protect against nonsense
# happening in /tmp:
chmod 700 $TMP/mozilla-firefox-build-deps
PATH=$TMP/mozilla-firefox-build-deps/usr/bin:$HOME/.cargo/bin:$PATH

# cbindgen is a build-time dependency:
( cd $CWD/build-deps/cbindgen ; ./cbindgen.build ) || exit 1

if /bin/ls build-deps*.txz 1> /dev/null 2> /dev/null ; then # use prebuilt autoconf/nodejs
  ( cd $TMP/mozilla-firefox-build-deps ; tar xf $CWD/build-deps*.txz )
else
  # We need to use the incredibly ancient autoconf-2.13 for this  :/
  ( cd $CWD/build-deps/autoconf ; ./autoconf.build ) || exit 1
  # And node.js... WHY
  ( cd $CWD/build-deps/nodejs ; ./nodejs.build ) || exit 1
fi
