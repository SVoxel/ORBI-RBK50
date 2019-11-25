#!/bin/sh

# save the thermal log in memory. Reboot will lost thermal log data

# File size limitation: There will be 2 files, thermal-log1.txt and thermal-log2.txt
file_num=1

while [ 1 ]
do
	thermaltool -i wifi0 -get >> /tmp/thermal-log$file_num.txt
	thermaltool -i wifi1 -get >> /tmp/thermal-log$file_num.txt
	thermaltool -i wifi2 -get >> /tmp/thermal-log$file_num.txt
	
	filesize=`ls -l /tmp/thermal-log$file_num.txt | awk '{print $5}'`
	# The maximum of each file is 10MB
	if [ $filesize -ge 10485760 ]; then
		echo "filesize if over, change to another thermal-log file"
		if [ $file_num -eq 1 ]; then
			file_num=2;
		else
			file_num=1;
		fi
		# Once 1 file has reached the maximum(10MB), start write to another file
		[ -f /tmp/thermal-log$file_num.txt ] && rm -rf /tmp/thermal-log$file_num.txt
	fi
	sleep 30
	echo "======================next time=====================" >> /tmp/thermal-log$file_num.txt
done

