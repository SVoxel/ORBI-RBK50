#!/bin/sh

# As requirement for NTGR Weber, if have usb storage, we will store LAN/WAN packet into usb storage, or store in sdram

dist_path=""
mnt_path="/mnt/"
store_locate=`cat /tmp/debug_store_locate`
wanlan_capture=$(/bin/config get debug_wanlan_capture)
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

# check whether usb storage connect to DUT
check_usb_storage_folder

# Simple LAN/WAN packet capture. THe file saved in DDR memory, THe file maximum to 10MB
if [ "X$wanlan_capture" = "X1" ]; then 

	if [ "X$store_locate" = "X1" -a "X$dist_path" != "X" ]; then
		echo "Save capture lan/wan packet in usb storage"
		mkdir $dist_path/Capture
		if [ "$(cat /tmp/orbi_type)" = "Satellite" ]; then
			tcpdump -i eth1 -s 0 -W 1 -w $dist_path/Capture/lan.pcap -C 6000 &
		else
			tcpdump -i br0 -s 0 -W 1 -w $dist_path/Capture/lan.pcap -C 6000 &
            if [ "`/bin/config get enable_arlo_function`" = "1" ];then
                tcpdump -i brarlo -s 0 -W 1 -w $dist_path/Capture/arlo.pcap -C 6000 &
            fi
		fi
		tcpdump -i brwan -s 0 -W 1 -w $dist_path/Capture/wan.pcap -C 6000 &
	else
		echo "Save capture lan/wan packet in SDRAM tmp dir"
		if [ "$(cat /tmp/orbi_type)" = "Satellite" ]; then
			tcpdump -i eth1 -s 0 -W 1 -w /tmp/lan.pcap -C 5 &
		else
			tcpdump -i br0 -s 0 -W 1 -w /tmp/lan.pcap -C 5 &
            if [ "`/bin/config get enable_arlo_function`" = "1" ];then
                tcpdump -i brarlo -s 0 -W 1 -w /tmp/arlo.pcap -C 5 &
            fi
		fi
		tcpdump -i brwan  -s 0 -W 1 -w /tmp/wan.pcap -C 5 &
	fi
fi

