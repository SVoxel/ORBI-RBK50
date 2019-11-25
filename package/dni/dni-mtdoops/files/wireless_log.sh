#!/bin/sh

# Collect basi debug information
# File size limitation: There will be 2 files, wireless-log1.txt and wireless-log2.txt

file_num=1
local max_filesize=$(/bin/config get wifi_debug_max_log_size)

[  "$max_filesize" = "" ] && max_filesize=5

max_filesize=$(($max_filesize*1024*1024))
local wifi_debug_option=$(/bin/config get wifi_debug_option)
local enable_wifi_debug=$(/bin/config get enable_wifi_debug)

if [ "$enable_wifi_debug" = "1" ];then
	iwpriv ath0 dbgLVL $wifi_debug_option
	iwpriv ath1 dbgLVL $wifi_debug_option
	iwpriv ath01 dbgLVL $wifi_debug_option
	iwpriv ath2 dbgLVL $wifi_debug_option
fi

wl5g_NORMAL_AP=$(/bin/config get wl5g_NORMAL_AP)
wl2g_NORMAL_AP=$(/bin/config get wl2g_NORMAL_AP)
wl5g_BACKHAUL_AP=$(/bin/config get wl5g_BACKHAUL_AP)
wl2g_BACKHAUL_AP=$(/bin/config get wl2g_BACKHAUL_AP)
wl5g_BACKHAUL_STA=$(/bin/config get wl5g_BACKHAUL_STA)
wl2g_BACKHAUL_STA=$(/bin/config get wl2g_BACKHAUL_STA)

iwpriv $wl5g_NORMAL_AP dbgLVL 0x90CC0080
iwpriv $wl5g_NORMAL_AP dbgLVL_high 0x0
iwpriv $wl2g_NORMAL_AP dbgLVL 0x90CC0080
iwpriv $wl2g_NORMAL_AP dbgLVL_high 0x0
iwpriv $wl5g_BACKHAUL_AP dbgLVL 0x90CC0080
iwpriv $wl5g_BACKHAUL_AP dbgLVL_high 0x0
iwpriv $wl2g_BACKHAUL_AP dbgLVL 0x90CC0080
iwpriv $wl2g_BACKHAUL_AP dbgLVL_high 0x0
iwpriv $wl5g_BACKHAUL_STA dbgLVL 0x90CC0080
iwpriv $wl5g_BACKHAUL_STA dbgLVL_high 0x0
iwpriv $wl2g_BACKHAUL_STA dbgLVL 0x90CC0080
iwpriv $wl2g_BACKHAUL_STA dbgLVL_high 0x0

IPQ4019_board_data_v1_dir="/lib/firmware/IPQ4019/hw.1/board-01"
IPQ4019_board_data_v2_dir="/lib/firmware/IPQ4019/hw.1/board-02"
QCA9984_board_data_v1_dir="/lib/firmware/QCA9984/hw.1/board-01"
QCA9984_board_data_v2_dir="/lib/firmware/QCA9984/hw.1/board-02"

echo "======================hw_revision check======================" >> /tmp/wireless-log$file_num.txt
echo "/tmp/hw_revision : `cat /tmp/hw_revision`" >> /tmp/wireless-log$file_num.txt
echo "in artmtd `artmtd -r hw_revision`" >> /tmp/wireless-log$file_num.txt

echo "---------------------------- 4019 Board data --------------------------------" >> /tmp/wireless-log$file_num.txt
md5sum /lib/firmware/IPQ4019/hw.1/* >> /tmp/wireless-log$file_num.txt
[ -e $IPQ4019_board_data_v1_dir ] && md5sum $IPQ4019_board_data_v1_dir/* >> /tmp/wireless-log$file_num.txt
[ -e $IPQ4019_board_data_v2_dir ] && md5sum $IPQ4019_board_data_v2_dir/* >> /tmp/wireless-log$file_num.txt

echo "---------------------------- 9984 Board data --------------------------------" >> /tmp/wireless-log$file_num.txt
md5sum /lib/firmware/QCA9984/hw.1/* >> /tmp/wireless-log$file_num.txt
[ -e $QCA9984_board_data_v1_dir ] && md5sum $QCA9984_board_data_v1_dir/* >> /tmp/wireless-log$file_num.txt
[ -e $QCA9984_board_data_v2_dir ] && md5sum $QCA9984_board_data_v2_dir/* >> /tmp/wireless-log$file_num.txt

while [ 1 ]
do
echo "======================Run time check======================" >> /tmp/wireless-log$file_num.txt
date=`date`
echo "-----------------------$date----------------------" >> /tmp/wireless-log$file_num.txt
echo "-----------------------$date----------------------" >> /dev/console
echo "-------------------------------iwconfig---------------------------------" >> /tmp/wireless-log$file_num.txt
	iwconfig >>/tmp/wireless-log$file_num.txt
echo "-----------------------ebtables----------------------" >> /tmp/wireless-log$file_num.txt
        ebtables -L >> /tmp/wireless-log$file_num.txt
echo "--------------------------wlanconfig athX list--------------------------" >> /tmp/wireless-log$file_num.txt
	echo "wlanconfig ath0 list:" >>/tmp/wireless-log$file_num.txt
	wlanconfig ath0 list >>/tmp/wireless-log$file_num.txt
	echo "wlanconfig ath1 list:" >>/tmp/wireless-log$file_num.txt
	wlanconfig ath1 list >>/tmp/wireless-log$file_num.txt
	echo "wlanconfig ath2 list:" >>/tmp/wireless-log$file_num.txt
	wlanconfig ath2 list >>/tmp/wireless-log$file_num.txt
	echo "wlanconfig ath01 list:" >>/tmp/wireless-log$file_num.txt
	wlanconfig ath01 list >>/tmp/wireless-log$file_num.txt

#echo "------------------------------dump WDS table----------------------------------" >> /tmp/wireless-log$file_num.txt
echo "------------------------------dump WDS table----------------------------------" >> /dev/console
        wl5g_BACKHAUL_AP=$(/bin/config get wl5g_BACKHAUL_AP)
        wl2g_BACKHAUL_AP=$(/bin/config get wl2g_BACKHAUL_AP)
        wl5g_BACKHAUL_STA=$(/bin/config get wl5g_BACKHAUL_STA)
        wl2g_BACKHAUL_STA=$(/bin/config get wl2g_BACKHAUL_STA)
#echo "Dump 5G backhaul AP,2G backhaul AP,5G backhaul STA, 2G backhaul STA WDS table." >> /dev/console
	echo "Dump 5G backhaul AP WDS table:" >> /dev/console
        wlanconfig $wl5g_BACKHAUL_AP hmwds dump-wdstable >> /dev/console
        sleep 2

	echo "Dump 2G backhaul AP WDS table:" >> /dev/console
        wlanconfig $wl2g_BACKHAUL_AP hmwds dump-wdstable >> /dev/console
        sleep 2

	echo "Dump 5G backhaul STA WDS table:" >> /dev/console
        wlanconfig $wl5g_BACKHAUL_STA hmwds dump-wdstable >> /dev/console
        sleep 2

	echo "Dump 2G backhaul STA WDS table:" >> /dev/console
        wlanconfig $wl2g_BACKHAUL_STA hmwds dump-wdstable >> /dev/console
        sleep 2

echo "------------------------------hmwds read-table----------------------------------" >> /dev/console
    echo "Dump 5G backhaul AP read-table:" >>/dev/console
        wlanconfig $wl5g_BACKHAUL_AP hmwds read-table >> /dev/console

    echo "Dump 2G backhaul AP read-table:" >>/dev/console
        wlanconfig $wl2g_BACKHAUL_AP hmwds read-table >> /dev/console


echo "------------------------------athstats----------------------------------" >> /tmp/wireless-log$file_num.txt
	athstats >>/tmp/wireless-log$file_num.txt
echo "-------------current topology information via Wi-Fi SON-----------------" >> /tmp/wireless-log$file_num.txt
	(echo "td s2"; sleep 2) | hyt |tee >>/tmp/wireless-log$file_num.txt
echo "---------Satellite's current backhaul is (ath01)2G or (ath2)5G ?--------" >> /tmp/wireless-log$file_num.txt
	(echo "hy hd"; sleep 2) | hyt |tee >>/tmp/wireless-log$file_num.txt
	
echo "---------------------Wi-Fi SON daemons status---------------------------" >> /tmp/wireless-log$file_num.txt
	echo "Wi-Fi SON daemons status" >>/tmp/wireless-log$file_num.txt
	echo -n "hyd_enable =">>/tmp/wireless-log$file_num.txt;
	/bin/config get hyd_enable >>/tmp/wireless-log$file_num.txt
	echo -n "repacd_enable =">>/tmp/wireless-log$file_num.txt;
	/bin/config get repacd_enable >>/tmp/wireless-log$file_num.txt
	echo -n "wsplcd_enable=">>/tmp/wireless-log$file_num.txt;
	/bin/config get wsplcd_enable >>/tmp/wireless-log$file_num.txt
        [ -f /tmp/radardetect.log ] && {
            echo "------------------------------radardetect-------------------------------" >> /tmp/wireless-log$file_num.txt
            cat /tmp/radardetect.log >> /tmp/wireless-log$file_num.txt
        }
echo "---------------------hyctl show br0---------------------------" >> /tmp/wireless-log$file_num.txt
        hyctl show br0 >> /tmp/wireless-log$file_num.txt


echo "---------------------hy hd---------------------------" >> /tmp/wireless-log$file_num.txt
        (echo "hy hd"; sleep 2) | hyt |tee >> /tmp/wireless-log$file_num.txt

echo "---------------------hy ha---------------------------" >> /tmp/wireless-log$file_num.txt
        (echo "hy ha"; sleep 2) | hyt |tee >> /tmp/wireless-log$file_num.txt

echo "-----------------------$date----------------------" >> /tmp/wireless-log$file_num.txt
echo "-----------------------dbg here----------------------" >> /tmp/wireless-log$file_num.txt
echo "-------------(echo "dbg here"; sleep 5)| hyt-------------" >> /tmp/wireless-log$file_num.txt
        (echo "dbg here"; sleep 5)| hyt >> /tmp/wireless-log$file_num.txt

echo "-----------------------2G BACKHAUL_AP RX Rate---------------------" > /dev/console
iwpriv `config get wl2g_BACKHAUL_AP` txrx_fw_stats 3
sleep 1

echo "-----------------------5G BACKHAUL_AP RX Rate---------------------" > /dev/console
iwpriv `config get wl5g_BACKHAUL_AP` txrx_fw_stats 3
sleep 1

echo "-----------------------2G BACKHAUL_AP TX Rate---------------------" > /dev/console
iwpriv `config get wl2g_BACKHAUL_AP` txrx_fw_stats 6
sleep 1

echo "-----------------------5G BACKHAUL_AP TX Rate---------------------" > /dev/console
iwpriv `config get wl5g_BACKHAUL_AP` txrx_fw_stats 6
sleep 1

echo "-----------------------2G BACKHAUL_STA RX Rate---------------------" > /dev/console
iwpriv `config get wl2g_BACKHAUL_STA` txrx_fw_stats 3
sleep 1

echo "-----------------------5G BACKHAUL_STA RX Rate---------------------" > /dev/console
iwpriv `config get wl5g_BACKHAUL_STA` txrx_fw_stats 3
sleep 1

echo "-----------------------2G BACKHAUL_STA TX Rate---------------------" > /dev/console
iwpriv `config get wl2g_BACKHAUL_STA` txrx_fw_stats 6
sleep 1

echo "-----------------------5G BACKHAUL_STA TX Rate---------------------" > /dev/console
iwpriv `config get wl5g_BACKHAUL_STA` txrx_fw_stats 6
sleep 1

	echo "========================next loop==================================" >>/tmp/wireless-log$file_num.txt
	sleep 1
	filesize=`ls -l /tmp/wireless-log$file_num.txt | awk '{print $5}'`

	if [ $filesize -ge $max_filesize ]; then
	echo "wifi log filesize is over, change to another wireless-log file"
		if [ $file_num -eq 1 ]; then
			file_num=2;
		else
			file_num=1;
		fi
	# Once 1 file has reached the maximum, start write to another file
	[ -f /tmp/wireless-log$file_num.txt ] && rm -rf /tmp/wireless-log$file_num.txt
	
	fi
	sleep 30

done

