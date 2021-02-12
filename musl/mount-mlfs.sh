#/bin/sh
mount -v --bind /dev $MLFS/dev
mount -vt devpts devpts $MLFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $MLFS/proc
mount -vt sysfs sysfs $MLFS/sys
mount -vt tmpfs tmpfs $MLFS/run
if [ -h $MLFS/dev/shm ]; then
  mkdir -pv $MLFS/$(readlink $MLFS/dev/shm)
fi
