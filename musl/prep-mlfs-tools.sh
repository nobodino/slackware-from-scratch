#######################  prep-mlfs-tools.sh #####################################
#!/bin/bash
#
# Copyright 2018,2019,2020,2021  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018,2019,2020,2021  "nobodino", Bordeaux, FRANCE
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
#--------------------------------------------------------------------------
#
# Note: Much of this script is inspired from the LFS manual chapter 5
#       Copyright © 1999-2021 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
# script to prepare build 'tools' for Musl Slackware From Scratch (MLFS)
#
#*******************************************************************
# set -x
#*******************************************************************
# the directory where will be built Musl Slackware From Scratch
#*******************************************************************
export MLFS=/mnt/mlfs
#*******************************************************************
# the directory where will be stored the slackware source for MLFS
#*******************************************************************
export SRCDIR=$MLFS/sources
# MLFS_TGT=$(uname -m)-mlfs-linux-gnu
# export MLFS_TGT
#*******************************************************************
# define the target MLFS is built for
#*******************************************************************
case $(uname -m) in
   x86_64)  export MLFS_TARGET="x86_64-mlfs-linux-musl"
            export MLFS_ARCH="x86"
            export MLFS_CPU="x86-64"
            ;;
   i686)    export MLFS_TARGET="i686-mlfs-linux-musl"
            export MLFS_ARCH="x86"
            export MLFS_CPU="i686"
            ;;
esac
#*******************************************************************
# define the HOST MLFS is built on
#*******************************************************************
export MLFS_HOST="$(echo $MACHTYPE | sed "s/$(echo $MACHTYPE | cut -d- -f2)/cross/")"
#*******************************************************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#*******************************************************************

begin_mlfs () {
#*****************************
[ -d $MLFS/tools ] && rm -rf $MLFS/tools
mkdir -v $MLFS/tools
ln -sv $MLFS/tools /
mkdir -v $MLFS/cross-tools
ln -sv   $MLFS/cross-tools /
mkdir -v /home/mlfs/

groupadd mlfs 
useradd -s /bin/bash -g mlfs -m -k /dev/null mlfs

chown -v mlfs $MLFS/tools
chown -v  mlfs $MLFS/cross-tools
chown -Rv mlfs:mlfs $MLFS/sources
chmod -v  a+wt $MLFS/sources
}

generate_bash_profile () {
#*****************************
cat > /home/mlfs/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
}

generate_bashrc () {
#*****************************
cat > /home/mlfs/.bashrc << "EOF"
set +h
umask 022
MLFS=/mnt/mlfs
LC_ALL=POSIX
PATH=/tools/bin:/bin:/usr/bin
export MLFS LC_ALL MLFS_HOST MLFS_TARGET MLFS_ARCH MLFS_CPU PATH
unset CFLAGS
unset CXXFLAGS
EOF
}

source_bash_profile () {
#*****************************
echo
echo "By now, you're in the 'mlfs' environment."
echo
echo "Execute the 2 following commands:"
echo
echo -e "$YELLOW" "cd $MLFS/sources  && source ~/.bash_profile" "$NORMAL"
echo 
echo "and then:"
echo 
echo -e "$YELLOW"  "./mlfs-tools-current.sh"  "$NORMAL"
echo && su - mlfs
}

tools_test () {
#*****************************
	if [[ ! -f $PATDIR/$tools_dir/tools.tar.?z ]]; then
		cat <<- EndofText
	
		A copy of "tools.tar.?z" has been found.
		if you wish to untar this for your tools directory, select "old"
		otherwise select "new" to build a new tools directory.
		If you desire to quit, select "quit"

		EndofText

		PS3="Your choice: "
		select new_tools in old new quit; do
			case $new_tools in
				old  ) return 0 ;;
				new  ) return 1 ;;
				*    ) return 2 ;;
			esac
		done
	else
		return 1
	fi
}

get_tools_dir () {
#****************************
	cd $MLFS
	echo "

	Untarring tools.tar.?z
	"
	tar xf $PATDIR/$tools_dir/tools.tar.?z

	echo "

	The tools directory has been installed and /tools link remade!
	"

	cd -
}


#*****************************
# core script
#*****************************
tools_test
tool_sel=$?
if [[ $tool_sel == 0 ]]; then
	get_tools_dir
	echo
elif [[ $tool_sel == 1 ]]; then
	begin_mlfs
	generate_bash_profile
	generate_bashrc
	source_bash_profile
	exit 0  # note: this quits shell owned by mlfs user.
else 		# [[ $tools_test == 3 ]]
	exit 1	# note: this quits mlfs-bootstrap.sh
fi


