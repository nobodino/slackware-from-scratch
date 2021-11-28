#!/bin/bash
# a-devs-uninstaller-1.0-noarch.txz:  Added.
# devs-2.3.1-noarch-25.txz:  Removed.
mount --bind / /mnt/tmp
ROOT=/mnt/tmp removepkg devs
rm -f /mnt/tmp/dev/*
