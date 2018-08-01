#!/bin/bash
# Slackware installation as DVD. 
#
# Contains: non bootable DVD (only /source)
#
# Command used to create the ISO's for this DVD:
# (see also /isolinux/README.TXT on the DVD you'll burn from the ISO)
#
# modified by "nobodino" to only have the sources to build SFS or Slackware From Scratch 

# DVD

mkisofs -o slackware64-current-install-dvd.iso \
    -R -J -V "Slackware-current DVD" \
    -hide-rr-moved -hide-joliet-trans-tbl \
    -v -d -N -no-emul-boot -boot-load-size 4 -boot-info-table \
    -sort isolinux/iso.sort \
    -b isolinux/isolinux.bin \
    -c isolinux/isolinux.boot \
    -A "Slackware-current DVD - build 01_Aug_2018" \
    -x ./pasture -x ./testing  -x ./slackware64 -x ./EFI -x ./patches -x ./usb-and-pxe-installers -x ./kernels \
    .

