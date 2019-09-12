#!/bin/sh

# We'll expect device-name and index as a parameter

DEVICE=$1
INDEX=$2

JOURNAL_SIZE=4M
BLOCKSIZE=4096

VG=vgroot
LV_NAME=lv_ost_${INDEX}_jrnl

create_journal_fs () {
	if ! [ -L /dev/${VG}/${LV_NAME} ]
	then 
		echo Logival volume ${VG}/${LV_NAME} not created >> /dev/sdterr
	elif ( /usr/bin/lsblk /dev/${VG}/${LV_NAME} --fs -n | grep -q 'OST_.*_jrnl' )
	then 
		echo Lustre journal already created to /dev/${VG}/${LV_NAME} >> /dev/stderr
        exit 0
	else
		mkfs -t ext2 -b ${BLOCKSIZE} -O journal_dev -L OST_${INDEX}_jrnl /dev/${VG}/${LV_NAME}
	fi
}

create_lustre_fs () {
	if ( /usr/bin/lsblk ${DEVICE} --fs -n | grep -q 'lustre:OST00' )
	then
		echo Lustre fs already created to ${DEVICE} >> /dev/stderr
        exit 0
	else
		/usr/sbin/mkfs.lustre --fsname=lustre --mgsnode=10.2.20.10@o2ib --mgsnode=10.2.20.11@o2ib --ost --index=${INDEX} --mkfsoptions="-E stride=262144,stripe_width=262144 -i 8192 -J device=/dev/${VG}/${LV_NAME}" ${DEVICE}
	fi
}
create_journal_fs

create_lustre_fs

exit 2
