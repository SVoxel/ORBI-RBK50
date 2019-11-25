#!/bin/sh

# Collect basi debug information
# File size limitation: There will be 2 files, arlo-log1.txt and arlo-log2.txt

file_num=1
local max_filesize=$(/bin/config get wifi_debug_max_log_size)

[  "$max_filesize" = "" ] && max_filesize=5

max_filesize=$(($max_filesize*1024*1024))
arlo_vap=$(/bin/config get wl2g_ARLO_AP)

while [ 1 ]
do
date=`date`
echo "-------------------------$date---------------------------" >> /tmp/arlo-log$file_num.txt
echo "-----------------wlanconfig arlo vap list--------------------------" >> /tmp/arlo-log$file_num.txt
	echo "wlanconfig arlvap list:" >>/tmp/arlo-log$file_num.txt
	wlanconfig $arlo_vap list >>/tmp/arlo-log$file_num.txt

echo "------------------------------arp table----------------------------" >> /tmp/arlo-log$file_num.txt
	cat /proc/net/arp >>/tmp/arlo-log$file_num.txt
echo "--------------------------brctl showmacs brarlo----------------------------" >> /tmp/arlo-log$file_num.txt
	brctl showmacs brarlo >>/tmp/arlo-log$file_num.txt

if [ "`cat /tmp/orbi_type`" = "Base" ];then
echo "---------------------d2 arlocfg------------------------------------" >> /tmp/arlo-log$file_num.txt
        d2 arlocfg >> /tmp/arlo-log$file_num.txt
echo "---------------------d2 arlostatus---------------------------------" >> /tmp/arlo-log$file_num.txt
        d2 arlostatus >> /tmp/arlo-log$file_num.txt
echo "---------------------d2 arlocameras[0-7]---------------------------" >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[0] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[1] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[2] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[3] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[4] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[5] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[6] >> /tmp/arlo-log$file_num.txt
        d2 arlocameras[7] >> /tmp/arlo-log$file_num.txt
echo "---------------------d2 xagentcfg---------------------------------" >> /tmp/arlo-log$file_num.txt
        d2 xagentcfg >> /tmp/arlo-log$file_num.txt
fi

	filesize=`ls -l /tmp/arlo-log$file_num.txt | awk '{print $5}'`

	if [ $filesize -ge $max_filesize ]; then
	echo "arlo log filesize is over, change to another arlo-log file"
		if [ $file_num -eq 1 ]; then
			file_num=2;
		else
			file_num=1;
		fi
	# Once 1 file has reached the maximum, start write to another file
	[ -f /tmp/arlo-log$file_num.txt ] && rm -rf /tmp/arlo-log$file_num.txt
	
	fi
	sleep 30

done

