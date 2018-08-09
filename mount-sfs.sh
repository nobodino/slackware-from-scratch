#/bin/sh
mount -v --bind /dev $SFS/dev
mount -vt devpts devpts $SFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $SFS/proc
mount -vt sysfs sysfs $SFS/sys
mount -vt tmpfs tmpfs $SFS/run
if [ -h $SFS/dev/shm ]; then
  mkdir -pv $SFS/$(readlink $SFS/dev/shm)
fi
