#!/bin/sh
# A script to increment build numbers.
# Call it with the list of the build numbers to increase by one:
#
# ./increment.sh xf86-input-acecad xf86-input-aiptek xf86-input-joystick
#
# If a build file does not exist, it will be created with a value of 2.

for build in $* ; do
  if [ ! -r $build ]; then
    echo "Creating $build with value 2"
    echo 2 > $build
  else
    echo "Incrementing $build $(cat $build) -> $(expr $(cat $build) + 1)"
    echo $(expr $(cat $build) + 1) > $build
  fi
done
