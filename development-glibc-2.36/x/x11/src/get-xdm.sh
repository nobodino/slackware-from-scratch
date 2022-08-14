#!/bin/sh

# Copyright 2016, 2020  Patrick J. Volkerding, Sebeka, Minnesota, USA
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

# Pull a stable branch + patches
BRANCH=${1:-master}

# Clear download area:
rm -rf xdm

# Clone repository:
git clone git://anongit.freedesktop.org/git/xorg/app/xdm

# checkout $BRANCH:
( cd xdm 
  git checkout $BRANCH || exit 1
)

HEADISAT="$( cd xdm && git log -1 --format=%h )"
DATE="$( cd xdm && git log -1 --format=%cd --date=format:%Y%m%d )"
LONGDATE="$( cd xdm && git log -1 --format=%cd --date=format:%c )"
# Cleanup.  We're not packing up the whole git repo.
( cd xdm && find . -type d -name ".git*" -exec rm -rf {} \; 2> /dev/null )
cd xdm && ./autogen.sh && rm -rf autom4te.cache && cd ..
mv xdm xdm-${DATE}_${HEADISAT}
tar cf xdm-${DATE}_${HEADISAT}.tar xdm-${DATE}_${HEADISAT}
xz -9 -f xdm-${DATE}_${HEADISAT}.tar
rm -rf xdm-${DATE}_${HEADISAT}
touch -d "$LONGDATE" xdm-${DATE}_${HEADISAT}.tar.xz
echo
echo "xdm branch $BRANCH with HEAD at $HEADISAT packaged as xdm-${DATE}_${HEADISAT}.tar.xz"
echo
