#######################  full-sfs.sh #############################
#!/bin/bash
#
# 
#  Revision 0 			25032018				nobodino
#     -initial release
#
#
#################################################################
# set -x

#!/bin/sh
./sfsbuild1.sh build1_s.list && ./sfsbuild1.sh build2_s.list && ./sfsbuild1.sh build3_s.list && ./sfsbuild1.sh build4_s.list
# ./sfsbuild1.sh build2_s.list && ./sfsbuild1.sh build3_s.list && ./sfsbuild1.sh build4_s.list
# ./sfsbuild1.sh build2_s.list && ./sfsbuild1.sh build3_s.list
# ./sfsbuild1.sh build4_s.list
# ./sfsbuild1.sh build1_s.list && ./sfsbuild1.sh build2_s.list && ./sfsbuild1.sh build3_s.list
# cd / && rm localtime
# cd /tmp
# rm *
# rm -rf /tmp/*
# cd /sources
