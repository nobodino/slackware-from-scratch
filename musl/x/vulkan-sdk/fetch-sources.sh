#!/bin/sh

# Copyright 2017, 2018  Patrick J. Volkerding, Sebeka, Minnesota, USA
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

# Call this script with the version of the Vulkan-LoaderAndValidationLayers-sdk
# that you would like to fetch the sources for. This will fetch the SDK from
# github, and then look at the revisions listed in the external_revisions
# directory to fetch the proper glslang, SPIRV-Headers, and SPIRV-Tools.
#
# Example:  VERSION=1.1.92.1 ./fetch-sources.sh

VERSION=${VERSION:-1.2.162.2}
BRANCH=${BRANCH:-sdk-1.2.162}

rm -rf Vulkan-*-*.tar.?z glslang* SPIRV-Tools* SPIRV-Headers* \
	Vulkan-Headers-sdk-${VERSION}* \
	Vulkan-ValidationLayers-sdk-${VERSION}* \
	Vulkan-Loader-sdk-${VERSION}* \
	Vulkan-Tools-sdk-${VERSION}*


git clone -b "$BRANCH" --single-branch https://github.com/KhronosGroup/Vulkan-Headers.git Vulkan-Headers-sdk-${VERSION}
rm -rf Vulkan-Headers-sdk-${VERSION}/.git
tar cf Vulkan-Headers-sdk-${VERSION}.tar Vulkan-Headers-sdk-${VERSION}
rm -rf Vulkan-Headers-sdk-${VERSION}
plzip -9 Vulkan-Headers-sdk-${VERSION}.tar

git clone -b "$BRANCH" --single-branch https://github.com/KhronosGroup/Vulkan-ValidationLayers.git Vulkan-ValidationLayers-sdk-${VERSION}
rm -rf Vulkan-ValidationLayers-sdk-${VERSION}/.git
tar cf Vulkan-ValidationLayers-sdk-${VERSION}.tar Vulkan-ValidationLayers-sdk-${VERSION}
rm -rf Vulkan-ValidationLayers-sdk-${VERSION}
# Put this here since python's tarfile.open doesn't like tar.lz:
GLSLANG_COMMIT=$(python3 - << EOF
import json
import tarfile
with tarfile.open('Vulkan-ValidationLayers-sdk-$VERSION.tar') as layers:
        known_good = layers.extractfile('Vulkan-ValidationLayers-sdk-${VERSION}/scripts/known_good.json')
        known_good_info = json.loads(known_good.read())
glslang = next(repo for repo in known_good_info['repos'] if repo['name'] == 'glslang')
print(glslang['commit'])
EOF
)
# Now it's safe to compress:
plzip -9 Vulkan-ValidationLayers-sdk-${VERSION}.tar

git clone -b "$BRANCH" --single-branch https://github.com/KhronosGroup/Vulkan-Loader.git Vulkan-Loader-sdk-${VERSION}
rm -rf Vulkan-Loader-sdk-${VERSION}/.git
tar cf Vulkan-Loader-sdk-${VERSION}.tar Vulkan-Loader-sdk-${VERSION}
rm -rf Vulkan-Loader-sdk-${VERSION}
plzip -9 Vulkan-Loader-sdk-${VERSION}.tar

git clone -b "$BRANCH" --single-branch https://github.com/KhronosGroup/Vulkan-Tools.git Vulkan-Tools-sdk-${VERSION}
rm -rf Vulkan-Tools-sdk-${VERSION}/.git
tar cf Vulkan-Tools-sdk-${VERSION}.tar Vulkan-Tools-sdk-${VERSION}
rm -rf Vulkan-Tools-sdk-${VERSION}
plzip -9 Vulkan-Tools-sdk-${VERSION}.tar

git clone https://github.com/KhronosGroup/glslang.git
cd glslang || exit
git checkout "$GLSLANG_COMMIT"
GLSLANG_VERSION=$(git rev-parse --short HEAD)
rm -rf .git
cd ..

mv glslang "glslang-$GLSLANG_VERSION"

SPIRV_TOOLS_COMMIT=$(python3 - << EOF
import json
with open('glslang-$GLSLANG_VERSION/known_good.json') as f:
	known_good = json.load(f)
tools = next(commit for commit in known_good['commits'] if commit['name'] == 'spirv-tools')
print(tools['commit'])
EOF
)

git clone https://github.com/KhronosGroup/SPIRV-Tools.git
cd SPIRV-Tools || exit
git checkout "$SPIRV_TOOLS_COMMIT"
SPIRV_TOOLS_VERSION="$(git rev-parse --short HEAD)"
rm -rf .git
cd ..
mv SPIRV-Tools SPIRV-Tools-$SPIRV_TOOLS_VERSION
tar cf SPIRV-Tools-$SPIRV_TOOLS_VERSION.tar SPIRV-Tools-$SPIRV_TOOLS_VERSION
rm -rf SPIRV-Tools-$SPIRV_TOOLS_VERSION
plzip -9 SPIRV-Tools-$SPIRV_TOOLS_VERSION.tar

SPIRV_HEADERS_COMMIT=$(python3 - << EOF
import json
with open('glslang-$GLSLANG_VERSION/known_good.json') as f:
	known_good = json.load(f)
name = 'spirv-tools/external/spirv-headers'
headers = next(commit for commit in known_good['commits'] if commit['name'] == name)
print(headers['commit'])
EOF
)

git clone https://github.com/KhronosGroup/SPIRV-Headers.git
cd SPIRV-Headers || exit
git checkout "$SPIRV_HEADERS_COMMIT"
SPIRV_HEADERS_VERSION="$(git rev-parse --short HEAD)"
rm -rf .git
cd ..
mv SPIRV-Headers SPIRV-Headers-$SPIRV_HEADERS_VERSION
tar cf SPIRV-Headers-$SPIRV_HEADERS_VERSION.tar SPIRV-Headers-$SPIRV_HEADERS_VERSION
rm -rf SPIRV-Headers-$SPIRV_HEADERS_VERSION
plzip -9 SPIRV-Headers-$SPIRV_HEADERS_VERSION.tar

tar cf glslang-$GLSLANG_VERSION.tar glslang-$GLSLANG_VERSION
rm -rf glslang-$GLSLANG_VERSION
plzip -9 glslang-$GLSLANG_VERSION.tar
