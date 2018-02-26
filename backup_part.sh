#!/bin/bash -x
if [ $# -ne 2 ]
then
        #exit 1
	echo a
fi
export BACKUPPATH=/backup
export BACKUPOUTPUT=$BACKUPPATH/$(date +"%Y%m%d%H%M%S")
export VG=ubuntu-vg
mkdir -p $BACKUPOUTPUT
cd $BACKUPOUTPUT
function dobackup() {

	lvcreate -s -n snap -L 5G $1/$2
	e2fsck -f /dev/$1/snap
	tune2fs -U $(uuidgen ) /dev/$1/snap
	partclone.ext4 -o - -c -s /dev/$1/snap | pigz -p $(lscpu | grep ^CPU\( | awk '{print $2}') | split  -b 1G - $BACKUPOUTPUT/$2.
	lvremove $1/snap -f
}

lvs $VG | egrep -vw "backup|home|LV|swap_1" |awk '{print $1 " " $2 }'| tail -n $( expr $(lvs $VG | wc -l ) - 1 ) |while read  lv vg; do dobackup $vg $lv;done
grep /boot /proc/mounts  | \
awk '{print $1 " " $2}' | \
while read device mountpoint fstype
do 
	umount $mountpoint
	partclone.$fstype -o - -c -s $device | pigz -p  $(lscpu | grep ^CPU\( | awk '{print $2}') | split  -b 1G - boot.
	mount $mountpoint
done
