#! /bin/sh
#
# Copyright (c) 2013 The Linux Foundation. All rights reserved.
#

. /lib/functions.sh
include /lib/upgrade

ubus call system upgrade

kill_remaining TERM
sleep 3
kill_remaining KILL

ROOTFS_PART=$(grep rootfs_data /proc/mtd |cut -f4 -d' ')

if [ -z $ROOTFS_PART ]; then
	ROOTFS_PART="$(find_mmc_part "rootfs_data")"
	ERASE_PART="mkfs.ext4 "$ROOTFS_PART
else
	ERASE_PART="mtd erase "$ROOTFS_PART
fi

run_ramfs ". /lib/functions.sh; include /lib/upgrade; sync; $ERASE_PART; reboot"
