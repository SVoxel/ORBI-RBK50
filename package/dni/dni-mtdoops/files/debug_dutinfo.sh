#!/bin/sh

CPU_INFO=/tmp/debug_cpu
MEM_INFO=/tmp/debug_mem
FLASH_INFO=/tmp/debug_flash
SESSION_INFO=/tmp/debug_session

cpu_usage()
{
	CPU_LOG1=$(cat /proc/stat | grep "cpu " | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
	SYS_IDLE1=$(echo $CPU_LOG1 | awk '{print $4}')
	SYS_TOTAL1=$(echo $CPU_LOG1 | awk '{print $1+$2+$3+$4+$5+$6+$7}')

	sleep 1

	CPU_LOG2=$(cat /proc/stat | grep "cpu " | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
	SYS_IDLE2=$(echo $CPU_LOG2 | awk '{print $4}')
	SYS_TOTAL2=$(echo $CPU_LOG2 | awk '{print $1+$2+$3+$4+$5+$6+$7}')

	SYS_IDLE=$(echo "${SYS_IDLE2} ${SYS_IDLE1}" | awk '{print $1-$2}')
	SYS_TOTAL=$(echo "${SYS_TOTAL2} ${SYS_TOTAL1}" | awk '{print $1-$2}')

	USAGE=`echo "${SYS_IDLE} ${SYS_TOTAL}" | awk '{print 100-$1/$2*100}'`

	echo "${USAGE}%" > $CPU_INFO
}

mem_usage()
{
	# SPEC 14, Avaliable memory/Total memory: Free+Buffer+Cache/Total

	# This item used = Used - Buffer - Free
	used_kb=`free | grep "buffers" |grep -v "total"| awk '{print $3}'`
	used_mb=`expr ${used_kb} / 1024`
	# This item avaliable = Free + Buffer + Cache
	unused_kb=`free | grep "buffers" | grep -v "total"|awk '{print $4}'`
	unused_mb=`expr ${unused_kb} / 1024`

	total_kb=`free | grep "Mem" | awk '{print $2}'`
	total_mb=`expr ${total_kb} / 1024`

	echo "$(($total_mb - $unused_mb))MB/${total_mb}MB" > $MEM_INFO
}

session_usage()
{
	used_session=`cat /proc/sys/net/ipv4/netfilter/ip_conntrack_count`
	total_session=`cat /proc/sys/net/ipv4/netfilter/ip_conntrack_max`
	
	echo "${used_session}/${total_session}" > $SESSION_INFO
}

flash_usage()
{
	#flash usage: (Flash size - reserved partition) / Flash size
	flash_type=`cat /flash_type`
	module_name=`cat /module_name`
	if [ "$flash_type" = "NAND_FLASH" ]; then
		#for NAND flash, we have mount all
		while read dev size erasesize name
		do
			name=$(echo $name | sed 's/\"//g')
			[ "$name" = "name" -o "${name:0:6}" = "kernel" -o "${name:0:6}" = "rootfs" -o "${name:0:4}" = "vol_" -o "${name:0:3}" = "spi" ] && continue
			size=$(printf %d 0x$size)
			[ "$name" = "reserved" ] && reserved_size=$size
			size_sum=$(($size_sum + $size))
		done < /proc/mtd
		max_size=$(($size_sum / 1048576))
		reserved_size=$(($reserved_size / 1048576))
		echo "$(($max_size - $reserved_size))MB/${max_size}MB" > $FLASH_INFO
	else
		#for EMMC flash, whole Flash chip size is 4GB, but we have not mount all flash.
		while read major minor size name
		do
			if [ "$name" = "mmcblk0rpmb" ]; then
				reserved_size=$size_last
			fi
			size_last=$size
		done < /proc/partitions
		
		reserved_size=$(($reserved_size / 1024))
		max_size=4096
		echo "$(($max_size - $reserved_size))MB/${max_size}MB" > $FLASH_INFO
	fi
}

dist_path=""
mnt_path="/mnt/"

check_usb_storage_folder()
{
	part_list="a b c d e f g"
	for i in $part_list; do
		[ "X$(df | grep /dev/sd"$i")" = "X" ] && continue
		#echo "sd$i"
		j=1
		while [ $j -le 20 ]; do
			tmp=`df | grep /dev/sd"$i""$j"`
			mnt_tmp=`ls $mnt_path | grep sd"$i""$j"`
			[ "X$tmp" = "X" -o "X$mnt_tmp" = "X" ] && j=$((j+1)) && continue

			dist_path="$mnt_path"sd"$i""$j"
			break;

			j=$((j+1))
		done
		[ "X$dist_path" != "X" ]  && break
	done
}

cpu_usage
mem_usage
session_usage
flash_usage
check_usb_storage_folder
if [ "X$dist_path" != "X" ]; then
	echo 1 > /tmp/debug-usb
else
	echo 0 > /tmp/debug-usb
fi
