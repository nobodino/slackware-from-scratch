#!/bin/sh

# Copyright 2017  Patrick J. Volkerding, Sebeka, Minnesota, USA
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

# This is a script to extract the manpages from cmake-*-Linux-x86_64.tar.gz
# and output them as cmake.manpages.tar.xz in the current directory.

rm -rf tmp-manpages
mkdir tmp-manpages
tar xf cmake-*-Linux-x86_64.tar.?z
mv cmake-*-Linux-x86_64/man tmp-manpages
rm -r cmake-*-Linux-x86_64
mkdir tmp-manpages/usr
mv tmp-manpages/man tmp-manpages/usr
chown -R root:root tmp-manpages
cd tmp-manpages
tar cf ../cmake.manpages.tar .
cd ..
lzip -9 -f cmake.manpages.tar
rm -r tmp-manpages
