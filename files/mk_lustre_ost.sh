#!/bin/bash

# We'll expect device-name and index as a parameter

LOKI=/tmp/mklustrefs.log
echo " === `date \"+%F %T\"` ===" >> $LOKI
echo "Sain parametrit $1 $2 $3" >> $LOKI
DEVICE=$1
INDEX=$2

JOURNAL_SIZE=4M
BLOCKSIZE=4096

VG=vgroot
#LV_NAME=lv_ost_${INDEX}_jrnl
if [[ "$3" == "No" ]]
then # We don't create journal for this device
    JOURNAL=""
else
    LV_NAME=$3
    JOURNAL="-J device=/dev/${VG}/$3"
fi


create_journal_fs () {
	if [[ ! -L /dev/${VG}/${LV_NAME} ]]
	then 
		echo Logival volume ${VG}/${LV_NAME} not created >> $LOKI
        return 9
	elif ( /usr/bin/lsblk /dev/${VG}/${LV_NAME} --fs -n | grep -q 'OST_.*_jrnl' )
	then 
		echo Lustre journal already created to /dev/${VG}/${LV_NAME} >> $LOKI
        return 0
	else
        echo "Creating journal /dev/${VG}/${LV_NAME}" >> $LOKI
		mkfs -t ext2 -b ${BLOCKSIZE} -O journal_dev -L OST_${INDEX}_jrnl /dev/${VG}/${LV_NAME}
	fi
	return 2
}

create_lustre_fs () {
	if ( /usr/bin/lsblk ${DEVICE} --fs -n | grep -q 'lustre.OST00' )
	then
		echo Lustre fs already created to ${DEVICE} >> $LOKI
        return 0
	else
        echo "Creating lustrefs ${DEVICE}" >> $LOKI
		/usr/sbin/mkfs.lustre --replace --fsname=lustre --mgsnode=10.2.20.10@o2ib --mgsnode=10.2.20.11@o2ib --ost --index=${INDEX} --mkfsoptions="-E stride=262144,stripe_width=262144 -i 8192 ${JOURNAL}" ${DEVICE}
	fi
	return 2
}
if [[ "$3" != "No" ]] ; then 
    create_journal_fs
    JOURNAL=$?
fi

create_lustre_fs
LDISKFS=$?

if [[ "$JOURNAL" == "2" || "$LDISKFS" == "2" ]] 
then 
    echo "Returning value 2" >> $LOKI
	exit 2
else
    echo "Returning value 0" >> $LOKI
	exit 0
fi
