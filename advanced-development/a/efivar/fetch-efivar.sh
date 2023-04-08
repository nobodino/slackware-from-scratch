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
rm -rf efivar

# Clone repository:
git clone https://github.com/rhboot/efivar

# checkout $BRANCH:
( cd efivar 
  git checkout $BRANCH || exit 1
)

HEADISAT="$( cd efivar && git log -1 --format=%h )"
DATE="$( cd efivar && git log -1 --format=%cd --date=format:%Y%m%d )"
LONGDATE="$( cd efivar && git log -1 --format=%cd --date=format:%c )"
# Cleanup.  We're not packing up the whole git repo.
( cd efivar && find . -type d -name ".git*" -exec rm -rf {} \; 2> /dev/null )
mv efivar efivar-${DATE}_${HEADISAT}
tar cf efivar-${DATE}_${HEADISAT}.tar efivar-${DATE}_${HEADISAT}
xz -9 -f efivar-${DATE}_${HEADISAT}.tar
rm -rf efivar-${DATE}_${HEADISAT}
touch -d "$LONGDATE" efivar-${DATE}_${HEADISAT}.tar.xz
echo
echo "efivar branch $BRANCH with HEAD at $HEADISAT packaged as efivar-${DATE}_${HEADISAT}.tar.xz"
echo
