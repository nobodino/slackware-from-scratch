#!/bin/bash
# $Id: usbimg2disk.sh,v 1.23 2012/09/03 20:52:31 eha Exp eha $
#
# Copyright 2009, 2010, 2011, 2012  Eric Hameleers, Eindhoven, NL
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

# Paranoid as usual:
set -e

# Define some variables ahead of time, so that cleanup knows about them:
MNTDIR1=""
MNTDIR2=""
MNTDIR3=""

# Clean up in case of failure:
cleanup() {
  # Clean up by unmounting our loopmounts, deleting tempfiles:
  echo "--- Cleaning up the staging area..."
  sync
  [ ! -z "${MNTDIR1}" ] && ( umount -f ${MNTDIR1} ; rmdir $MNTDIR1 )
  [ ! -z "${MNTDIR2}" ] && ( umount -f ${MNTDIR2} ; rmdir $MNTDIR2 )
  [ ! -z "${MNTDIR3}" ] && rm -rf ${MNTDIR3} || true
}
trap 'echo "*** $0 FAILED at line $LINENO ***"; cleanup; exit 1' ERR INT TERM

showhelp() {
  echo "# "
  echo "# Purpose #1: to use the content of Slackware's usbboot.img and"
  echo "#   transform a standard USB thumb drive with a single vfat partition"
  echo "#   into a bootable medium containing the Slackware Linux installer."
  echo "# "
  echo "# Purpose #2: to use the contents of a Slackware directory tree"
  echo "#   and transform a standard USB thumb drive with"
  echo "#   a single vfat partition and 2GB of free space into"
  echo "#   a self-contained USB installation medium for Slackware Linux."
  echo "# "
  echo "# "
  echo "# Your USB thumb drive may contain data!"
  echo "# This data will *not* be overwritten, unless you have"
  echo "#   explicitly chosen to format the drive by using the '-f' parameter."
  echo "# "
  echo "# $(basename $0) accepts the following parameters:"
  echo "#   -h|--help                  This help"
  echo "#   -f|--format                Format the USB drive before use"
  echo "#   -i|--infile <filename>     Full path to the usbboot.img file"
  echo "#   -l|--logfile <filename>    Optional logfile to catch fdisk output"
  echo "#   -o|--outdev <filename>     The device name of your USB drive"
  echo "#   -s|--slackdir <dir>        Use 'dir' as the root of Slackware tree"
  echo "#   -u|--unattended            Do not ask any questions"
  echo "#   -L|--label <labelname>     FAT label when formatting the USB drive"

  echo "# "
  echo "# Examples:"
  echo "# "
  echo "# $(basename $0) -i ~/download/usbboot.img -o /dev/sdX"
  echo "# $(basename $0) -f -s /home/ftp/pub/slackware-13.0 -o /dev/sdX"
  echo "# "
  echo "# The second example shows how to create a fully functional Slackware"
  echo "# installer on a USB stick (it needs a Slackware tree as the source)."
  echo "# "
}

reformat() {
  # Commands to re-create a functional USB stick with VFAT partition:
  # two parameters:
  #  (1) the name of the USB device to be formatted:
  #  (2) FAT label to use when formatting the USB device:
  local TOWIPE="$1"
  local THELABEL="$2"

  # Sanity checks:
  if [ ! -b $TOWIPE ]; then
    echo "*** Not a block device: '$TOWIPE' !"
    exit 1
  fi

  # Wipe the MBR:
  dd if=/dev/zero of=$TOWIPE bs=512 count=1

  # Temporarily accept errors (so that we can examine them):
  set +e

  # create a FAT32 partition (type 'b')
  /sbin/fdisk $TOWIPE <<EOF
n
p
1


t
b
w
EOF

  # Check if fdisk gave an error (like "error closing file").
  # Some desktop environments auto-mount the partition on sight...:
  if [ $? -ne 0 ]; then
    echo "*** The fdisk command had an error."
    echo "*** Some desktop environments (KDE, GNOME) may automatically mount"
    echo "*** the new FAT partition on your USB drive, causing the fdisk error."
    if [ $UNATTENDED -eq 0 ]; then
      # if we are running interactively, allow to chicken out now:
      echo "*** Perhaps you want to format the device '$TOWIPE' yourself first?"
      read -p "*** Press ENTER to continue anyway or Ctrl-C to quit now: " JUNK
    fi
  fi

  # Fail on errors again:
  set -e

  if mount | grep -q ${TOWIPE}1 ; then
    echo "--- Un-mounting ${TOWIPE}1 because your desktop auto-mounted it..."
    umount -f ${TOWIPE}1
  fi

  # We set the fat label to '$THELABEL' when formatting.
  # It will enable the installer to mount the fat partition automatically
  # and pre-fill the correct pathname for the "SOURCE" dialog.
  # Format with a vfat filesystem:
  /sbin/mkdosfs -F32 -n ${THELABEL} ${TOWIPE}1
}

makebootable() {
  # Only parameter: the name of the USB device to be set bootable:
  USBDRV="$1"

  # Sanity checks:
  if [ ! -b $USBDRV ]; then
    echo "*** Not a block device: '$USBDRV' !"
    exit 1
  fi

  # Set the bootable flag for the first partition:
  /sbin/sfdisk -A $USBDRV 1
}

# Parse the commandline parameters:
if [ -z "$1" ]; then
  showhelp
  exit 1
fi
while [ ! -z "$1" ]; do
  case $1 in
    -f|--format)
      REFORMAT=1
      shift
      ;;
    -h|--help)
      showhelp
      exit
      ;;
    -i|--infile)
      USBIMG="$(cd $(dirname $2); pwd)/$(basename $2)"
      shift 2
      ;;
    -l|--logfile)
      LOGFILE="$(cd $(dirname $2); pwd)/$(basename $2)"
      shift 2
      ;;
    -o|--outdev)
      TARGET="$2"
      TARGETPART="${TARGET}1"
      shift 2
      ;;
    -s|--slackdir)
      REPODIR="$2"
      FULLINSTALLER="yes"
      shift 2
      ;;
    -u|--unattended)
      UNATTENDED=1
      shift
      ;;
    -L|--label)
      CUSTOMLABEL="$2"
      shift 2
      ;;
    *)
      echo "*** Unknown parameter '$1'!"
      exit 1
      ;;
  esac
done

# Before we start:
[ -x /bin/id ] && CMD_ID="/bin/id" || CMD_ID="/usr/bin/id"
if [ "$($CMD_ID -u)" != "0" ]; then
  echo "*** You need to be root to run $(basename $0)."
  exit 1
fi

# Check existence of the package repository if that was passed as a parameter:
if [ -n "$REPODIR" ]; then
  if [ ! -d "$REPODIR" ]; then
    echo "*** This is not a directory: '$REPODIR' !"
    exit 1
  else
    # This also takes care of stripping a trailing '/', which is required
    # for the rsync command to work as intended:
    REPOSROOT="$(cd $(dirname $REPODIR); pwd)/$(basename $REPODIR)"
  fi
fi

# Check FAT label:
if [ -n "${CUSTOMLABEL}" ]; then
  if [ "x$(echo "${CUSTOMLABEL}"| tr -d '[:alnum:]._-')" != "x" ]; then
    echo "*** FAT label '${CUSTOMLABEL}' is not an acceptible name!"
    exit 1
  elif [ ${#CUSTOMLABEL} -gt 11 ]; then
    echo "*** FAT label '${CUSTOMLABEL}' must be less than 12 characters!"
    exit 1
  else
  FATLABEL="${CUSTOMLABEL}"
  fi
else
  FATLABEL="USBSLACKINS"
fi

# Prepare the environment:
MININSFREE=2200               # minimum in MB required for a Slackware tree
UNATTENDED=${UNATTENDED:-0}   # unattended means: never ask questions.
REFORMAT=${REFORMAT:-0}       # do not try to reformat by default
LOGFILE=${LOGFILE:-/dev/null} # silence by default
EXCLUDES=${EXCLUDES:-"--exclude=source \
                      --exclude=extra/aspell-word-lists \
                      --exclude=isolinux \
                      --exclude=usb-and-pxe-installers \
                      --exclude=pasture"}  # not copied onto the stick

# If we have been given a Slackware tree, we will create a full installer:
if [ -n "$REPOSROOT" ]; then
  if [ -d "$REPOSROOT" -a -f "$REPOSROOT/PACKAGES.TXT" ]; then
    USBIMG=${USBIMG:-"$REPOSROOT/usb-and-pxe-installers/usbboot.img"}
    PKGDIR=$(head -40 $REPOSROOT/PACKAGES.TXT | grep 'PACKAGE LOCATION: ' |head -1 |cut -f2 -d/)
    if [ -z "$PKGDIR" ]; then
      echo "*** Could not find the package subdirectory in '$REPOSROOT'!"
      exit 1
    fi
  else
    echo "*** Directory '$REPOSROOT' does not look like a Slackware tree!"
    exit 1
  fi
fi

# More sanity checks:
if [ -z "$TARGET" -o -z "$USBIMG" ]; then
  echo "*** You must specify both the names of usbboot.img and the USB device!"
  exit 1
fi

if [ ! -f $USBIMG ]; then
  echo "*** This is not a useable file: '$USBIMG' !"
  exit 1
fi

if [ ! -b $TARGET ]; then
  echo "*** Not a block device: '$TARGET' !"
  exit 1
elif [ $REFORMAT -eq 0 ]; then
  if ! /sbin/blkid -t TYPE=vfat $TARGETPART 1>/dev/null 2>/dev/null ; then
    echo "*** I fail to find a 'vfat' partition: '$TARGETPART' !"
    echo "*** If you want to format the USB thumb drive, add the '-f' parameter"
    exit 1
  fi
fi

if mount | grep -q $TARGETPART ; then
  echo "*** Please un-mount $TARGETPART first, then re-run this script!"
  exit 1
fi

# Do not croak if we have a Slackware tree without sources:
if [ ! $(readlink -f ${REPOSROOT}/extra/java ) ]; then
   EXCLUDES="${EXCLUDES} --exclude=extra/java"
fi

# Check for prerequisites which may not always be installed:
MISSBIN=0
MBRBIN="/usr/lib/syslinux/mbr.bin"
if [ ! -r $MBRBIN ]; then MBRBIN="/usr/share/syslinux/mbr.bin"; fi
if [ ! -r $MBRBIN -o ! -x /usr/bin/syslinux ]; then
  echo "*** This script requires that the 'syslinux' package is installed!"
  MISSBIN=1
fi
if [ ! -x /usr/bin/mtools ]; then
  echo "*** This script requires that the 'floppy' (mtools) package is installed!"
  MISSBIN=1
fi
if [ ! -x /sbin/mkdosfs ]; then
  echo "*** This script requires that the 'dosfstools' package is installed!"
  MISSBIN=1
fi
if [ ! -x /bin/cpio ]; then
  echo "*** This script requires that the 'cpio' package is installed!"
  MISSBIN=1
fi
if [ $MISSBIN -eq 1 ]; then exit 1 ; fi

# Show the USB device's information to the user:
if [ $UNATTENDED -eq 0 ]; then
  [ $REFORMAT -eq 1 ] && DOFRMT="format and " || DOFRMT="" 

  echo ""
  echo "# We are going to ${DOFRMT}use this device - '$TARGET':"
  echo "# Vendor : $(cat /sys/block/$(basename $TARGET)/device/vendor)"
  echo "# Model  : $(cat /sys/block/$(basename $TARGET)/device/model)"
  echo "# Size   : $(( $(cat /sys/block/$(basename $TARGET)/size) / 2048)) MB"
  echo "# "
  echo "# FDISK OUTPUT:"
  /sbin/fdisk -l $TARGET | while read LINE ; do echo "# $LINE" ; done
  echo ""

  echo "***                                                       ***"
  echo "*** If this is the wrong drive, then press CONTROL-C now! ***"
  echo "***                                                       ***"

  read -p "Or press ENTER to continue: " JUNK
  # OK... the user was sure about the drive...
fi

# Initialize the logfile:
cat /dev/null > $LOGFILE

# If we need to format the USB drive, do it now:
if [ $REFORMAT -eq 1 ]; then
  echo "--- Formatting $TARGET with VFAT partition label '${FATLABEL}'..."
  if [ $UNATTENDED -eq 0 ]; then
    echo "--- Last chance! Press CTRL-C to abort!"
    read -p "Or press ENTER to continue: " JUNK
  fi
  ( reformat $TARGET ${FATLABEL} ) 1>>$LOGFILE 2>&1
else
  # We do not format the drive, but apply a FAT label if required.

  # Prepare for using mlabel to change the FAT label:
  MTOOLSRCFILE=$(mktemp -p /tmp -t mtoolsrc.XXXXXX)
  echo "drive s: file=\"$TARGETPART\"" > $MTOOLSRCFILE
  echo "mtools_skip_check=1" >> $MTOOLSRCFILE

  if [ -n "$CUSTOMLABEL" ]; then
    # User gave us a FAT label to use, so we will force that upon the drive:
    echo "--- Setting FAT partition label to '$FATLABEL'"
    MTOOLSRC=$MTOOLSRCFILE mlabel s:${FATLABEL}
  elif [ -n "$(/sbin/blkid -t TYPE=vfat -s LABEL -o export $TARGETPART)" ] ; then
    # User did not care, but the USB stick has a FAT label that we will use:
    eval $(/sbin/blkid -t TYPE=vfat -s LABEL -o export $TARGETPART)
    FATLABEL=$LABEL
    echo "--- Using current FAT partition label '$FATLABEL'"
    unset LABEL
  else
    # No user-supplied label, nor a drive label present. We apply our default:
    echo "--- Setting FAT partition label to '$FATLABEL'"
    MTOOLSRC=$MTOOLSRCFILE mlabel s:${FATLABEL}
  fi

  # Cleanup:
  rm -f $MTOOLSRCFILE
fi

# Create a temporary mount point for the image file:
mkdir -p /mnt
MNTDIR1=$(mktemp -d -p /mnt -t img.XXXXXX)
if [ ! -d $MNTDIR1 ]; then
  echo "*** Failed to create a temporary mount point for the image!"
  exit 1
else
  chmod 711 $MNTDIR1
fi

# Create a temporary mount point for the USB thumb drive partition:
MNTDIR2=$(mktemp -d -p /mnt -t usb.XXXXXX)
if [ ! -d $MNTDIR2 ]; then
  echo "*** Failed to create a temporary mount point for the usb thumb drive!"
  exit 1
else
  chmod 711 $MNTDIR2
fi

# Create a temporary directory to extract the initrd if needed:
MNTDIR3=$(mktemp -d -p /mnt -t initrd.XXXXXX)
if [ ! -d $MNTDIR3 ]; then
  echo "*** Failed to create a temporary directory to extract the initrd!"
  exit 1
else
  chmod 711 $MNTDIR3
fi

# Mount the image file:
mount -o loop,ro $USBIMG $MNTDIR1

# Mount the vfat partition:
mount -t vfat -o shortname=mixed $TARGETPART $MNTDIR2

# Do we have space to create a full Slackware USB install medium?
if [ "$FULLINSTALLER" = "yes" ]; then
  if [ $(df --block=1MB $TARGETPART |grep "^$TARGETPART" |tr -s ' ' |cut -f4 -d' ') -le $MININSFREE ]; then
    echo "*** The partition '$TARGETPART' does not have enough"
    echo "*** free space (${MININSFREE} MB) to create a Slackware installation medium!"
    cleanup
    exit 1
  fi
fi

# Check available space for a Slackware USB setup bootdisk:
USBFREE=$(df -k $TARGETPART |grep "^$TARGETPART" |tr -s ' ' |cut -d' ' -f4)
IMGSIZE=$(du -k $USBIMG |cut -f1)
echo "--- Available free space on the the USB drive is $USBFREE KB"
echo "--- Required free space for installer: $IMGSIZE KB"

# Exit when the installer image's size does not fit in available space:
if [ $IMGSIZE -gt $USBFREE ]; then
  echo "*** The USB thumb drive does not have enough free space!"
  # Cleanup and exit:
  cleanup
  exit 1
fi

if [ $UNATTENDED -eq 0 ]; then
  # if we are running interactively, warn about overwriting files:
  if [ -n "$REPOSROOT" ]; then
    if [ -d $MNTDIR2/syslinux -o -d $MNTDIR2/$(basename $REPOSROOT) ]; then
      echo "--- Your USB drive contains directories 'syslinux' and/or '$(basename $REPOSROOT)'"
      echo "--- These will be overwritten.  Press CTRL-C to abort now!"
      read -p "Or press ENTER to continue: " JUNK
    fi
  else
    if [ -d $MNTDIR2/syslinux ]; then
      echo "--- Your USB drive contains directory 'syslinux'"
      echo "--- This will be overwritten.  Press CTRL-C to abort now!"
      read -p "Or press ENTER to continue: " JUNK
    fi
  fi
fi

# Copy boot image files to the USB disk in its own subdirectory '/syslinux':
echo "--- Copying boot files to the USB drive..."
mkdir -p $MNTDIR2/syslinux
cp -R $MNTDIR1/* $MNTDIR2/syslinux/
rm -f $MNTDIR2/syslinux/ldlinux.sys

# If we are creating a full Slackware installer, there is a lot more to do:
if [ "$FULLINSTALLER" = "yes" ]; then
  # Extract the Slackware initrd for modifications we have to do:
  echo "--- Extracting Slackware initrd.img..."
  ( cd ${MNTDIR3}/
    gunzip -cd ${MNTDIR2}/syslinux/initrd.img | cpio -i -d -H newc --no-absolute-filenames
  ) 2>>$LOGFILE

  # Modify installer files so that installing from USB stick will be easier:
  echo "--- Modifying installer files..."
  ( cd ${MNTDIR3}/
    # Try to automatically mount the installer partition:
    mkdir usbinstall
    echo "mount -t vfat -o ro,shortname=mixed \$(/sbin/blkid -t LABEL=$FATLABEL | cut -f1 -d:) /usbinstall 1>/dev/null 2>&1" >> etc/rc.d/rc.S
    # Adapt the dialogs so that pressing [OK] will be all there is to it:
    sed -i -e 's# --menu# --default-item 6 --menu#' usr/lib/setup/SeTmedia
    sed -i -e "s# 2> \$TMP/sourcedir# /usbinstall/$(basename $REPOSROOT)/$PKGDIR 2> \$TMP/sourcedir#" usr/lib/setup/INSdir
    FIXF=$(find usr/lib/setup -name SeTp*media)
    sed -i -e 's# --menu# --default-item 3 --menu#' $FIXF
  ) 2>>$LOGFILE

  # Recreate the initrd:
  echo "--- Gzipping the initrd image again:"
  chmod 0755 ${MNTDIR3}
  ( cd ${MNTDIR3}/
    find . |cpio -o -H newc |gzip > ${MNTDIR2}/syslinux/initrd.img
  ) 2>>$LOGFILE

  # Copy Slackware package tree (no sources) to the USB disk -
  # we already made sure that ${REPOSROOT} does not end with a '/'
  echo "--- Copying Slackware package tree to the USB drive..."
  rsync -rpthDL --delete $EXCLUDES $REPOSROOT $MNTDIR2/
fi

# Unmount/remove stuff:
cleanup

# Run syslinux and write a good MBR:
echo "--- Making the USB drive '$TARGET' bootable..."
( makebootable $TARGET ) 1>>$LOGFILE 2>&1
/usr/bin/syslinux -s -d /syslinux $TARGETPART 1>>$LOGFILE 2>&1
dd if=$MBRBIN of=$TARGET 1>>$LOGFILE 2>&1

# THE END
