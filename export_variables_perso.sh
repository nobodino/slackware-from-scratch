#######################  export_variables.sh ###################################
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
#
#--------------------------------------------------------------------------
#
#	Above july 2018, revisions made through github project: https://github.com/nobodino/slackware-from-scratch 
#
##########################################################################
# set -x
#*******************************************************************
# VARIABLES to be set by the user
#*******************************************************************
# the directory where will be built slackware from scratch
#*******************************************************************
export SFS=/mnt/sfs
#******************************************************************
# the directory where you store eveything about sfs (tools, others...)
#*******************************************************************
export PATDIR=/mnt/ext4/sda4/sfs
#*******************************************************************
# the directory where are stored everything else slackware (gnuada, SBo..)
#*******************************************************************
export DNDIR1=/mnt/ext4/sda4/sfs/others
#*******************************************************************
# the directory where is stored the resynced slackware sources
#*******************************************************************
export RDIR1=/mnt/ext4/sda4/home/ftp/pub/Linux/Slackware/slackware-current
export RDIR3=/mnt/ext4/sda4/home/ftp/pub/Linux/Slackware/slackware64-current
export RDIR5=/mnt/dvd
#*******************************************************************
#*******************************************************************
# the directory where will be copied the slackware sources from RDIR
#*******************************************************************
export SRCDIR=$SFS/slacksrc
#*******************************************************************
# the directory where will be stored the patches necessary to build SFS
#*******************************************************************
export PATCHDIR=$SFS/sources/patches
#******************************************************************
