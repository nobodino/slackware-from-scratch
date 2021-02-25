# This script uses the SOURCE file downloaded from:
# archive.mozilla.org:/pub/firefox/releases/{VERSION}

CWD=$(pwd)

if [ ! -r SOURCE ]; then
  echo "Error: no SOURCE file present."
  echo "  download one from archive.mozilla.org:/pub/firefox/releases/{VERSION} and run this script again."
  exit 1
fi

REPO_URL=$(grep tar.bz2 SOURCE | rev | cut -f 1 -d ' ' | rev)
REPO_TARBALL=$(basename ${REPO_URL})
rm -f ${REPO_TARBALL}
rm -f firefox-*.source.tar.lz
lftpget ${REPO_URL} || exit 1
TMPDIR=$(mktemp -d)
cd ${TMPDIR}
tar xf ${CWD}/${REPO_TARBALL}
FF_VER=$(cat mozilla-release-*/browser/config/version.txt)
mv mozilla-release-* firefox-${FF_VER}
tar cf firefox-${FF_VER}.source.tar firefox-${FF_VER}
plzip -9 -n 6 firefox-${FF_VER}.source.tar
cd ${CWD}
mv ${TMPDIR}/firefox-${FF_VER}.source.tar.lz .
rm -f ${REPO_TARBALL}
rm -rf ${TMPDIR}
