#!/bin/sh

# Collect basi debug information
# File size limitation: There will be 2 files, wireless-client-statistic1.txt and wireless-client-statistic2.txt

file_num=1
local max_filesize=$(/bin/config get wifi_debug_max_log_size)

[  "$max_filesize" = "" ] && max_filesize=5

max_filesize=$(($max_filesize*1024*1024))

while [ 1 ]
do
    echo "===========Run time check============" >> /tmp/wireless-client-statistic$file_num.txt
    date=`date`
    echo "------------------$date--------------" >> /tmp/wireless-client-statistic$file_num.txt
    echo "------------------$date--------------" >> /dev/console
    echo "-----------wlanconfig athX list and corresponding mac apstats-------" >> /tmp/wireless-client-statistic$file_num.txt

    AP_iface_list=`cat /tmp/wifi_topology|awk 'BEGIN {FS=":"} $2 == "AP" {print $4}'`
    for ap in $AP_iface_list;do
        echo  "wlanconfig $ap list:" >>/tmp/wireless-client-statistic$file_num.txt
        wlanconfig $ap list >>/tmp/wireless-client-statistic$file_num.txt
        client_mac_list=`wlanconfig $ap list|awk 'FNR>1 {print $1}'`
        for mac in $client_mac_list;do
            echo "apstats -s -m $mac:" >>/tmp/wireless-client-statistic$file_num.txt
            apstats -s -m $mac >>/tmp/wireless-client-statistic$file_num.txt
        done
    done

    echo "========================next loop==================================" >>/tmp/wireless-client-statistic$file_num.txt
    sleep 1
    filesize=`ls -l /tmp/wireless-client-statistic$file_num.txt | awk '{print $5}'`

    if [ $filesize -ge $max_filesize ]; then
        echo "wifi log filesize is over, change to another wireless-client-statistic file"
        if [ $file_num -eq 1 ]; then
            file_num=2;
        else
            file_num=1;
        fi
        # Once 1 file has reached the maximum, start write to another file
	[ -f /tmp/wireless-client-statistic$file_num.txt ] && rm -rf /tmp/wireless-client-statistic$file_num.txt
    fi
    sleep 30
done

