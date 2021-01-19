#######################  export_variables.sh ###################################
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
#
#--------------------------------------------------------------------------
#
#	Above july 2018, revisions made through github project: 
#   https://github.com/nobodino/slackware-from-scratch 
#
##########################################################################
# set -x
#*******************************************************************
# the rsync mirror from which you get the slackware source tree
#*******************************************************************
# export RSYNCDIR=rsync://mirror.slackbuilds.org/slackware/slackware-current
# export RSYNCDIR=rsync://mirrors.slackware.bg/slackware/slackware-current
# export RSYNCDIR=rsync://slackware.uk/slackware/slackware64-current
# export RSYNDIR=rsync://rsync.slackware.no/slackware/slackware64-current/
export RSYNCDIR=rsync://bear.alienbase.nl/mirrors/slackware/slackware64-current
#*******************************************************************
# the mirrors from which we download files to populate "others" directly
#*******************************************************************
export DLDIR2=ftp://slackware.uk/slackware/slackware-14.1
export DLDIR3=ftp://slackware.uk/slackware/slackware-14.2
export DLDIR4=ftp://slackware.uk/slackware/slackware64-14.1
export DLDIR5=ftp://slackware.uk/slackware/slackware64-14.2
export DLDIR6=http://mirror.eu.oneandone.net/linux/distributions/gentoo/gentoo/distfiles
# export DLDIR9=https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jre-8u202-linux-i586.tar.gz
# export DLDIR10=https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jre-8u202-linux-x64.tar.gz
export DLDIR11=https://slackbuilds.org/slackbuilds/14.2
export DLDIR12=https://github.com/nobodino/slackware-from-scratch/trunk/packages_for_aaa_elflibs
export DLDIR13=https://github.com/nobodino/slackware-from-scratch/trunk
#*******************************************************************
# jdk and ada versions
#*******************************************************************
# export ISLVER="0.18"
# export JDK="8u202"
export GNAT_x86="gnat-gpl-2014-x86-linux-bin.tar.gz"
export GNAT_x86_64="gnat-gpl-2017-x86_64-linux-bin.tar.gz"
export GREEN="\\033[1;32m"
export NORMAL="\\033[0;39m"
export RED="\\033[1;31m"
export BLUE="\\033[1;34m"
export YELLOW="\\033[1;33m"
#*******************************************************************
