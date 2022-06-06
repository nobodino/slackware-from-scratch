#!/bin/sh

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

# Pull a stable branch + patches
BRANCH=${1:-master}

# Clear download area:
rm -rf libimobiledevice-glue

# Clone repository:
git clone https://github.com/libimobiledevice/libimobiledevice-glue

# checkout $BRANCH:
( cd libimobiledevice-glue
  git checkout $BRANCH || exit 1
)

HEADISAT="$( cd libimobiledevice-glue && git log -1 --format=%h )"
DATE="$( cd libimobiledevice-glue && git log -1 --format=%cd --date=format:%Y%m%d )"
LONGDATE="$( cd libimobiledevice-glue && git log -1 --format=%cd --date=format:%c )"
# Cleanup.  We're not packing up the whole git repo.
( cd libimobiledevice-glue && find . -type d -name ".git*" -exec rm -rf {} \; 2> /dev/null )
mv libimobiledevice-glue libimobiledevice-glue-${DATE}_${HEADISAT}
tar cf libimobiledevice-glue-${DATE}_${HEADISAT}.tar libimobiledevice-glue-${DATE}_${HEADISAT}
xz -9 -f libimobiledevice-glue-${DATE}_${HEADISAT}.tar
rm -rf libimobiledevice-glue-${DATE}_${HEADISAT}
touch -d "$LONGDATE" libimobiledevice-glue-${DATE}_${HEADISAT}.tar.xz
echo
echo "libimobiledevice-glue branch $BRANCH with HEAD at $HEADISAT packaged as libimobiledevice-glue-${DATE}_${HEADISAT}.tar.xz"
echo
