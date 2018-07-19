#!/bin/bash -x
if [ $# -ne 1 ]
then
        exit 1
	#echo a
fi
export BACKUPPATH=$1
export BACKUPOUTPUT=$BACKUPPATH/$(date +"%Y%m%d%H%M%S")
export VG=linux
mkdir -p $BACKUPOUTPUT
cd $BACKUPOUTPUT
function dobackup() {

	#lvcreate -s -n snap -L 500M $1/$2
	lvcreate -s -n snap -L 5G $1/$2
	e2fsck -f /dev/$1/snap
	tune2fs -U $(uuidgen ) /dev/$1/snap
	partclone.ext4 -o - -c -s /dev/$1/snap | pigz -p $(lscpu | grep ^CPU\( | awk '{print $2}') | split  -b 1G - $BACKUPOUTPUT/$2.
	lvremove $1/snap -f
}

lvs $VG | egrep -vw "bkp|backup|home|LV|swap_1" |awk '{print $1 " " $2 }'| tail -n $( expr $(lvs $VG | wc -l ) - 1 ) |while read  lv vg; do dobackup $vg $lv;done
umount /boot/efi
umount /boot
partclone.ext2 -o - -c -s /dev/sda1 | pigz -p  $(lscpu | grep ^CPU\( | awk '{print $2}') | split  -b 1G - boot.
partclone.vfat -o - -c -s /dev/sda2 | pigz -p  $(lscpu | grep ^CPU\( | awk '{print $2}') | split  -b 1G - boot.efi.
mount /boot
mount /boot/efi
#grep /boot /proc/mounts  | \
#awk '{print $1 " " $2}' | \
#while read device mountpoint fstype
#do 
#	umount $mountpoint
#	echo partclone.ext2 -o - -c -s $device \| pigz -p  $(lscpu | grep ^CPU\( | awk '{print $2}') \| split  -b 1G - boot.
#	mount $mountpoint
#done
