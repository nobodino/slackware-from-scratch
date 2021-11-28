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
 ./sfsbuild1.sh build1.list && ./sfsbuild1.sh build2.list && ./sfsbuild1.sh build3.list && ./sfsbuild1.sh build4.list
# ./sfsbuild1.sh build2.list && ./sfsbuild1.sh build3.list && ./sfsbuild1.sh build4.list
# ./sfsbuild1.sh build2.list && ./sfsbuild1.sh build3.list
# ./sfsbuild1.sh build4.list
