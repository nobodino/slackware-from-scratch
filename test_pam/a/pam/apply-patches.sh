set -e -o pipefail

SBO_PATCHDIR=${CWD}/patches

# patch -p0 -E --backup --verbose -i ${SBO_PATCHDIR}/${PKGNAM}.patch


# Set to YES if autogen is needed
SBO_AUTOGEN=NO

set +e +o pipefail
