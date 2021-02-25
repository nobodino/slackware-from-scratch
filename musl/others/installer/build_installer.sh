#!/bin/bash
set +o posix

# $Id: build_installer.sh,v 1.129 2011/04/13 23:03:07 eha Exp eha $
#
# Copyright 2005-2018  Stuart Winter, Surrey, England, UK
# Copyright 2008, 2009, 2010, 2011, 2017  Eric Hameleers, Eindhoven, Netherlands
# Copyright 2011-2020  Patrick Volkerding, Sebeka, MN, USA
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
################################################################################
#
# Script:  build_installer.sh
# Purpose: Build the Slackware installer from scratch (multiple architectures)
# Author:  Stuart Winter <mozes@slackware.com>
#          Eric Hameleers <alien@slackware.com>
#
################################################################################
#
# Notes: [1] If you want to use your own _skeleton_ initrd (containing only
#            the directory layout plus all the scripts) you just make it
#            available as ./sources/initrd/skeleton_initrd.tar.gz
#
#          The script will look for the directory 'sources' first in your
#          working directory, and next in the script's directory (whatever is
#          found in your working directory takes precedence).
#
################################################################################

# INSTALLERVERSION is the Slackware version the installer will advertize!
INSTALLERVERSION=${INSTALLERVERSION:-"15.0"}
PKGNAM=slackware-installer

# Needed to find package names:
shopt -s extglob

# Automatically determine the architecture we're building on:
if [ -z "$ARCH" ]; then
  case "$( uname -m )" in
    i?86) export ARCH=i586 ;;
    arm*) export ARCH=arm ;;
    # Unless $ARCH is already set, use uname -m for all other archs:
       *) export ARCH=$( uname -m ) ;;
  esac
fi

# Make sure that loopback support is loaded, if it is modular.
# Use traditional Q+D methodology...  i.e. shove a stick in it
# Timmy, by the time anyone notices we'll be dead
modprobe loop 1> /dev/null 2> /dev/null

# Path to Slackware source tree:
# (we need this to extract some packages - get libraries and stuff)
SLACKROOT=${SLACKROOT:-/mnt/nfs/door/non-public/slackware-current}

# Where do we look for other stuff this script requires?
SRCDIR=$(cd $(dirname $0); pwd)   # where the script looks for support
CWD=$(pwd)                        # where the script writes files

# A list of modules (just the names, no directory path) that should not
# be included on the installer image.  Typically this is a list of modules used
# with the generic kernel that are not built by the huge kernel:
MODBLACKLIST=$SRCDIR/module-blacklist

# Temporary build locations:
TMP=${TMP:-/tmp/build-$PKGNAM}
PKG=$TMP/package-$PKGNAM

# Firmware for wired network cards we need to add to the installer:
NETFIRMWARE="3com acenic adaptec bnx tigon e100 sun kaweth tr_smctr cxgb3 rtl_nic"

# Safe defaults:
DUMPSKELETON=0    # set to '1' to just create a skeleton initrd tarball
SHOWHELP=0        # Do not show help

# Default actions for the script:
case $ARCH in
  arm*|aarch64)
    ADD_NETMODS=1         # add network modules
    ADD_PCMCIAMODS=1      # add pcmcia modules
    ADD_MANPAGES=1
    COMPRESS_MODS=0       # already compressed in a/kernel-modules.t?z package already
    DISTRODIR=${DISTRODIR:-"slackware"} # below this you find a,ap,d,..,y
    LIBDIRSUFFIX=""       # the default
    RECOMPILE=1           # recompile busybox/dropbear and add new binaries
    SPLIT_INITRD=0        # Do not create separate initrd for each kernel
    USBBOOT=0             # do not build the USB boot image
    EFIBOOT=0             # do not build the EFI boot image
    VERBOSE=1             # show a lot of additional output
                          # The firmware we include by default is only for x86, but
    ADD_NETFIRMWARE=1     # we'll probably want to include some at some stage. For now supply -nf to this script.
    ADD_NANO=1
    ;;
  x86_64)
    ADD_NETMODS=1
    ADD_PCMCIAMODS=1
    ADD_MANPAGES=1
    COMPRESS_MODS=1
    ADD_KMS=1
    DISTRODIR=${DISTRODIR:-"slackware64"} # below this you find a,ap,d,..,y
    LIBDIRSUFFIX=""
    RECOMPILE=1
    SPLIT_INITRD=0
    USBBOOT=1
    EFIBOOT=1
    VERBOSE=1
    ADD_NETFIRMWARE=1     # Include the network card firmware
    ADD_NANO=1
    ;;
  i586)
    ADD_NETMODS=1
    ADD_PCMCIAMODS=1
    ADD_MANPAGES=1
    COMPRESS_MODS=1
    ADD_KMS=1
    DISTRODIR=${DISTRODIR:-"slackware"} # below this you find a,ap,d,..,y
    LIBDIRSUFFIX=""
    RECOMPILE=1
    SPLIT_INITRD=0
    USBBOOT=1
    EFIBOOT=1
    VERBOSE=1
    ADD_NETFIRMWARE=1     # Include the network card firmware
    ADD_NANO=1
    ;;
  *)
    ADD_NETMODS=1         # add network modules
    ADD_PCMCIAMODS=1      # add pcmcia modules
    ADD_MANPAGES=1        # Add preprocessed manpages
    DISTRODIR=${DISTRODIR:-"slackware"} # below this you find a,ap,d,..,y
    COMPRESS_MODS=1       # compress kernel modules
    LIBDIRSUFFIX=""       # the default
    RECOMPILE=0           # re-use binaries from existing initrd and packages
    SPLIT_INITRD=0        # Do not create separate initrd for each kernel
    USBBOOT=0             # do not build the USB boot image
    EFIBOOT=0             # do not build the EFI boot image
    VERBOSE=1             # show a lot of additional output
    ADD_NETFIRMWARE=1     # Include the network card firmware
    ADD_NANO=1
    ;;
esac

# Define the CFLAGS for the known architectures:
case $ARCH in
  arm)     SLKCFLAGS="-O2 -march=armv7-a -mfpu=vfpv3-d16"
           ARCHQUADLET="-gnueabihf" ;;
  aarch64) SLKCFLAGS="-O2"
           ARCHQUADLET="" ;;
  i?86)    SLKCFLAGS="-O2 -march=i586 -mtune=i686"
           ARCHQUADLET="" ;;
  s390*)   SLKCFLAGS="-O2"
           ARCHQUADLET="" ;;
  x86_64)  SLKCFLAGS="-O2 -fPIC"
           ARCHQUADLET="" ;;
esac

# Here is where we take our kernel modules and dependency info from
# (at least one of these must be available):
case $ARCH in
  arm*)
    # What kernel directories are in this installer?
    # This kernel is only here to allow us to build a generic ARM installer image from which
    # the other architectures will be built.  It doesn't matter which kernel this is, as it
    # won't be used: post processing scripts unpack this image, generate a list of standard kernel
    # modules; replace those modules with versions specific to the particular device and supplement
    # the image with any additional requirements for that device.
    KERNELS[0]=armv7
    # The -extraversion (appended to the $KVER) for the KERNELS[*]:
    KEXTRAV[0]="-armv7"
    ;;
  aarch64)
    KERNELS[0]=aarch64
    # The -extraversion (appended to the $KVER) for the KERNELS[*]:
    KEXTRAV[0]="-aarch64"
    ;;
  i?86)
    # What kernel directories are in this installer?
    KERNELS[0]=huge.s
    KERNELS[1]=hugesmp.s
    # The -extraversion (appended to the $KVER) for the KERNELS[*]:
    KEXTRAV[0]=""
    KEXTRAV[1]="-smp"
    ;;
  x86_64)
    # What kernel directories are in this installer?
    KERNELS[0]=huge.s
    # The -extraversion (appended to the $KVER) for the KERNELS[*]:
    KEXTRAV[0]=""
    ;;
esac


# Parse the commandline parameters:
while [ ! -z "$1" ]; do
  case $1 in
    -c|--compressmods)
      COMPRESS_MODS=1
      shift
      ;;
    -h|--help)
      SHOWHELP=1
      shift
      ;;
    -m|--multiple)
      SPLIT_INITRD=1
      shift
      ;;
    -nf|--noaddnetfirmware)
      ADD_NETFIRMWARE=0
      shift
      ;;
    -mn|--manpages)
      ADD_MANPAGES=1
      shift
      ;;
    -n|--netmods)
      ADD_NETMODS=1
      shift
      ;;
    -nc|--no-compressmods)
      COMPRESS_MODS=0
      shift
      ;;
    -ne|--no-nano)
      ADD_NANO=0
      shift
      ;;
    -nn|--no-netmods)
      ADD_NETMODS=0
      shift
      ;;
    -np|--no-pcmciamods)
      ADD_PCMCIAMODS=0
      shift
      ;;
    -nr|--no-recompile)
      RECOMPILE=0
      shift
      ;;
    -nm|--no-multiple)
      SPLIT_INITRD=0
      shift
      ;;
    -nu|--no-usbboot)
      USBBOOT=0
      shift
      ;;
    -p|--pcmciamods)
      ADD_PCMCIAMODS=1
      shift
      ;;
    -q|--quiet)
      VERBOSE=0
      shift
      ;;
    -r|--recompile)
      RECOMPILE=1
      shift
      ;;
    -s|--skeleton)
      DUMPSKELETON=1
      shift
      ;;
    -u|--usbboot)
      USBBOOT=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -I|--initrd)
      INITRDIMG="$(cd $(dirname $2); pwd)/$(basename $2)"
      shift 2
      ;;
    -S|--slackroot)
      SLACKROOT="$2"
      shift 2
      ;;
    -*)
      echo "Unsupported parameter '$1'!"
      exit 1
      ;;
    *)# Do nothing
      shift
      ;;
  esac
done

############### Some house keeping now that we have read the commandline #######

# The location of the initrd.img file
INITRDIMG=${INITRDIMG:-"$SLACKROOT/isolinux/initrd.img"}

# Wildcard expression for the kernel-modules package:
KERNELMODPKG=${KERNELMODPKG:-"${SLACKROOT}/${DISTRODIR}/a/kernel-modules-*.t?z"}
# PCMCIA support tools:
PCMCIAUTILS="${SLACKROOT}/${DISTRODIR}/a/pcmciautils-*.t?z"
# Needed by pcmciautils:
SYSFS="${SLACKROOT}/${DISTRODIR}/a/sysfsutils-*.t?z"

# Wildcard expression for the kernel-firmware package:
KERNELFW_PKG=${KERNELFW_PKG:-"${SLACKROOT}/${DISTRODIR}/a/kernel-firmware-*.t?z"}

# If we only want help, do no pre-processing which may lead to error messages
if [ $SHOWHELP -eq 0 ]; then

  if [ "$($(which id) -u)" != "0" ]; then
    echo "You need to be root to run $(basename $0)."
    exit 1
  fi

  if [ ! -d $SLACKROOT ]; then
    echo "*** I can't find the Slackware package tree $SLACKROOT!"
    exit 1
  fi

  # Determine the kernel version:
  #KVER=$( ls -1 ${KERNELMODPKG} | head -1 | sed -e "s#.*/kernel-modules-\([^-]*\)-.*.t[gblx]z#\1#")
  KVER="$( ls -1 ${KERNELMODPKG} | head -1 | rev | cut -d- -f3 | rev | cut -d_ -f1 )"
  if [ -z "$KVER" ]; then
    echo "*** I can't determine the kernel version!"
    exit 1
  fi
  echo "--- Detected kernel version: '$KVER' ---"

  if [ $VERBOSE -eq 1 ]; then
    VERBOSE1="v"
    VERBOSE2="vv"
    VERBOSE3="vvv"
    VERBOSETXT="--verbose"
    SILENTMAKE=""
  else
    VERBOSE1=""
    VERBOSE2=""
    VERBOSE3=""
    VERBOSETXT=""
    SILENTMAKE="-s"
  fi
fi

############### Display help about command line parameters #####################

basic_usage()
{
cat <<"EOH"
# ----------------------------------------------------------------------------#
$Id: build_installer.sh,v 1.129 2011/04/13 23:03:07 eha Exp eha $
# ----------------------------------------------------------------------------#
EOH

cat <<EOT

Usage: $(basename $0) <parameters>
Parameters:
  -h|--help              Show this help
  -c|--compressmods      Compress the kernel modules inside the initrd.img
  -m|--multiple          Multiple initrd files (for SMP and non-SMP kernels)
  -n|--netmods           Add network modules to the initrd
  -nc|--no-compressmods  Do _not_ compress kernel modules
  -ne|--no-nano          Do _not_ add nano editor
  -nm|--no-multiple      Do _not_ create multiple initrd files
  -nn|--no-netmods       Do _not_ add network modules to the initrd
  -np|--no-pcmciamods    Do _not_ add pcmcia modules to the initrd
  -nr|--no-recompile     Do _not_ recompile /re-add binaries
  -nu|--no-usbboot       Do _not_ create a USB boot image
  -p|--pcmciamods        Add pcmcia modules to the initrd
  -q|--quiet             Be (fairly) quiet during progress
  -r|--recompile         Recompile /re-add binaries (busybox,dropbear as
                         well as any required bin/lib from Slackware packages)
  -s|--skeleton          Stop after creating a skeleton_initrd.tar.gz
                         (which only contains directories and scripts)
  -u|--usbboot           Create a USB boot image
  -v|--verbose           Be (very) verbose during progress
  -I|--initrd <file>     Specify location of the initrd.img file
  -S|--slackroot <dir>   Specify location of the Slackware directory tree

Actions to be taken (ARCH=$ARCH):
EOT

[ $VERBOSE -eq 1 ] && echo "* Be (very) verbose during progress" \
                   || echo "* Be (fairly) quiet during progress"
[ $RECOMPILE -eq 1 ] && echo "* Recompile busybox/dropbear /re-add binaries" \
                     || echo "* Do _not_ recompile /re-add binaries"
[ $ADD_NETMODS -eq 1 ] && echo "* Add network modules to the initrd" \
                       || echo "* Do _not_ add network modules to the initrd"
[ $ADD_PCMCIAMODS -eq 1 ] && echo "* Add pcmcia modules to the initrd" \
                          || echo "* Do _not_ add pcmcia modules to the initrd"
[ $COMPRESS_MODS -eq 1 ] && echo "* Compress all kernel modules" \
                         || echo "* Do _not_ compress kernel modules"
[ $SPLIT_INITRD -eq 1 ] && echo "* Split initrd's for SMP and non-SMP kernels" \
                        || echo "* Do _not_ split the initrd"
[ $USBBOOT -eq 1 ] && echo "* Create a USB boot image" \
                   || echo "* Do _not_ create a USB boot image"

echo
echo -e  "Use Slackware root: \n  $SLACKROOT"
echo -e "Use initrd file: \n  $INITRDIMG"

cat <<EOT

# Note: [1] If you want to build your own specific busybox and dropbear       #
#           instead of using the sources provided by the Slackware tree,      #
#           you should have these sources ready below                         #
#           ./sources/{busybox,dropbear}                                      #
#           Delete the directory if you don't want to use it!                 #
#       [2] If you want to use your own _skeleton_ initrd (containing only    #
#           the directory layout plus all the scripts) you just make it       #
#           available as ./sources/initrd/skeleton_initrd.tar.gz              #
#                                                                             #
#          The script will look for the directory 'sources' first in your     #
#          working directory, and next in the script's directory (whatever is #
#          found in your working directory takes precedence).                 #
# ----------------------------------------------------------------------------#

EOT
}

############### Determine patch level required & apply the patch ################################

# Functions:
# Determine patch level required & apply the patch:
function auto_apply_patch () {
 patchfile=$1

 echo
 echo "***********************************************************"
 echo "** Working on Patch: $patchfile"
 echo "***********************************************************"
 echo

 # Decompress the patch if it's compressed with a known method:
 FTYPE=$( file $patchfile )
 case "$FTYPE" in
    *xz*compressed*)
        xz -dc $patchfile > $TMP/$(basename $patchfile).unpacked
        patchfile=$TMP/$(basename $patchfile).unpacked ;;
    *bzip2*compressed*)
        bzcat -f $patchfile > $TMP/$(basename $patchfile).unpacked
        patchfile=$TMP/$(basename $patchfile).unpacked ;;
    *gzip*compressed*)
        zcat -f $patchfile > $TMP/$(basename $patchfile).unpacked
        patchfile=$TMP/$(basename $patchfile).unpacked ;;
 esac

 # By now the patch is decompressed or wasn't compressed originally.
 #
 # Most patches should not require more levels than this:
 success=0
 for (( pl=0 ; pl<=5 ; pl++ )) ; do
   echo "Patch : $patchfile , trying patch level $pl"
     patch -N --fuzz=20 -t --dry-run -l -p$pl < $patchfile > /dev/null 2>&1 && success=1 && break
   done
 if [ $success = 1 ]; then
    echo "Patch: $patchfile will apply at level $pl"
    patch -N --fuzz=20 --verbose -l -p$pl < $patchfile
    return 0
  else
    echo "Patch: $patchfile failed to apply at levels 0-5"
    return 1
 fi
}

############### Unpack an existing initrd image ################################

unpack_oldinitrd()
{

# This function is called when we are not re-building a new initrd from scratch
# (but need to add modules for a new kernel version for instance):
echo "--- Unpacking the old initrd ---"
mkdir -p -m755 $PKG/$ARCH-installer-filesystem
cd $PKG/$ARCH-installer-filesystem

xzcat -f${VERBOSE1} $INITRDIMG | cpio -di${VERBOSE1}

# Wipe the Kernel modules:
echo "--- Removing old kernel modules ---"
rm -rf lib/modules/*
}

############### Create the Installer's filesystem  #############################

create_installer_fs()
{
# Make the directories required for the filesystem:
echo "--- Creating basic filesystem layout ---"
mkdir -p -m755 $PKG/$ARCH-installer-filesystem
cd $PKG/$ARCH-installer-filesystem
mkdir -p -m755  bin
mkdir -p -m755  dev
mkdir -p -m755  etc/rc.d
mkdir -p -m755  etc/dropbear
mkdir -p -m755  floppy
mkdir -p -m755  lib/modules
[ "$ARCH" = "x86_64" ] && mkdir -p -m755  lib64
mkdir -p -m700  lost+found
mkdir -p -m755  mnt
mkdir -p -m755  proc
mkdir -p -m755  root
mkdir -p -m755  sbin
mkdir -p -m755  sys
mkdir -p -m755  tag
mkdir -p -m1777 tmp
mkdir -p -m755  usr/{bin,sbin,etc,lib/setup,libexec,share/tabset}
mkdir -p -m755  usr/share/terminfo/{c,l,v,x,s}
mkdir -p -m755  var/{mount,setup,run,lib}

ln -sf /mnt/boot boot
ln -sf /var/log/mount cdrom
ln -sf /var/log/mount nfs

( cd etc; touch mtab )
( cd etc; touch mdev.conf )

}

############### Extract skeleton from Slackware installer image ################

extract_skeleton_fs()
{
# Temporary extraction directory:
echo "--- Extracting shell scripts from original initrd ---"
rm -rf $TMP/extract-packages
mkdir -p -m755 $TMP/extract-packages
cd $TMP/extract-packages

# Unpack the real i586/current Slackware initrd.img (or a custom one specified
# with the '-I' parameter):
xzcat -f${VERBOSE1} $INITRDIMG | cpio -di${VERBOSE1}

# Wipe the binaries and x86 specific stuff.  This will leave us with
# just the directories and shell scripts:
echo "--- Removing unwanted binaries and libs ---"
( find . -type f -print0 | xargs -0 file | egrep '(ELF.*)' | awk -F: '{print $1}' | xargs rm -f ) >/dev/null 2>&1
( find . -name '*.a' -type f -print0 | xargs -0 rm -f ) > /dev/null 2>&1
# Wipe the Kernel modules:
rm -rf lib/modules/*
# Wipe firmware:
rm -rf lib/firmware/*
# Wipe udev stuff:
rm -rf lib/udev etc/udev
# Wipe the pci.ids:
rm -f usr/share/hwdata/pci.ids*
# Wipe any unneeded scripts that were installed from packages:
rm -f bin/{ldd,zgrep} sbin/fsck.* sbin/{lvmdump,xfs_check}
# Wipe ncurses stuff:
( find usr/share/terminfo -type f -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find usr/share/tabset -type f -print0 | xargs -0 rm -f ) > /dev/null 2>&1
# Wipe dangling symlinks:
( find -L ./bin -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find -L ./usr/bin -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find -L ./sbin -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find -L ./lib -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find -L ./lib${LIBDIRSUFFIX} -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find -L ./usr/lib -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1
( find -L ./usr/lib${LIBDIRSUFFIX} -type l -print0 | xargs -0 rm -f ) > /dev/null 2>&1

cd $PKG/$ARCH-installer-filesystem

cp --remove-destination -fa${VERBOSE2} $TMP/extract-packages/. .
rm -rf $TMP/extract-packages

# Re-create essential symlinks
ln -sf sbin/init init
( cd bin; ln -sf grep.bin grep )
( cd bin; ln -sf grep.bin egrep )
( cd bin; ln -sf grep.bin fgrep )
( cd bin; ln -sf gzip zcat )
( cd bin; ln -sf /usr/bin/compress compress )
( cd usr/bin; ln -sf ../../bin/gzip zcat )

# Add RAID re-assembly commands to rc.S if missing:
if ! grep -q mdadm etc/rc.d/rc.S ; then
  sed -i -e '/# Check \/proc\/partitions again:/s%^%# Re-assemble RAID volumes:\n/sbin/mdadm -E -s > /etc/mdadm.conf\n/sbin/mdadm -A -s\n\n%m' etc/rc.d/rc.S
  if [ $? -ne 0 ]; then
    echo "*** Adding mdadm commands to /etc/rc.d/rc.S failed. ***"
  fi
fi

}

############### Zip up skeleton from Slackware installer image #################

zipup_installer_skeleton()
{
cd $PKG/$ARCH-installer-filesystem
echo "--- Zipping up a skeleton initrd in '$CWD' ---"
tar -zc${VERBOSE1}f $CWD/skeleton_initrd.tar.gz .
}

############### Unpack skeleton of a Slackware installer image #################

use_installer_source()
{
if [ ! -f $CWD/sources/initrd/skeleton_initrd.tar.gz ]; then
  if [ ! -f $SRCDIR/sources/initrd/skeleton_initrd.tar.gz ]; then
    echo "*** Could not find 'skeleton_initrd.tar.gz' in either:"
    echo "*** '$CWD/sources/initrd/' or '$SRCDIR/sources/initrd/'"
    return 1
  else
    SKELFILE="$SRCDIR/sources/initrd/skeleton_initrd.tar.gz"
  fi
else
  SKELFILE="$CWD/sources/initrd/skeleton_initrd.tar.gz"
fi
echo "--- Using _your_ skeleton installer (not the initrd in the Slacktree) ---"
echo "--- ($SKELFILE) ---"
cd $PKG/$ARCH-installer-filesystem
tar -zx${VERBOSE1}f $SKELFILE
}

############### Build busybox ##################################################

build_busybox()
{
echo "--- Building a new busybox ---"
# Extract source:
cd $TMP
if [ -d $CWD/sources/busybox ]; then
  echo "--- Using _your_ busybox sources (not those in the Slacktree) ---"
  BUSYBOXPATH=$CWD/sources/busybox
elif [ -d $SRCDIR/sources/busybox ]; then
  echo "--- Using _your_ busybox sources (not those in the Slacktree) ---"
  BUSYBOXPATH=$SRCDIR/sources/busybox
else
  # Use the busybox sources from the real Slackware tree:
  BUSYBOXPATH=$SLACKROOT/source/installer
fi
[ ! -d $BUSYBOXPATH ] && ( echo "No directory '$BUSYBOXPATH'" ; exit 1 )
BUSYBOXPKG=$(ls -1 $BUSYBOXPATH/busybox-*.tar.bz2 | head -1)
BUSYBOXCFG=$(ls -1 $BUSYBOXPATH/busybox?dot?config | head -1)
BUSYBOXVER=$(echo $BUSYBOXPKG | sed -e "s#.*/busybox-\(.*\).tar.bz2#\1#")

echo "--- Compiling BUSYBOX version '$BUSYBOXVER' ---"
tar x${VERBOSE2}f $BUSYBOXPKG
cd busybox-* || exit 1
if $(ls $BUSYBOXPATH/busybox*.diff.gz 1>/dev/null 2>/dev/null) ; then
  for DIFF in $(ls $BUSYBOXPATH/busybox*.diff.gz) ; do
    zcat $DIFF | patch -p1 --verbose || exit 1
  done
fi
chown -R root:root .

# Copy config:
install -m644 $BUSYBOXCFG .config

# Build:
make $SILENTMAKE $NUMJOBS CFLAGS="$SLKCFLAGS" || exit 1

# Install into package framework:
make $SILENTMAKE $NUMJOBS install || exit 1
cd _install

# Since Slackware 's installer uses the 'date' from coreutils, and 'zcat'
# script from gzip, we delete the busybox symlinks:
rm -f${VERBOSE1} bin/date bin/zcat

# Likewise, we will remove the 'fdisk' applet which overwrites our shell script:
rm -f${VERBOSE1} sbin/fdisk

# And we want to use our own 'cp':
rm -f${VERBOSE1} bin/cp

cp --remove-destination -fa${VERBOSE2} * $PKG/$ARCH-installer-filesystem/

# If we built bin/env, make a link in usr/bin as well:
if [ -x $PKG/$ARCH-installer-filesystem/bin/env ]; then
  ( cd $PKG/$ARCH-installer-filesystem/usr/bin ; ln -sf ../../bin/env . )
fi

}


############### Build dropbear #################################################

build_dropbear()
{
echo "--- Building a new dropbear ---"
# Extract source:
cd $TMP
if [ -d $CWD/sources/dropbear ]; then
  echo "--- Using _your_ dropbear sources (not those in the Slacktree) ---"
  DROPBEARPATH=$CWD/sources/dropbear
elif [ -d $SRCDIR/sources/dropbear ]; then
  echo "--- Using _your_ dropbear sources (not those in the Slacktree) ---"
  DROPBEARPATH=$SRCDIR/sources/dropbear
else
  # Use the dropbear sources from the Slackware tree.
  DROPBEARPATH=$SLACKROOT/source/installer/dropbear
fi
[ ! -d $DROPBEARPATH ] && ( echo "No directory '$DROPBEARPATH'" ; exit 1 )
DROPBEARPKG=$(ls -1 $DROPBEARPATH/dropbear-*.tar.lz | head -1)
DROPBEARVER=$(echo $DROPBEARPKG | sed -e "s#.*/dropbear-\(.*\).tar.lz#\1#")
tar x${VERBOSE2}f $DROPBEARPKG

echo "--- Compiling DROPBEAR version '$DROPBEARVER' ---"
cd dropbear* || exit 1
chown -R root:root .
chmod -R u+w,go+r-w,a-s .

# The programs we want to have as symlinks to dropbearmulti binary:
PROGS="dropbear dbclient dropbearkey dropbearconvert scp ssh"

# Patch to allow empty passwords (used in Slackware's installer):
patch -p1 ${VERBOSETXT} < $DROPBEARPATH/dropbear_emptypass.patch || exit 1

# Set local options, such as dbclient is in /bin (due to prefix=/):
cp $DROPBEARPATH/localoptions.h .

autoconf || exit 1
autoheader || exit 1

# Configure:
CFLAGS="$SLKCFLAGS" \
CXXFLAGS="$SLKCFLAGS" \
./configure \
   --prefix=/ \
   --mandir=/usr/man \
   --disable-syslog \
   --disable-utmp \
   --disable-utmpx \
   --disable-wtmp \
   --disable-wtmpx \
   --disable-pututline \
   --disable-pututxline \
   --build=$ARCH-slackware-linux$ARCHQUADLET || exit 1

# Build:
make $SILENTMAKE $NUMJOBS PROGRAMS="$PROGS" MULTI="1" SCPPROGRESS="1" || exit 1

# Install into installer's filesystem:
make $SILENTMAKE DESTDIR=$PKG/$ARCH-installer-filesystem/ MULTI="1" install || exit 1

# Link binaries to dropbearmulti since the 'make install' does not do that
# if we build a multicall binary
( cd $PKG/$ARCH-installer-filesystem/bin
  ln -${VERBOSE1}fs ../bin/dropbearmulti ../sbin/dropbear
  for i in $(echo $PROGS | sed -e 's/dropbear //') ; do
    ln -${VERBOSE1}fs dropbearmulti $i
  done
)

}

############### Build nano #####################################################

build_nano()
{
echo "--- Building nano editor ---"
# Extract source:
cd $TMP
if [ -d $CWD/sources/nano ]; then
  echo "--- Using _your_ nano sources (not those in the Slacktree) ---"
  NANOPATH=$CWD/sources/nano
elif [ -d $SRCDIR/sources/nano ]; then
  echo "--- Using _your_ nano sources (not those in the Slacktree) ---"
  NANOPATH=$SRCDIR/sources/nano
else
  # Use the nano sources from the Slackware tree.
  NANOPATH=$SLACKROOT/source/installer/nano
fi
[ ! -d $NANOPATH ] && ( echo "No directory '$NANOPATH'" ; exit 1 )
NANOPKG=$(ls -1 $NANOPATH/nano-*.tar.?z | head -1)
NANOVER=$(echo $NANOPKG | rev | cut -f 3- -d . | cut -f 1 -d - | rev)
tar x${VERBOSE2}f $NANOPKG

echo "--- Compiling NANO version '$NANOVER' ---"
cd nano* || exit 1
chown -R root:root .
chmod -R u+w,go+r-w,a-s .

# Configure:
CFLAGS="$(echo $SLKCFLAGS | sed s/-O2/-Os/g)" \
./configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --infodir=/usr/info \
  --mandir=/usr/man \
  --docdir=/usr/doc/nano-$VERSION \
  --datadir=/usr/share \
  --program-prefix= \
  --program-suffix= \
  --disable-libmagic \
  --enable-color \
  --enable-multibuffer \
  --enable-nanorc \
  --enable-utf8 \
  --build=$ARCH-slackware-linux$ARCHQUADLET || exit 1

# Build:
make $NUMJOBS || make || exit 1

# Install into installer's filesystem:
mkdir -p $PKG/$ARCH-installer-filesystem/usr/bin
cp -a src/nano $PKG/$ARCH-installer-filesystem/usr/bin/nano
strip --strip-unneeded $PKG/$ARCH-installer-filesystem/usr/bin/nano
mkdir -p $PKG/$ARCH-installer-filesystem/usr/man/man1
cat doc/nano.1 | gzip -9c > $PKG/$ARCH-installer-filesystem/usr/man/man1/nano.1.gz

# Install locale files if I_AM_DIDIER is defined:
if [ ! -z $I_AM_DIDIER ]; then
  ( cd po
    make install DESTDIR=$PKG/$ARCH-installer-filesystem/
  )
fi

}

############## Install binaries into installer filesystem ######################

# You can generate file-> package list in slackware-current
# cd slackware-current/${DISTRODIR}
# find . -name '*.t?z' | while read name ; do echo "****** $name ******" ; tar tvvf $name ; done > /tmp/newfest
#

import_binaries()
{
# Change into the installer's filesystem:
cd $PKG/$ARCH-installer-filesystem

echo "--- Importing binaries from Slackware packages ---"

# Temporary extraction directory:
rm -rf $TMP/extract-packages
mkdir -p -m755 $TMP/extract-packages

# This list of packages (Slackware v13.0+):
#
# Some ports require binaries from additional packages not shipped
# by Slackware/x86.  Put the name of the binary into the relevant
# string below, and it'll be copied into either the installer filesystem's
# /sbin or /bin -- the installer does not have /usr/{sbin,bin}.
#
case $ARCH in
  arm*) EXTRA_PKGS="a/u-boot-tools a/mtd-utils"
        EXTRA_PKGS_BIN=""
        EXTRA_PKGS_SBIN=""
        EXTRA_PKGS_USRBIN="mkimage"
        EXTRA_PKGS_USRSBIN="nand* flash_* flashcp sheeva* fw_setenv fw_printenv ubi*" ;;
    *)  EXTRA_PKGS=""
        EXTRA_PKGS_BIN=""
        EXTRA_PKGS_SBIN=""
        EXTRA_PKGS_USRBIN=""
        EXTRA_PKGS_USRSBIN="" ;;
esac
PKGLIST="${EXTRA_PKGS} \
a/bash \
a/btrfs-progs \
a/coreutils \
a/cryptsetup \
a/dialog \
a/dosfstools \
a/e2fsprogs \
a/efivar \
a/elogind \
a/etc \
a/f2fs-tools \
a/gptfdisk \
a/grep \
a/gzip \
a/hdparm \
a/hwdata \
a/inih \
a/jfsutils \
a/kmod \
a/lvm2 \
a/lzip \
a/lzlib \
a/mdadm \
a/ncompress \
a/openssl-solibs \
a/os-prober \
a/pam \
a/pciutils \
a/plzip \
a/pkgtools \
a/procps-ng \
a/reiserfsprogs \
a/sed \
a/shadow \
a/sysfsutils \
a/syslinux \
a/tar \
a/eudev \
a/hostname \
a/libgudev \
a/usbutils \
a/util-linux \
a/xfsprogs \
a/xz \
a/zerofree \
ap/ddrescue \
ap/dmidecode \
ap/lsscsi \
ap/neofetch \
ap/terminus-font \
d/gcc \
d/gcc-g++ \
l/argon2 \
l/musl \
l/json-c \
l/keyutils \
l/libaio \
l/libcap \
l/libidn2 \
l/libnsl \
l/libunistring \
l/libusb \
l/lzo \
l/parted \
l/pcre \
l/popt \
l/readline \
l/zlib \
l/zstd \
n/dhcpcd \
n/dnsmasq \
n/iproute2 \
n/krb5 \
n/libgcrypt \
n/libgpg-error \
n/libtirpc \
n/net-tools \
n/nfs-utils \
n/ntp \
n/rpcbind \
n/samba"

# Prevent a harmless (but ugly) build-time error:
mkdir -p $TMP/extract-packages/etc
touch $TMP/extract-packages/etc/shells

# Cruise through the required packages and extract them into
# a temporary directory:
for pkg in $PKGLIST ; do
  if [ -s $SLACKROOT/${DISTRODIR}/$pkg-+([^-])-+([^-])-+([^-]).t[gblx]z ]; then
    installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/$pkg-+([^-])-+([^-])-+([^-]).t[gblx]z
  else
    echo "*** Package: "$pkg" not found in ${SLACKROOT}/${DISTRODIR} ***"
    exit 1
  fi
done

#
# Deal with the installer's /bin:
#
cd $TMP/extract-packages/bin
cp --remove-destination -fa${VERBOSE1} ${EXTRA_PKGS_BIN} \
        bash \
        comm \
        cp \
        cut \
        date \
        dialog \
        dircolors \
        findmnt \
        gzip \
        ipmask \
        ls \
        lsblk \
        paste \
        printf \
        pr \
        ps \
        mknod \
        mount \
        numfmt \
        sed \
        seq \
        sort \
        tar \
        umount \
        xz \
        zgrep \
        $PKG/$ARCH-installer-filesystem/bin/
$(readlink -s setterm 1>/dev/null) || \
  cp --remove-destination -fa${VERBOSE1} setterm \
  $PKG/$ARCH-installer-filesystem/bin/
cp --remove-destination -fa${VERBOSE1} grep $PKG/$ARCH-installer-filesystem/bin/grep.bin
cd $TMP/extract-packages/usr/bin
cp --remove-destination -fa${VERBOSE1} ${EXTRA_PKGS_USRBIN} \
        bash \
        ddrescue \
        ldd \
        lzip \
        neofetch \
        plzip \
        rev \
        uuidgen \
        syslinux-nomtools \
        strings \
        $PKG/$ARCH-installer-filesystem/usr/bin/
# Fix ldd shebang:
sed -i "s|/usr/bin/bash|/bin/bash|g" $PKG/$ARCH-installer-filesystem/usr/bin/ldd
# Use syslinux-nomtools to avoid needing mtools on the installer:
if [[ $ARCH = *86* ]]; then
  mv --verbose $PKG/$ARCH-installer-filesystem/usr/bin/syslinux-nomtools $PKG/$ARCH-installer-filesystem/usr/bin/syslinux || exit 1
fi
$(readlink -s setterm 1>/dev/null) || \
  cp --remove-destination -fa${VERBOSE1} setterm \
  $PKG/$ARCH-installer-filesystem/usr/bin/
cp --remove-destination -fa${VERBOSE1} \
        compress \
        $PKG/$ARCH-installer-filesystem/usr/bin/

# Make sure that /bin/sh points to bash:
( cd $PKG/$ARCH-installer-filesystem/bin
  ln -${VERBOSE1}fs bash sh
)

#
# Deal with the installer's /sbin:
#
cd $TMP/extract-packages/sbin
cp --remove-destination -fa${VERBOSE1} ${EXTRA_PKGS_SBIN} \
        badblocks \
        blkid \
        btrfs* \
        cgdisk \
        cryptsetup \
        debugfs \
        dmsetup \
        dosfsck \
        dumpe2fs \
        e2fsck \
        fsck \
        fsck.* \
        filefrag \
        fixparts \
        hdparm \
        insmod \
        e2image \
        e2label \
        e4crypt \
        gdisk \
        fsfreeze \
        fstrim \
        jfs_fsck \
        jfs_mkfs \
        kmod \
        logsave \
        ldconfig \
        lsmod \
        lspci \
        lvm \
        lvmdump \
        mount.nfs \
        mkdosfs \
        mke2fs \
        mkreiserfs \
        mkfs.* \
        mklost+found \
        mkswap \
        modprobe \
        mount \
        mdadm \
        rdev \
        reiserfsck \
        rmmod \
        resize2fs \
        rpcbind \
        rpc.statd \
        sfdisk \
        sgdisk \
        swaplabel \
        tune2fs \
        udev* \
        umount \
        xfs_repair \
        $PKG/$ARCH-installer-filesystem/sbin/
        # This had dmsetup* above, which unnecessarily copies dmsetup.static
        # This had lvm* above, which unnecessarily copies lvm.static
cp --remove-destination -fa${VERBOSE1} fdisk \
   $PKG/$ARCH-installer-filesystem/sbin/fdisk.bin

# Hack reboot to call reboot -f:
rm -f $PKG/$ARCH-installer-filesystem/sbin/reboot
( cd $PKG/$ARCH-installer-filesystem/bin ; ln -sf busybox reboot )
cat << EOF > $PKG/$ARCH-installer-filesystem/sbin/reboot
#!/bin/sh
echo "Sending all processes the SIGTERM signal."
/sbin/killall5 -15
/bin/sleep 2
echo "Sending all processes the SIGKILL signal."
/sbin/killall5 -9
/bin/sleep 2
echo "Syncing filesystems."
sync
echo "Unmounting filesystems:"
# Try to unmount these bind mounts first to prevent them from blocking unmount of the target /:
umount /mnt/dev 2> /dev/null
umount /mnt/proc 2> /dev/null
umount /mnt/sys 2> /dev/null
/bin/umount -v -a -t no,proc,sysfs,devtmpfs,fuse.gvfsd-fuse,tmpfs
sync
echo "Rebooting."
if [ -z "\$*" ]; then
  /bin/reboot -f
else
  /bin/reboot \$*
fi
EOF
chmod 755 $PKG/$ARCH-installer-filesystem/sbin/reboot

# Copy binaries from /usr/bin into the installer's /usr/bin/
cd $TMP/extract-packages/usr/bin
cp --remove-destination -fa${VERBOSE1} ${EXTRA_PKGS_USRBIN} \
        chattr \
        lsattr \
        lsusb \
        mcookie \
        usb-devices \
        $PKG/$ARCH-installer-filesystem/usr/bin/

# Copy PAM's security directory:
cd $TMP/extract-packages/lib${LIBDIRSUFFIX}
cp -a security $PKG/$ARCH-installer-filesystem/lib${LIBDIRSUFFIX}

# Copy PAM's config files:
cd $TMP/extract-packages/etc
cp -a pam.d $PKG/$ARCH-installer-filesystem/etc
( cd $PKG/$ARCH-installer-filesystem/etc/pam.d
  for file in *.new ; do
    mv $file $(basename $file .new)
  done
)

# Grab a couple of terminus fonts that we'll need to prevent
# blindness from microscopic KMS terminal fonts:
cd $TMP/extract-packages/usr/share/kbd/consolefonts
mkdir -p $PKG/$ARCH-installer-filesystem/usr/share/kbd/consolefonts
cp --remove-destination -fa${VERBOSE1} \
  ter-114v.psf.gz \
  $PKG/$ARCH-installer-filesystem/usr/share/kbd/consolefonts

# Copy binaries from /usr/sbin into the installer's /usr/sbin/
cd $TMP/extract-packages/usr/sbin
cp --remove-destination -fa${VERBOSE1} ${EXTRA_PKGS_USRSBIN} \
        chpasswd \
        dnsmasq \
        ntpdate \
        parted \
        partprobe \
        partx \
        dmidecode \
        mount.cifs \
        sm-notify \
        sparsify \
        umount.cifs \
        zerofree \
        $PKG/$ARCH-installer-filesystem/usr/sbin/

# The installer has wrappers for cfdisk/fdisk which run /dev/makedevs.sh
# if it is there.  If it is not there, udev is running and will handle
# creating or removing block devices in /dev as needed:
cd $TMP/extract-packages/sbin
cp --remove-destination -fa${VERBOSE1} \
        cfdisk \
        $PKG/$ARCH-installer-filesystem/sbin/cfdisk.bin

# And for LVM, there are tonnes of symlinks:
cd $TMP/extract-packages/sbin
find . -type l -lname lvm -printf "%p\n" | xargs -i cp  -fa${VERBOSE1} {} $PKG/$ARCH-installer-filesystem/sbin/
# Fix lvmdump script:
sed -i -e 's?/usr/bin/tr?tr?' $PKG/$ARCH-installer-filesystem/sbin/lvmdump
# Grab the matching lvm.conf script:
mkdir -p $PKG/$ARCH-installer-filesystem/etc/lvm
cat $TMP/extract-packages/etc/lvm/lvm.conf \
  > $PKG/$ARCH-installer-filesystem/etc/lvm/lvm.conf

# Use a current group file (udev expects this)
cat $TMP/extract-packages/etc/group > $PKG/$ARCH-installer-filesystem/etc/group

## Copy udev related files over (do not clobber an existing blacklist):
#if [ -f $PKG/$ARCH-installer-filesystem/etc/modprobe.d/blacklist ]; then
#  mv $PKG/$ARCH-installer-filesystem/etc/modprobe.d/blacklist{,.new}
#fi
# Copy udev related files over
cp -a $TMP/extract-packages/etc/modprobe.d $PKG/$ARCH-installer-filesystem/etc/
mkdir -p $PKG/$ARCH-installer-filesystem/lib
cp -a $TMP/extract-packages/lib/modprobe.d $PKG/$ARCH-installer-filesystem/lib/
cp -a $TMP/extract-packages/etc/{modprobe.conf,modprobe.d,scsi_id.config,udev} \
  $PKG/$ARCH-installer-filesystem/etc/
cp -a $TMP/extract-packages/etc/rc.d/rc.udev \
  $PKG/$ARCH-installer-filesystem/etc/rc.d/
#if [ -f $PKG/$ARCH-installer-filesystem/etc/modprobe.d/blacklist.new ]; then
#  mv $PKG/$ARCH-installer-filesystem/etc/modprobe.d/blacklist{.new,}
#fi

# Copy package tools:
cd $TMP/extract-packages/sbin
cp --remove-destination -fa${VERBOSE1} \
        installpkg \
        pkgtool \
        removepkg \
        $PKG/$ARCH-installer-filesystem/sbin/

# Deal with /lib stuff from the packages:
mkdir -p -m755 $PKG/$ARCH-installer-filesystem/lib
mkdir -p -m755 $PKG/$ARCH-installer-filesystem/lib${LIBDIRSUFFIX}
mkdir -p -m755 $PKG/$ARCH-installer-filesystem/usr/lib${LIBDIRSUFFIX}
cp  -fa${VERBOSE1} $TMP/extract-packages/lib/udev \
        $PKG/$ARCH-installer-filesystem/lib/
cd $TMP/extract-packages/lib${LIBDIRSUFFIX}
cp  -fa${VERBOSE1} \
        e2initrd_helper \
        libaio.so* \
        libblkid*so* \
        libcap*so* \
        libcrypto*so* \
        libdevmapper*so* \
        libelogind*so* \
        libf2fs.so* \
        libfdisk.so* \
        libgcc*so* \
        libgcrypt*.so* \
        libgpg-error*.so* \
        libgssapi_krb5.so* \
        libinih.so* \
        libk5crypto.so* \
        libkeyutils.so* \
        libkmod*so* \
        libkrb5.so* \
        libkrb5support.so* \
        liblzma*so* \
        libmount.so* \
        libnsl.so* \
        libpam*.so* \
        libpcre.so* \
        libpopt*.so* \
        libsmartcols.so* \
        libssl*so* \
        libtirpc*so* \
        libudev*so* \
        libuuid*so* \
        libvolume_id*so* \
        libz*.so* \
        $PKG/$ARCH-installer-filesystem/lib${LIBDIRSUFFIX}/

# Deal with /usr/lib stuff from the packages:
cd $TMP/extract-packages/usr/lib${LIBDIRSUFFIX}
cp  -fa${VERBOSE1} \
        libargon2.so* \
        libcryptsetup*.so* \
        libefiboot.so* \
        libefivar.so* \
        libgcc*.so* \
        libhistory*.so* \
        libidn2*.so* \
        libjson-c.so* \
        liblz.so* \
        liblzo*.so* \
        libparted*so* \
        libreadline*.so* \
        libstdc++*.so* \
        libunistring*.so* \
        libusb-1.0*.so* \
        libzstd.so* \
        $PKG/$ARCH-installer-filesystem/usr/lib${LIBDIRSUFFIX}/

# Stuff needed for os-prober:
cd $TMP/extract-packages/usr/share
cp  -fa${VERBOSE1} \
        os-prober \
        $PKG/$ARCH-installer-filesystem/usr/share/
cd $TMP/extract-packages/usr/lib${LIBDIRSUFFIX}
cp  -fa${VERBOSE1} \
        os-probes \
        os-prober \
        linux-boot-probes \
        $PKG/$ARCH-installer-filesystem/usr/lib${LIBDIRSUFFIX}/
cd $TMP/extract-packages/usr/bin
cp  -fa${VERBOSE1} \
        linux-boot-prober \
        os-prober \
        $PKG/$ARCH-installer-filesystem/usr/bin/

# Copy dhcpcd pieces:
cd $TMP/extract-packages/
cp -fa${VERBOSE1} \
       lib/dhcpcd \
       $PKG/$ARCH-installer-filesystem/lib/
cp -fa${VERBOSE1} \
      usr/lib${LIBDIRSUFFIX}/dhcpcd \
      $PKG/$ARCH-installer-filesystem/usr/lib${LIBDIRSUFFIX}/
cp -fa${VERBOSE1} \
       var/lib/dhcpcd \
       $PKG/$ARCH-installer-filesystem/var/lib/
cp -fa${VERBOSE1} \
       etc/dhcpcd.conf \
       $PKG/$ARCH-installer-filesystem/etc/
cp -fa${VERBOSE1} \
       sbin/dhcpcd \
       $PKG/$ARCH-installer-filesystem/sbin/

# Add pci.ids and usb.ids now that we have lspci and lsusb onboard:
cd $TMP/extract-packages/usr/share/hwdata
mkdir -p -m755 $PKG/$ARCH-installer-filesystem/usr/share/hwdata
cp -fa${VERBOSE1} pci.ids usb.ids \
        $PKG/$ARCH-installer-filesystem/usr/share/hwdata

# Copy the rc script for rpcbind:
cd $TMP/extract-packages/etc/rc.d
cp -fa${VERBOSE1} \
       rc.rpc \
       $PKG/$ARCH-installer-filesystem/etc/rc.d/
chmod 755 $PKG/$ARCH-installer-filesystem/etc/rc.d/rc.rpc
mkdir -p $PKG/$ARCH-installer-filesystem/var/state/rpcbind

# Copy /etc/default/{nfs,rpc}:
cd $TMP/extract-packages/etc/default
cp -fa${VERBOSE1} \
       nfs rpc \
       $PKG/$ARCH-installer-filesystem/etc/default

# Remove busybox symlinks for things that we have a real version of:
for prunedir in $PKG/$ARCH-installer-filesystem/usr/bin $PKG/$ARCH-installer-filesystem/usr/sbin ; do
  cd $prunedir
  for removefile in $(find . -type f -maxdepth 1) ; do
    rm -f $PKG/$ARCH-installer-filesystem/bin/$(basename $removefile)
    rm -f $PKG/$ARCH-installer-filesystem/sbin/$(basename $removefile)
  done
done
if [ -r rm -f $PKG/$ARCH-installer-filesystem/sbin/lspci -a ! -L $PKG/$ARCH-installer-filesystem/sbin/lspci -a -L $PKG/$ARCH-installer-filesystem/bin/lspci ]; then
  rm -f $PKG/$ARCH-installer-filesystem/bin/lspci
fi

# Update to latest versions of files within /etc/
# /etc/ file         Package    Reason
#       ------------------------------------------------------------------------------------
#       netconfig     : libtirpc : Required by libtirpc (for rpc.statd/rpcbind)
#       services      : etc      : Always use the latest version to avoid problems with NFS.
#       dialogrc      : dialog   : Dialog config
#       mke2fs.conf   : e2fsprogs: Required for ext4
#       nfsmount.conf : nfs-utls : On ARM we set "vers=3" as the default which allows
#                                  easy NFS mounting within the installer.
cd $TMP/extract-packages/etc/
cp -fa${VERBOSE1} \
       services \
       netconfig \
       nfsmount.conf \
       dialogrc \
       mke2fs.conf \
       $PKG/$ARCH-installer-filesystem/etc/

# For ARM:
# Copy the configuration file for fw_(printenv/saveenv) utility.
# This allows people to more easily fix up a duff u-boot config
# from the installer because the config file contains some of the memory offsets
# for the most popular devices
[ -s $TMP/extract-packages/etc/fw_env.config* ] \
  && install -${VERBOSE1}pm644 $TMP/extract-packages/etc/fw_env.config* \
     $PKG/$ARCH-installer-filesystem/etc/fw_env.config

# If man pages have been requested, copy the groff sources to process later
# For now, these will be English only (sorry)
if [ $ADD_MANPAGES -eq 1 ]; then
  if [ -d $TMP/extract-packages/usr/man ]; then
    mkdir -p $PKG/$ARCH-installer-filesystem/usr/man/
    cd $TMP/extract-packages/usr/man
    cp --remove-destination -fa${VERBOSE1} man* \
          $PKG/$ARCH-installer-filesystem/usr/man/
  fi
  # In case the real man package has been installed (unlikely)
  if [ -f $TMP/extract-packages/lib${LIBDIRSUFFIX}/man.conf ]; then
    cp -a $TMP/extract-packages/lib${LIBDIRSUFFIX}/man.conf $PKG/$ARCH-installer-filesystem/usr/lib${LIBDIRSUFFIX}
  fi
fi

}

############### Install libraries into installer's filesystem ##################

# We install the library packages and copy only the parts that we need.
#
# Rather than automate the process, for some packages we need to specifically
# select individual library names.
# In case you wonder why we don't copy these libraries during the extraction
# in the code above, it's because this way we don't need to keep up to date with
# any new library names or versions - we either take everything or be very
# specific -- this is particularly relevant for glibc.

import_libraries()
{
rm -rf $TMP/extract-packages
mkdir -p $TMP/extract-packages

# Change into the installer's filesystem:
cd $PKG/$ARCH-installer-filesystem

echo "--- Importing libraries from Slackware packages ---"

# a/e2fsprogs:
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/a/e2fsprogs-*.t[gblx]z
cp  -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
rm -rf $TMP/extract-packages

# l/musl:
mkdir -p $TMP/extract-packages
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/l/musl-*.t[gblx]z
#cp  -fa${VERBOSE1} /lib${LIBDIRSUFFIX}/ld-linux*so* lib${LIBDIRSUFFIX}/
cp  -fa${VERBOSE1} /lib${LIBDIRSUFFIX}/* lib${LIBDIRSUFFIX}/
cp  -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
# pt_chown has been removed from glibc as a possible security hole:
#cp --remove-destination -fa${VERBOSE1} $TMP/extract-packages/usr/libexec/pt_chown usr/libexec
rm -rf $TMP/extract-packages

# l/ncurses:
mkdir -p $TMP/extract-packages
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/l/ncurses-*.t[gblx]z
cp -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
cp -fa${VERBOSE1} $TMP/extract-packages/usr/share/terminfo/{c,l,v,s,x} usr/share/terminfo/
# Remove any terminal entries that are broken due to them being symlinks into directories that we haven't included:
find usr/share/terminfo/ -xtype l -print0 | xargs -0 rm -f
cp -fa${VERBOSE1} $TMP/extract-packages/usr/share/tabset/* usr/share/tabset/
rm -rf $TMP/extract-packages
# Remove dangling symlinks (pointing into directories we did not copy):
( cd usr/share/terminfo
  for file in $(find . -type l) ; do
    if [ "$(readlink -e $file)" = "" ]; then
      rm -f${VERSOSE1} $file
    fi
  done
)

# a/acl:
mkdir -p $TMP/extract-packages
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/a/acl-*.t[gblx]z
cp -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
rm -rf $TMP/extract-packages

# a/attr:
mkdir -p $TMP/extract-packages
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/a/attr-*.t[gblx]z
cp -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
rm -rf $TMP/extract-packages

# a/pciutils:
mkdir -p $TMP/extract-packages
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/a/pciutils-*.t[gblx]z
cp  -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
rm -rf $TMP/extract-packages

# a/procps-ng:
mkdir -p $TMP/extract-packages
installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/a/procps-ng-*.t[gblx]z
cp  -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
  lib${LIBDIRSUFFIX}/
rm -rf $TMP/extract-packages

# a/gpm:
#mkdir -p $TMP/extract-packages
#installpkg --terse -root $TMP/extract-packages $SLACKROOT/${DISTRODIR}/a/gpm-*.t[gblx]z
#cp  -fa${VERBOSE1} $TMP/extract-packages/lib${LIBDIRSUFFIX}/*so* \
#  lib${LIBDIRSUFFIX}/
#rm -rf $TMP/extract-packages

}

############### Install Kernel modules into installer's filesystem #############
#
#
############### Add the network modules ########################################

add_netmods()
{

echo "--- Adding network modules ---"
cd $PKG/$ARCH-installer-filesystem

# Clear out remaining cruft:
rm -rf ./lib/modules.incoming

# Temporary extraction directory:
rm -rf $TMP/extract-packages
mkdir -p -m755 $TMP/extract-packages

# Unpack the kernel modules (all kernels defined for this $ARCH):
for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
  tar -C $TMP/extract-packages -x${VERBOSE1}f $(ls -1 ${KERNELMODPKG} | grep "${KVER}$(echo ${KEXTRAV[$ind]}| tr - _)-" ) lib
done
mv -f${VERBOSE1} $TMP/extract-packages/lib/modules ./lib/modules.incoming

# Start removing unwanted modules to keep the resulting image small:
echo "--- Removing unneeded kernel modules ---"
for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
  kv=${KEXTRAV[$ind]}
  [ ! -d ./lib/modules.incoming/$KVER$kv ] && continue
  (
    echo "--- Processing kernel version '$KVER$kv' ---"
    cd ./lib/modules.incoming/$KVER$kv
    cd kernel/
    # Remove blacklisted modules:
    cat $MODBLACKLIST | while read modname ; do
      find . -name $modname -exec rm -f "{}" \;
    done
    mv -f fs{,.orig} && \
    ( mkdir -m755 fs
      # If the architecture has a mostly modular kernel, then
      # the filesystem modules may need to be included within the installer:
      case $ARCH in
         arm*)
           cp -a fs.orig/{udf*,isofs*,cifs*,ext*,fat*,fscache,jfs*,lockd,nfs,nfs_common,jbd*,nls,reiserfs,xfs,binfmt*,mbcache*,exportfs*} fs/
         ;;
         *86*)
           cp -a fs.orig/{cifs*,fscache,lockd,nfs,nfs_common} fs/
         ;;
         *)
           cp -a fs.orig/cifs* fs/
         ;;
      esac
      rm -rf fs.orig )
    rm -rf${VERBOSE1} sound arch

    cd net/
    # Architectures with a more modular kernel will want to keep supporting
    # modules for 'nfs' et al:
    case $ARCH in
       arm*)
       ;;
       *86*)
       ;;
       *)
          rm -rf${VERBOSE1} sunrpc
       ;;
    esac
    mv -f ipv4{,.orig} && ( mkdir -m755 ipv4 ; cp -a ipv4.orig/inet* ipv4/ ; rm -rf ipv4.orig )
    mv -f ipv6{,.orig} && ( mkdir -m755 ipv6 ; cp -a ipv6.orig/ipv6* ipv6/ ; rm -rf ipv6.orig )
    rm -rf${VERBOSE1} 9p appletalk atm ax25 bluetooth bridge dccp decnet ieee80211 ipx irda key mac80211 netfilter netrom rds rfkill rose rxrpc sched sctp tipc wanrouter wimax wireless
    cd ..

    cd drivers/
    # Architectures with a more modular kernel will want to keep 'ide' 'scsi'
    # and other core device drivers:
    case $ARCH in
       arm*)
       ;;
       *)
         mv scsi scsi.orig
         mv md md.orig
         rm -rf${VERBOSE1} cdrom ide md scsi
         mkdir scsi
         mv scsi.orig/hv_storvsc.ko scsi
         rm -rf${VERBOSE1} scsi.orig
         mkdir md
         mv md.orig/dm-bufio.ko md
         mv md.orig/dm-bio-prison.ko md
         mv md.orig/dm-raid.ko md
         mv md.orig/dm-snapshot.ko md
         mv md.orig/dm-thin-pool.ko md
         mkdir md/persistent-data
         mv md.orig/persistent-data/dm-persistent-data.ko md/persistent-data
         rm -rf${VERBOSE1} md.orig
       ;;
    esac
    # Save loop.ko, nvme.ko, and virtio_blk.ko, but remove other block drivers:
    mv block block.orig
    mkdir block
    mv block.orig/nvme.ko block
    mv block.orig/loop.ko block
    mv block.orig/virtio_blk.ko block
    rm -rf${VERBOSE1} block.orig
    # Done with block directory
    # Grab a few modules from staging:
    mv staging staging.orig
    mv staging.orig/hv staging
    mv staging.orig/exfat staging
    mv staging.orig/speakup staging
    rm -rf${VERBOSE1} staging.orig
    # Save the Hyper-V keyboard module:
    mkdir -p input.orig/serio
    cp -a input/serio/hyperv-keyboard.ko input.orig/serio
    rm -rf${VERBOSE1} ata atm bluetooth clocksource connector crypto dma idle infiniband input isdn kvm leds media memstick message mfd misc pci power rtc serial telephony uwb w1 watchdog
    mv input.orig input

    if [ "$ADD_KMS" = "1" ]; then
      # Keep video.ko and button.ko, needed by some gpu drivers.
      # Also keep processor.ko, needed by acpi-cpufreq.
      mv acpi acpi.orig
      mkdir acpi
      mv acpi.orig/{button,processor,video}.ko acpi
      rm -rf${VERBOSE1} acpi.orig

      # Keep AGP modules:
      mv char/agp agp.orig
      rm -rf${VERBOSE1} char
      mkdir char
      mv agp.orig char/agp

      # Keep hwmon.ko:
      mkdir hwmon.orig
      mv hwmon/hwmon.ko hwmon.orig
      rm -rf${VERBOSE1} hwmon
      mv hwmon.orig hwmon

      # Keep platform/x86/mxm-wmi.ko and platform/x86/wmi.ko
      mkdir x86.orig
      mv platform/x86/mxm-wmi.ko platform/x86/wmi.ko x86.orig
      rm -rf${VERBOSE1} platform
      mkdir platform
      mv x86.orig platform/x86

      # Keep thermal/thermal_sys.ko:
      mv thermal thermal.orig
      mkdir thermal
      mv thermal.orig/thermal_sys.ko thermal
      rm -rf${VERBOSE1} thermal.orig

      # Keep some video drivers:
      mv video video.orig
      mkdir -p video/fbdev
      mv video.orig/{sis,syscopyarea.ko,sysfillrect.ko,sysimgblt.ko} video
      mv video.orig/fbdev/hyperv_fb.ko video/fbdev
      rm -rf${VERBOSE1} video.orig
    else
      # Save the Hyper-V framebuffer module:
      mv video video.orig
      mkdir -p video/fbdevmv
      mv video.orig/fbdev/hyperv_fb.ko video/fbdev
      rm -rf${VERBOSE1} acpi char cpufreq hwmon platform thermal video.orig
    fi

    # Needed to install on MMC:
    mv mmc/host mmc/host.orig
    mkdir mmc/host
    mv mmc/host.orig/sdhci.ko mmc/host
    mv mmc/host.orig/sdhci-acpi.ko mmc/host
    mv mmc/host.orig/sdhci-pci.ko mmc/host
    mv mmc/host.orig/cqhci.ko mmc/host
    rm -rf${VERBOSE1} mmc/host.orig

    cd usb/
    rm -rf${VERBOSE1} atm host/hwa-hc.ko host/whci image serial wusbcore
    cd ..

    cd net/
    rm -rf${VERBOSE1} appletalk arcnet bonding chelsio hamradio irda ixgb wimax wireless wan
    cd ..

    rm -f${VERBOSE1} ieee1394/pcilynx.ko
    rm -f${VERBOSE1} net/pcmcia/com20020_cs.ko
    rm -f${VERBOSE1} net/plip.ko
    rm -f${VERBOSE1} net/usb/hso.ko
    rm -f${VERBOSE1} usb/misc/uss720.ko
    rm -f${VERBOSE1} gpio/wm831x-gpio.ko
    #rm -f${VERBOSE1} clocksource/scx200_hrt.ko
  )
done

# Move the remaining modules into place:
mkdir -p -m755 ./lib/modules
cp --remove-destination -fa${VERBOSE2} ./lib/modules.incoming/* ./lib/modules/

# This can go now:
rm -rf${VERBOSE1} ./lib/modules.incoming

}


############### Add the pcmcia modules #########################################

add_pcmciamods()
{

echo "--- Adding pcmcia modules ---"
cd $PKG/$ARCH-installer-filesystem

# Clear out remaining cruft:
rm -rf ./lib/modules.incoming

# Temporary extraction directory:
rm -rf $TMP/extract-packages
mkdir -p -m755 $TMP/extract-packages

# Unpack the kernel modules:
for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
  kv=${KEXTRAV[$ind]}
  tar -C $TMP/extract-packages -x${VERBOSE1}f $(ls -1 ${KERNELMODPKG} | grep "${KVER}$(echo $kv| tr - _)-" ) lib
done
mv -f${VERBOSE1} $TMP/extract-packages/lib/modules ./lib/modules.incoming

# Compile the list with pcmcia modules and copy into place:
for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
  kv=${KEXTRAV[$ind]}
  mkdir -p $PKG/$ARCH-installer-filesystem/lib/modules/${KVER}$kv
done
for kmod in $( egrep "(/kernel/drivers/pcmcia/|/kernel/drivers/net/pcmcia/|/kernel/drivers/char/pcmcia/|/kernel/drivers/scsi/pcmcia/).*:" $PKG/$ARCH-installer-filesystem/lib/modules.incoming/$KVER${KEXTRAV[0]}/modules.dep | sed -e 's,:,,g ; s, ,\n,g' | sort | uniq | sed  -e "s#^/lib/modules/$KVER${KEXTRAV[0]}##" ); do
  for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
    kv=${KEXTRAV[$ind]}
    mkdir -p $PKG/$ARCH-installer-filesystem/lib/modules/${KVER}$kv/$(dirname $kmod)
    cp -a${VERBOSE1} $PKG/$ARCH-installer-filesystem/lib/modules.incoming/${KVER}$kv/$kmod $PKG/$ARCH-installer-filesystem/lib/modules/${KVER}$kv/$(dirname $kmod)/
  done
done

# We can get rid of this now:
rm -rf ./lib/modules.incoming

# Install the necessary pcmcia support files from stock packages:
echo "--- Adding support tools from Slackware packages: ---"
rm -rf $TMP/extract-packages/*
installpkg --terse -root $TMP/extract-packages/ $PCMCIAUTILS
rm -rf $TMP/extract-packages/{usr,var}
cp -a $TMP/extract-packages/* $PKG/$ARCH-installer-filesystem/
rm -rf $TMP/extract-packages/*
installpkg --terse -root $TMP/extract-packages/ $SYSFS
rm -rf $TMP/extract-packages/usr/{doc,include} $TMP/extract-packages/var
if [ ! $ADD_MANPAGES -eq 1 ]; then
  rm -rf $TMP/extract-packages/usr/man/*
fi
cp -a $TMP/extract-packages/* $PKG/$ARCH-installer-filesystem/
rm -rf $TMP/extract-packages/*

}


############### Compress kernel modules ########################################

compress_modules()
{
  # If the module files should be compressed, do that now:
  if [ $COMPRESS_MODS -eq 1 ]; then
    echo "--- Compressing kernel modules ---"
    cd $PKG/$ARCH-installer-filesystem
    #find ./lib/modules -type f -name "*.ko" -exec xz -9f -C crc32 {} \;
    # Do this one in parallel instead:
    find ./lib/modules -type f -name "*.ko" | parallel xz -9f -C crc32
    for i in $(find ./lib/modules -type l -name "*.ko") ; do ln -s $( readlink $i).xz $i.xz ; rm $i ; done
    cd - 1>/dev/null
  fi

}


############### Add network card firmware  #####################################

add_netfirmware()
{
  # Some network cards use a firmware...
  echo "--- Adding firmware for network cards ---"
  cd $PKG/$ARCH-installer-filesystem

  # Just to be safe:
  mkdir -p -m755 ./lib/firmware

  # Temporary extraction directory:
  rm -rf $TMP/extract-packages
  mkdir -p -m755 $TMP/extract-packages

  # Unpack the kernel firmware:
  tar -C $TMP/extract-packages -x${VERBOSE1}f $(ls -1 ${KERNELFW_PKG}) lib
  for FMW in $NETFIRMWARE ; do
    cp -fa${VERBOSE2} $TMP/extract-packages/lib/firmware/${FMW}* ./lib/firmware
  done

  # Clean up:
  rm -rf $TMP/extract-packages/lib
  cd - 1>/dev/null

}


############### Calculate module dependencies (showing errors) #################

check_module_dependencies()
{

cd $PKG/$ARCH-installer-filesystem

# Make sure you compile generic and huge kernels with the same options
# (apart from the drivers that will be modularized/builtins) or else you
# will see "unknown symbol" errors when the scripts resolves dependencies!
# Unpack the System.map files we need for checking unresolved dependencies
# (aka kernel modules we forgot to add):
for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
  gunzip -cd ${SLACKROOT}/kernels/${KERNELS[$ind]}/System.map.gz \
    > ./lib/modules/System.map.$KVER${KEXTRAV[$ind]}
done

echo "--- Calculating module dependencies ---"
for ind in $(seq 0 $((${#KERNELS[*]} -1)) ); do
  kv=${KEXTRAV[$ind]}
  [ ! -d $PKG/$ARCH-installer-filesystem/lib/modules/$KVER${kv} ] && continue
  rm -f $PKG/$ARCH-installer-filesystem/lib/modules/$KVER${kv}/modules.*
  /sbin/depmod -a -e -b $PKG/$ARCH-installer-filesystem \
    -F $PKG/$ARCH-installer-filesystem/lib/modules/System.map.$KVER$kv $KVER$kv
done

# We do not need these any longer:
rm -f ./lib/modules/System.map.*
}

############### Architecture specific stuff ####################################

arch_specifics()
{
cd $PKG/$ARCH-installer-filesystem

echo "--- Running ARCH specific tasks ---"

# First the tasks we want to apply to every architecture:

# Set the Slackware version in the 'setup' script & /etc/issue
# to the version specified in this installer build script:
sed -i \
 's?Slackware Linux Setup (version.*)?Slackware Linux Setup (version '"$INSTALLERVERSION"')?' \
  usr/lib/setup/setup
sed -i 's?(version.*)?(version '"$INSTALLERVERSION"')?g' etc/issue

# Then split out per supported architecture:

case $ARCH in

  arm*)
  #
  # ARM modifications:
  #
  cat << 'EOF' > root/qgo
# This makes parallel Slackware installations over SSH far easier to identify.
read -p "Host name (for window title): " winthostname
# We include additional control characters to enable us to set the window title
# even under GNU Screen:
echo -ne "\033P\033]0; Slackware ARM Installer on $winthostname \007\033\\"
ntpdate rolex.ripe.net && /bin/sh /sbin/fakedate && TERM=screen-256color setup
EOF
    chmod 755 root/qgo

    # Don't need these - they take up space:
    #
    rm -f sbin/syslinux

    # Apply ARM patches to the installer scripts:
    #
    # We don't need to set a Kernel for Slackware ARM yet, as the boot loader config is usually
    # out of reach of the OS and needs to be configured independently.
    install -${VERBOSE1}pm755 $SRCDIR/arm/installer-patches/setkernel usr/lib/setup/SeTkernel

    # Load Kernel modules required for filesystems and so on.
    sed -i '\?^#.*!/bin/? a\/etc/rc.d/rc.modules-arm' etc/rc.d/rc.S
    install -${VERBOSE1}pm755 $SRCDIR/arm/rc.modules-arm etc/rc.d/

    # Set the system clock from the hardware clock before fudging the date
    # since on ARM the system clock is not automatically set on all devices.
    sed -i '/^touch \/.today/ a/sbin/hwclock --hctosys' etc/rc.d/rc.S

    # Log errors into /tmp on the root filesystem.  This helps the development
    # process -- sometimes the doinst.sh scripts bail out because of a missing
    # dependency (or sometimes a package just needs a recompile).
    patch ${VERBOSETXT} -p0 < $SRCDIR/arm/installer-patches/slackinstall-logerror.diff || exit 1

    # On some ARM devices there is no RTC so it's best to disable the
    # fsck checks on the filesystems.
    install -${VERBOSE1}pm755 $SRCDIR/arm/armedslack-nofscheck usr/lib/setup/
    patch ${VERBOSETXT} -p0 < $SRCDIR/arm/installer-patches/SeTpartitions-add-nofscheck.diff || exit 1

    ;;

  x86_64)
  #
  # x86_64 modifications:
  #

    # We may still need to fix-up 'slackware' directory paths to 'slackware64':
    if ! grep -qr "slackware64" ./usr/lib/setup/ ; then
      # Note, the order of fix-up is important:
      sed -i \
        -e "s#/slackware\([^-]\)#/slackware64\1#g" \
        -e "s#slackware/#slackware64/#g" \
        -e "s#slackware)#slackware64)#g" \
        -e "s#slackware\$#slackware64#g" \
        -e "s#mkdir slackware#mkdir slackware64#" \
        $(grep -lr "slackware" ./usr/lib/setup)
    fi
    ;;

esac

}

############### Create the new installer initrd ################################

create_initrd()
{
cd $PKG/$ARCH-installer-filesystem/

echo "--- Creating your new initrd.img ---"
# Leave a note in the installer image to help us work out which build version
# it is -- just aids with bug reports for now:
cat <<"EOF" > .installer-version
Version details:
----------------
Installer............: $Revision: 1.129 $ ($Date: 2011/04/13 23:03:07 $)
EOF
cat << EOF >> .installer-version
For Slackware version: $INSTALLERVERSION
Build date...........: $( date )

Build details:
--------------
Installer arch.......: $ARCH
Build host...........: $( uname -a )

EOF

if [ ! -f etc/ld.so.conf ]; then
  cat <<EOF > etc/ld.so.conf
/lib${LIBDIRSUFFIX}
/usr/lib${LIBDIRSUFFIX}
EOF
fi
ldconfig -r.

## Find any remaining dangling symlinks.
#echo "--- Finding any dangling symlinks ---"
#echo "    Expect to see:"
#echo "    ./boot ./var/log/scripts ./var/log/packages"
#echo "    ./var/adm/scripts ./var/adm/packages ./cdrom ./nfs"
#echo ""
#find -L . -type l
#echo "-------------------------------------"

# Do we have to split the initrd (separate initrd for each kernel version)?
if [ $SPLIT_INITRD -eq 1 ]; then
  if [ $(ls -d --indicator-style=none ./lib/modules/${KVER}* | wc -l) -eq 2 ];
  then
    echo "--- Splitting into separate initrd's for $KVER ---"
    local usek
    for kv in $KVER $KVER-smp ; do
      [ "$kv" = "$KVER" ] && usek="-smp" || usek=""
      # Determine the size of the installer:
      echo "    Installer size (uncompressed): $( du -sh --exclude=$kv . )"
      find . -path ./lib/modules/$kv -prune -o -print \
        | cpio -o -H newc | xz -9fv -C crc32 > $CWD/initrd${usek}.img
      echo "    New installer image for kernel $KVER$usek is ${CWD}/initrd${usek}.img"
    done
  cat $SLACKROOT/isolinux/isolinux.cfg | sed \
    -e "/label huge.s/,/label hugesmp.s/s/initrd=initrd.img/initrd=initrd.img/" \
    -e "/label hugesmp.s/,/label speakup.s/s/initrd=initrd.img/initrd=initrd-smp.img/" \
    -e "/label speakup.s/,\$s/initrd=initrd.img/initrd=initrd.img/" \
    > $CWD/isolinux.cfg
  elif [ $(ls -d --indicator-style=none ./lib/modules/${KVER}* | wc -l) -gt 2 ];
  then
    echo "*** Initrd splitting only supported for a total of 2 kernel versions!"
    SPLIT_INITRD=0
  else
    echo "*** Only one set of kernel modules present, no splitting performed!"
    SPLIT_INITRD=0
  fi
fi

if [ $SPLIT_INITRD -eq 0 ]; then
  # Determine the size of the installer:
  echo "    Installer size (uncompressed): $( du -sh . )"
  find . | cpio -o -H newc | xz -9fv -C crc32 > $CWD/initrd.img
  echo "    New installer image is ${CWD}/initrd.img"
  cp -a $SLACKROOT/isolinux/isolinux.cfg $CWD/
fi

echo
echo "--- Suggested actions:"
echo "[1] chroot $PKG/$ARCH-installer-filesystem"
echo "[2] Test it"
echo "[3] When done, mv -f $CWD/initrd.img $SLACKROOT/isolinux/initrd.img"
echo
}

############### Create the USB boot image file #################################

create_usbboot()
{
# Like initrd.img, the usbboot.img will be created in the current directory
echo "--- Creating an image for the USB boot disk ---"

# Calculate sizes:
let USBIMG=$( LC_ALL=C du -ck ${CWD}/initrd*.img | grep total | cut -f1 )
for KERN in ${SLACKROOT}/kernels/*.?/*zImage ; do
  let USBIMG=USBIMG+$( LC_ALL=C du -sk $KERN | cut -f1 )
done
let USBIMG=USBIMG+777  # Add just that little extra...
if [ $EFIBOOT -eq 1 ]; then
  # A bit more extra space since elilo will be added...
  let USBIMG=USBIMG+256
fi

# Generate a pxelinux.cfg/default file (used for usbboot.img too)
cat ${CWD}/isolinux.cfg \
  | sed -e "s#/kernels/#kernels/#" > ${CWD}/pxelinux.cfg_default

# Create a DOS formatted image file
if $(which mkfs.msdos 1>/dev/null 2>&1) ; then
  MKDOS=mkfs.msdos
else
  MKDOS=mkdosfs
fi
${MKDOS} -n USBSLACK -F 16 -C ${CWD}/usbboot.img $USBIMG || exit 1
[ $VERBOSE -eq 1 ] && file ${CWD}/usbboot.img

# Copy all relevant files into the image.
rm -rf ${CWD}/usbmount
mkdir -p -m700 ${CWD}/usbmount
mount -o loop,rw ${CWD}/usbboot.img ${CWD}/usbmount

echo "--- Copying data to the USB boot disk image: ---"
cp $SLACKROOT/isolinux/setpkg ${CWD}/usbmount/
cp $SLACKROOT/isolinux/{f*.txt,message.txt} ${CWD}/usbmount/
cp ${CWD}/initrd*.img ${CWD}/usbmount/
cat ${CWD}/pxelinux.cfg_default |sed -e 's# kernels/# #g' -e 's#/.zImage##' \
  -e 's#/memtest##' \
  > ${CWD}/usbmount/syslinux.cfg

# Add EFI support:
if [ $EFIBOOT -eq 1 ]; then
  cp -a ${SRCDIR}/sources/efi.${ARCH}/* ${CWD}/usbmount
  # Make sure the Slackware and kernel version in message.txt are up to date:
  cat ${SRCDIR}/sources/efi.${ARCH}/EFI/BOOT/message.txt | sed "s/version.*/version ${INSTALLERVERSION} \(Linux kernel $(uname -r | cut -f 1 -d -)\)\!/g" > ${CWD}/usbmount/EFI/BOOT/message.txt
fi

# Older syslinux can not cope with subdirectories - let's just be safe:
echo "--- Making the usbboot image bootable: ---"
(
  cd $SLACKROOT/kernels/
  for dir in `find  -type d -name "*.?" -maxdepth 1` ; do
    cp $dir/*zImage ${CWD}/usbmount/$dir
  done
  cp $SLACKROOT/kernels/memtest/memtest ${CWD}/usbmount/memtest
)
sync

# Stamp the file with the syslinux bootloader:
#   > Do "vi ~/.mtoolsrc" to add "mtools_skip_check=1",
#   > if the next command gives an error:
umount ${CWD}/usbmount
syslinux ${CWD}/usbboot.img

# Clean up:
rm -rf ${CWD}/usbmount

}

############### Create the EFI boot image file #################################

create_efiboot()
{
# Like initrd.img, the efiboot.img will be created in the current directory
echo
echo "--- Creating an image for the EFI boot disk ---"

# Calculate sizes:
let EFIIMG=$( LC_ALL=C du -ck ${CWD}/initrd*.img | grep total | cut -f1 )
for KERN in ${SLACKROOT}/kernels/huge.s/*zImage ; do
  let EFIIMG=EFIIMG+$( LC_ALL=C du -sk $KERN | cut -f1 )
done
let EFIIMG=EFIIMG+2222  # Add just that little extra...

# Round this value down to the nearest 2048 bytes:
let EFIIMG=EFIIMG\*1024
let EFIIMG=EFIIMG/2048

# Create the image:
dd if=/dev/zero of=${CWD}/efiboot.img bs=2048 count=$EFIIMG
sgdisk -N 1 -t 1:EF00 --change-name=1:EFISLACK ${CWD}/efiboot.img
losetup -o 1048576 /dev/loop3 ${CWD}/efiboot.img
mkdosfs -F 32 /dev/loop3
rm -rf ${CWD}/efimount
mkdir ${CWD}/efimount
mount /dev/loop3 ${CWD}/efimount
cp -a --verbose ${CWD}/sources/efi/* ${CWD}/efimount
cp -a --verbose ${SLACKROOT}/kernels/huge.s/*zImage ${CWD}/efimount/EFI/BOOT/huge.s
cp -a ${CWD}/initrd.img ${CWD}/efimount/EFI/BOOT/
umount /dev/loop3
losetup -d /dev/loop3

# Clean up:
rm -rf ${CWD}/efimount

}

############### Pre-process man pages ##########################################
process_manpages()
{
# We have to preprocess these, since we aren't about to ship groff on here.
if [ -d usr/man ]; then
  echo "--- Pre-processing man pages ---"
  ( cd usr/man
    for manpagedir in $(find . -type d -name "man*") ; do
      ( cd $manpagedir
        for eachpage in $( find . -type f -maxdepth 1) ; do
          echo -n "$eachpage "
          # bzip2 is best for text (among gzip, bzip2, and xz tested)
          /bin/gunzip -c "$eachpage" | /usr/bin/gtbl | /usr/bin/groff -mandoc -Tlatin1 | bzip2 -9c > "$(dirname $eachpage)/$(basename $eachpage .gz).bz2"
          rm -f "$eachpage"
        done
      )
    done
  echo
  )
fi
}
# End pre-process man pages

############### Copy man pages #################################################
copy_manpages()
{
# We will only include the man pages that are copied here.
if [ -d usr/man ]; then
  echo "--- Copying desired man pages ---"
  ( cd usr
    mv man man.full
    mkdir man
    # List every man page to include in the loop below.
    # Pages should be preprocessed text files compressed with bzip2.
    # Note that they can be any cattable text file and need not be true
    # man page format...  perhaps handy for future documentation, or
    # README_LVM, etc. ?
    for manpage in \
      man8/cfdisk.8.bz2 \
      man8/fdisk.8.bz2 \
      man8/gdisk.8.bz2 \
      man8/partprobe.8.bz2 \
      man8/parted.8.bz2 \
      man8/partx.8.bz2 \
      man8/sfdisk.8.bz2 \
      man8/sgdisk.8.bz2 \
      man8/mount.8.bz2 \
      man1/lsattr.1.bz2 \
      man1/chattr.1.bz2 \
      man8/e2image.8.bz2 \
      man8/badblocks.8.bz2 \
      man8/fsck.8.bz2 \
      man8/e2fsck.8.bz2 \
      man8/mke2fs.8.bz2 \
      man8/tune2fs.8.bz2 \
      man5/mke2fs.conf.5.bz2 \
      man5/e2fsck.conf.5.bz2 \
      man8/btrfs.8.bz2 \
      man8/mkfs.btrfs.8.bz2 \
      man8/jfs_mkfs.8.bz2 \
      man8/jfs_fsck.8.bz2 \
      man8/pvdisplay.8.bz2 \
      man8/vgchange.8.bz2 \
      man8/pvck.8.bz2 \
      man8/lvmsar.8.bz2 \
      man8/lvresize.8.bz2 \
      man8/lvrename.8.bz2 \
      man8/vgs.8.bz2 \
      man8/pvresize.8.bz2 \
      man8/vgexport.8.bz2 \
      man8/vgsplit.8.bz2 \
      man8/pvcreate.8.bz2 \
      man8/vgreduce.8.bz2 \
      man8/vgck.8.bz2 \
      man8/pvchange.8.bz2 \
      man8/vgdisplay.8.bz2 \
      man8/pvremove.8.bz2 \
      man8/vgremove.8.bz2 \
      man8/vgmerge.8.bz2 \
      man8/vgextend.8.bz2 \
      man8/lvchange.8.bz2 \
      man8/vgcfgbackup.8.bz2 \
      man8/lvreduce.8.bz2 \
      man8/lvscan.8.bz2 \
      man8/lvs.8.bz2 \
      man8/dmsetup.8.bz2 \
      man8/vgimport.8.bz2 \
      man8/pvscan.8.bz2 \
      man8/lvcreate.8.bz2 \
      man8/vgrename.8.bz2 \
      man8/lvdisplay.8.bz2 \
      man8/vgimportclone.8.bz2 \
      man8/lvextend.8.bz2 \
      man8/lvremove.8.bz2 \
      man8/vgcfgrestore.8.bz2 \
      man8/lvmconf.8.bz2 \
      man8/lvmdiskscan.8.bz2 \
      man8/lvmdump.8.bz2 \
      man8/vgcreate.8.bz2 \
      man8/vgscan.8.bz2 \
      man8/pvmove.8.bz2 \
      man8/lvmchange.8.bz2 \
      man8/vgmknodes.8.bz2 \
      man8/fsadm.8.bz2 \
      man8/vgconvert.8.bz2 \
      man8/lvconvert.8.bz2 \
      man8/lvm.8.bz2 \
      man8/lvmsadc.8.bz2 \
      man8/dmeventd.8.bz2 \
      man8/pvs.8.bz2 \
      man5/lvm.conf.5.bz2 \
      man8/cryptsetup.8.bz2 \
      man8/mdmon.8.bz2 \
      man8/mdadm.8.bz2 \
      man8/mkreiserfs.8.bz2 \
      man8/mkfs.xfs.8.bz2 \
      man8/installpkg.8.bz2 \
      man8/removepkg.8.bz2 \
      man8/pkgtool.8.bz2 \
      man8/mkfs.minix.8.bz2 \
      man8/mkdosfs.8.bz2 \
      man8/fdformat.8.bz2 \
      man1/grep.1.bz2 \
      man1/wc.1.bz2 \
      man1/chroot.1.bz2 \
      man1/tar.1.bz2 \
      man1/chmod.1.bz2 \
      man1/ln.1.bz2 \
      man1/chown.1.bz2 \
      man1/sync.1.bz2 \
      man1/du.1.bz2 \
      man1/ddrescue.1.bz2 \
      man1/dd.1.bz2 \
      man8/ifconfig.8.bz2 \
      man8/route.8.bz2 \
      man1/hostname.1.bz2 \
      man8/arp.8.bz2 \
      man8/netstat.8.bz2 \
      man8/ipmask.8.bz2 \
      man8/rarp.8.bz2 \
      man8/mii-tool.8.bz2 \
      man8/nameif.8.bz2 \
      man8/findmnt.8.bz2 \
      man8/lsblk.8.bz2 \
      man8/fsfreeze.8.bz2 \
      man8/fstrim.8.bz2 \
      man8/swaplabel.8.bz2 \
      man8/ip.8.bz2 \
      man1/nano.1.bz2 \
      man8/zerofree.8.bz2 \
      man1/lzip.1.bz2 \
      man1/plzip.1.bz2 \
      man1/neofetch.1.bz2 \
    ; do
      mkdir -p man/$(dirname $manpage)
      cp -a man.full/$manpage man/$manpage
    done
    # Delete the pages that will not be included:
    rm -rf man.full
    # Create cat directories:
    ( cd man
      for mandir in man* ; do
        ln -sf $mandir cat$(echo $mandir | cut -b4-)
      done
    )
  )
fi
}
# End copy man pages

############### Time to call all our functions #################################

############### Time to call all our functions #################################

if [ $SHOWHELP -eq 1  ]; then
  basic_usage
  exit
fi

# Clean build environment:
rm -rf $TMP $PKG
mkdir -p $TMP $PKG
rm -f $CWD/initrd*.img $CWD/usbboot.img
rm -f $CWD/isolinux.cfg ${CWD}/pxelinux.cfg_default

if [ $DUMPSKELETON -eq 1 ]; then
  create_installer_fs
  extract_skeleton_fs
  zipup_installer_skeleton
else
  cat <<-EOT

	** Building software for: ARCH='$ARCH'
	** This host's specs:     machine type='$(uname -m)'
	**                        processor='$(uname -p)'
	**                        hardware platform"='$(uname -i)'
	** Waiting 3 seconds or just press ENTER now :-)

	EOT
  read -p "..." -t 3
  echo
  # Are we re-compiling busybox/dropbear and populating with binaries?
  if [ $RECOMPILE -eq 1 ]; then
    create_installer_fs
    if ! use_installer_source ; then
      extract_skeleton_fs
    fi
    build_busybox || exit 1
    build_dropbear || exit 1
    import_binaries || exit 1
    import_libraries || exit 1
    arch_specifics
  else
    unpack_oldinitrd
  fi

  # Are we adding the nano editor?
  if [ $ADD_NANO -eq 1 ]; then
    build_nano
  fi

  # Are we adding network modules?
  if [ $ADD_NETMODS -eq 1 ]; then
    add_netmods
  fi

  # Are we adding pcmcia modules?
  if [ $ADD_PCMCIAMODS -eq 1 ]; then
    add_pcmciamods
  fi

  if [ $ADD_NETMODS -eq 1 -o $ADD_PCMCIAMODS -eq 1 ]; then
    # If we added modules, we also need to add network card firmware:
    # but only if specified.  The default list of firmware is useless on ARM SoC systems.
    # The TrimSlice has a RealTek card which requires firmware, but currently the firmware
    # is compiled into the Kernel.  This will probably have to change later, but for now
    # it'll suffice.
    if [ $ADD_NETFIRMWARE -eq 1 ]; then
      add_netfirmware
    fi
    # If we added modules, compress them (if requested):
    compress_modules
    # If we added modules, check for missing dependencies:
    check_module_dependencies
  fi

  if [ $ADD_MANPAGES -eq 1 ]; then
    process_manpages
    copy_manpages
  fi

  # Finally, create the Slackware installer initrd
  create_initrd

  # If you wanted a USB boot image as well, here it is:
  if [ $USBBOOT -eq 1 ]; then
    create_usbboot
  fi

  ## Commented out.  The usbboot.img handles EFI now.
  ## If you wanted an EFI boot image as well, here it is:
  #if [ $EFIBOOT -eq 1 ]; then
  #  create_efiboot || exit 1
  #fi

fi

