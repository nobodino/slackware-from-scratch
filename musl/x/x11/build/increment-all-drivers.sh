#!/bin/sh
# A script to increment build numbers of all the drivers.
# This is used when upgrading to a new major version of the X server.
#
# Any drivers that are newly added should not have a build file in
# here (or it should contain "1").  The usual method is to run this
# script and then remove the build files for any new driver versions.

for DRVSRC in ../src/driver/* ; do
  DRVBASENAME=$(basename $DRVSRC | rev | cut -f 2- -d - | rev)
  ./increment.sh $DRVBASENAME
done

