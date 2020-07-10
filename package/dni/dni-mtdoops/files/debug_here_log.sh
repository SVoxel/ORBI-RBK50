#!/bin/sh

# Collect basi debug information
filepath=/tmp
filename=/tmp/debug_here_log_1.txt


while [ 1 ]
do

echo "======================Debug level update======================" >> $filename    
echo "-------------(echo "dbg level estimator dump")| hyt-------------" >> $filename
	(echo "dbg level estimator dump"; sleep 2)| hyt >> $filename 
echo "-------------(echo "dbg level steermsg dump")| hyt-------------" >> $filename
	(echo "dbg level steermsg dump"; sleep 2)| hyt >> $filename 
echo "-------------(echo "dbg level steerexec dump")| hyt-------------" >> $filename
	(echo "dbg level steerexec dump"; sleep 2)| hyt >> $filename 
    
echo "======================Run time check======================" >> $filename
date=`date`
echo "-----------------------$date----------------------" >> $filename
echo "-----------------------dbg here----------------------" >> /tmp/basic_debug_log.txt
echo "-------------(echo "dbg here"; sleep 300)| hyt-------------" >> $filename
	(echo "dbg here"; sleep 300)| hyt >> $filename 

	
echo "========================next loop==================================" >> $filename


	backup_number=2
	current_file_size=`ls -l $filename | awk '{print $5}'`
	current_total_size=`ls -l $filepath | awk '/debug_here/ {SUM += $5} END {print SUM}'`
	single_size_limit=5000000
	total_size_limit=`awk "BEGIN {print $single_size_limit*$backup_number}"`


	if [ $current_file_size -ge $single_size_limit ]; then
		if [ "$filename" = "/tmp/debug_here_log_1.txt" ];then
		    echo "log1 filesize is over, will write to debug_here_log_2.txt"
		    filename=/tmp/debug_here_log_2.txt
		else
		    echo "log2 filesize is over, will write to debug_here_log_1.txt"
		    filename=/tmp/debug_here_log_1.txt
		fi
	    [ -f $filename  ] && [ $current_total_size -ge $total_size_limit ] && {
		    echo "filesize is over, need delete $filename"
			rm $filename
	    }
	fi
	
done

