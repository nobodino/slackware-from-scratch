#!/bin/bash
# set -x
if [ -f *.diff ]; then
	cat *.diff | patch -f -b -s *.SlackBuild --verbose 
	rm *.SlackBuild.rej
fi
