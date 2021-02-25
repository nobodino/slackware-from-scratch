#!/bin/sh
#
# Copyright 2015  Patrick J. Volkerding, Sebeka, MN, USA
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

# Show libraries that are only present in the aaa_elflibs that is currently
# installed on the system.

cleanup() {
  rm -r $TMPDIR
}

trap 'cleanup' 2 14 15          # trap CTRL+C and kill

TMPDIR="$(mktemp -d /tmp/find-aaaelfliborphans.XXXXXX)"

cp -a /var/log/packages/* $TMPDIR
rm -f $TMPDIR/aaa_elflibs-*
cat /var/log/packages/aaa_elflibs-* | grep -v -e PACKAGE -e aaa_elflibs: -e FILE -e '^\./$' -e install/ | grep -v '/$' | while read file ; do
  if ! grep -q $file $TMPDIR/* ; then
    echo $file
  fi
done

cleanup

