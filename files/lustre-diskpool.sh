#!/bin/bash
# 
# $1: diskpool 
# $2: ost

POOLDIR="/proc/fs/lustre/lov/lustre-MDT0000-mdtlov/pools"

# Wants diskpool-name as parameter, returns boolean
diskpool_exists() {
	[[ -r ${POOLDIR}/$1 ]]
}

# Wants diskpool-name as parameter, returns boolean
create_diskpool() {
	echo Trying to create missing diskpool lustre.$1
	lctl pool_new lustre.$1
}

# Wants ost-name as parameter, returns boolean
# TODO should find better way to check OST existence
ost_exists() {
	[[ -r /proc/fs/lustre/osp/lustre-${1}-osc-MDT0000/active ]]
}

# Wants diskpool-name and ost-name as parameters, returns boolean
ost_in_pool() {
	grep -q "$2" ${POOLDIR}/$1
}

# Wants diskpool-name and ost-name as parameters, returns boolean
add_ost_to_pool() {
	echo Trying to add OST $2 to diskpool $1
	lctl pool_add lustre.$1 lustre-$2_UUID
}

if ! diskpool_exists $1 
then
	echo $1 does not exist.
	create_diskpool $1
	if ost_exists $2
	then
		add_ost_to_pool $1 $2
	else
		false
	fi
else
	echo Diskpool $1 exists
	if ost_exists $2
	then
		if ! ost_in_pool $1 $2
		then
			add_ost_to_pool $1 $2
		fi
	else
		# OST doesn't exists, so we can't add it to pool
		echo OST $2 does not exists
		false
	fi
fi

