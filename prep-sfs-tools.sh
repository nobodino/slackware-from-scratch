#######################  prep-sfs-tools.sh #####################################
#!/bin/bash
#
# Copyright 2018  J. E. Garrott Sr, Puyallup, WA, USA
# Copyright 2018  "nobodino", Bordeaux, FRANCE
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
#       Copyright © 1999-2018 Gerard Beekmans and may be
#       copied under the MIT License.
#
#--------------------------------------------------------------------------
# script to prepare build 'tools' for Slackware From Scratch (SFS)
#
# Revision 	0 		24092016		nobodino
# Revision 	1 		25032018		nobodino
#		-modified with jeg version to allow to keep old "tools.tar.?z"
# Revision 	2 		31032018		nobodino
#		-removed a second symlink "ln -sv $SFS/tools /" in get_tools_dir
#
#	Above july 2018, revisions made through github project: https://github.com/nobodino/slackware-from-scratch 
#
#*******************************************************************
# set -x
#*******************************************************************
# the directory where will be built slackware from scratch
#*******************************************************************
export SFS=/mnt/sfs
#*******************************************************************
# the directory where will be stored the slackware source for SFS
#*******************************************************************
export SRCDIR=$SFS/sources
SFS_TGT=$(uname -m)-sfs-linux-gnu
export SFS_TGT
#*******************************************************************
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export PINK="\\033[1;35m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#*******************************************************************

begin_sfs () {
#*****************************
[ -d $SFS/tools ] && rm -rf $SFS/tools
mkdir -v $SFS/tools
ln -sv $SFS/tools /
mkdir -v /home/sfs/

groupadd sfs 
useradd -s /bin/bash -g sfs -m -k /dev/null sfs

chown -v sfs $SFS/tools
chown -Rv sfs:sfs $SFS/sources
}

generate_bash_profile () {
#*****************************
cat > /home/sfs/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
}

generate_bashrc () {
#*****************************
cat > /home/sfs/.bashrc << "EOF"
set +h
umask 022
SFS=/mnt/sfs
LC_ALL=POSIX
SFS_TGT=$(uname -m)-sfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export SFS LC_ALL SFS_TGT PATH
EOF
}

source_bash_profile () {
#*****************************
echo
echo "You have prepared the environment to build tools for Slackware."
echo
echo "Execute the following commands:"
echo
echo -e "$YELLOW" "cd $SFS/sources  && source ~/.bash_profile" "$NORMAL"
echo 
echo "then:"
echo 
echo -e "$YELLOW"  "./sfs-tools-current.sh"  "$NORMAL"
echo
su - sfs
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
	cd $SFS
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
	begin_sfs
	generate_bash_profile
	generate_bashrc
	source_bash_profile
	exit 0  # note: this quits shell owned by sfs user.
else 		# [[ $tools_test == 3 ]]
	exit 1	# note: this quits sfs-bootstrap.sh
fi


