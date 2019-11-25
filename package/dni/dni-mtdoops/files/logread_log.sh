#!/bin/sh

# save the console log in memory. Reboot will lost console log data

# File size limitation: There will be 2 files, Console-log1.txt and console-log2.txt
file_num=1

echo 1 > /sys/module/qca_ol/parameters/host_dbgshow

logread -f >> /tmp/logread-log$file_num.txt &

while [ 1 ]
do

	usleep 200000

	filesize=`ls -l /tmp/Console-log$file_num.txt | awk '{print $5}'`
	# The maximum of each file is 5MB
	if [ $filesize -ge 5242880 ]; then
		echo "filesize if over, change to another Console-log file"
                killall logread

		if [ $file_num -eq 1 ]; then
			file_num=2;
		else
			file_num=1;
		fi
		# Once 1 file has reached the maximum(5MB), start write to another file
		[ -f /tmp/logread-log$file_num.txt ] && rm -rf /tmp/logread-log$file_num.txt

                logread -f >> /tmp/logread-log$file_num.txt &
	fi
done

