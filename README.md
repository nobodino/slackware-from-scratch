# slackware-from-scratch
 
This memo describes how to build SFS or slackware from scratch with a small set
of scripts.

To begin with, when it's the first time you use these scripts, you have to do 
the following things.

nota: you need to be root to execute the main operations bellow, and work in 
kconsole otherwise you won't be able to build firefox/thunderbird ("unable to
setupterm" in others kind of console: don't know why this particularity).

1/ create a partition where your system will be built on:

# mount -t auto /dev/sdb2 /mnt/sfs 
(for example see your "generate_fstab" in "sfs-bootstraps.sh")
# export SFS=/mnt/sfs
# mkdir -pv $SFS/sources
# mkdir -pv $SFS/tools
# cd $SFS/sources

2/ git clone the scripts of the project:

# git clone https://github.com/nobodino/slackware-from-scratch.git
# chmod +x *.sh

3/ edit sfs-boostrap.sh to adjust your fstab caracteristics, root partition
and swap partition. In the example the options for the root partition are 
applicable to my ssd disk "defaults,noatime,discard", it may not be applicable
to your disk if a standard HDD.

3/ edit "export_variable.sh" to adjust PATDIR, DNDIR1, RDIR1 and RDRIR3, 
RSYNCDIR.

nota: on this version of sfs-bootsrap.sh, building slackware-14.2 is no more
applicable.

# export PATDIR=/mnt/ext4/sda4/sfs (for example)
# mkdir -pv $PATDIR/tools (to store the "tools" build further on x86)
# mkdir -pv $PATDIR/tools_64  (to store the "tools" build further on x86_64)
# mkdir -pv $PATDIR/others  (to store what the sub-script of "sfs-bootstarp.sh"
grab to "populate_others" get the different repositories)

4/ for now you are ready to begin to build slackware from scratch:

# ./sfs-bootsrap.sh

Two kinds of choice: "slackware" or "quit"
Three kinds of choice: "x86", "x86_64" or "quit"
It will generates the different patches.
Then it will clean up the previous installation building if you built one.
Then two kinds of choice: "rsync" or "quit". At that moment it will rsync with a 
slackware distant rsync repository. At the first building it can take some time
if your ADSL line (or other way to access internet) is not very performant (for
me it's about 2 Mb/s).
Local upgrade is not active on that version, I prefer rsyncing every time I can,
no more local repository on my machine.
Then it will alter the sources with patches necessary for "two pass building" 
packages: you'd better accept the choice than not.
Then it well generate the 4 lists of packages which are for the following
purpose:
- list1 : a bare system just able to boot
- list2: a bare x11 system
- lists3: system with xfce  but no web browser You can build firefox,
seamonkey and thunderbird : everything is in, to build them.
- list4: build4 the rest of the available packages of slackware till the end.

5/ If it's the first time you use SFS, you will have build the "tools" which are
compulsory to build SFS. It will use the "sfs-tools-current.sh" script.
In the available version building gnat-ada embedded has been disabled, it 
works but when building SFS the system doesn't seem to see the gnat compiler, 
maybe someone will be able to make it work, so that the "pre-gcc" and "post-gcc"
won't be necessary anymore.
Once the tools finished you can save the "tools" built by doing what's following.

In another console:
# cd /mnt/sfs
# chown -R root:root tools/
# tar czf tools.tar.gz tools/
# move it to $PATDIR/tools (for x86)  or $PATDIR/tools_64 (for x86_64)

6/ from now you can build SFS either piece of software by piece of software 
or completely with a unique script "full-sfs.sh".

Either by executing:
# time (./sfsbuild1.sh build1_s.list)

Either by executing:
# time (./full-sfs.sh)

On my machine the full build takes about 15 hours.
Your connection to internet must be active.

7/ at the end of the building, adjust "my_profile.sh" to your needs, and 
execute the script before rebooting. You wil have update grub so that your boot
loader sees your new system.

8/ the 3 following scripts are for:
- if rebooted after building the list1 to see if the system works do the
following:

# cd $SFS/sources
# ./mount-sfs.sh
# ./chroot1.sh
# cd /sources
You can go on building your system.

# at the end to umount the $SFS/{dev,run,proc,sys}
# ./umount-sfs.sh 



