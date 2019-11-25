#!/bin/sh
LOG_FILE_SIZE=$((5*1024*1024))
JSON_LOG_LIMIT_SIZE=$((120*1024))
TMP_LOG_FILE="/tmp/ra_debug.log"
TMP_LOG_FILE1="/tmp/ra_debug_tmp.log1"
TMP_LOG_FILE_PRE="/tmp/ra_debug_tmp.log"
LOG_FILE_NUMBER=1
RA_DBG_CFG="/tmp/dbg-gen.cfg"
HIGH_FREQ_CMD="iwconfig;ifconfig;"
MED_FREQ_CMD="mpstat -P ALL;cat /proc/meminfo;"
LOW_FREQ_CMD="cat /proc/cpuinfo;"

check_log_size()
{
	check_single_log_size $1
	while true
	do
		[ ! -f $TMP_LOG_FILE_PRE$LOG_FILE_NUMBER ] && break
		check_single_log_size $TMP_LOG_FILE_PRE$LOG_FILE_NUMBER
	done
}

check_single_log_size()
{
	if [ "$(wc -c $1 |awk '{print $1}')" -gt "$JSON_LOG_LIMIT_SIZE" ]; then
		size=`wc -c $1 |awk '{print $1}'`
		line=`wc -l $1 |awk '{print $1}'`

		count=$line
		while true
		do
			if [ "$(head -n$count $1 |wc -c)" -gt "$JSON_LOG_LIMIT_SIZE" ];then
				count=$(($count-10))	
			else
				break
			fi
		done
	
		count=$(($count+1))	
		line=$(($line-$count))
		LOG_FILE_NUMBER=$(($LOG_FILE_NUMBER+1))
		tail -n$line $1 >> $TMP_LOG_FILE_PRE$LOG_FILE_NUMBER
		sed -i $count',$d' $1
	else 
		break
	fi
}

limit_file_size()
{
	while true
	do
		if [ "$(wc -c $1 |awk '{print $1}')" -gt "$LOG_FILE_SIZE" ]; then
			sed -i '1d' $1
		else
			break
		fi
	done
}

run_cmd()
{
	cmd=$1
	echo [$cmd]| awk '{print $0,strftime("[%Y-%m-%d %H:%M:%S]")}' | tr "\n" " " | sed 's/] /]/g' >> $TMP_LOG_FILE
	$cmd |sed ':a;N;$!ba;s/\n/*##*/g' |tr "/" " " | tr "\t" " " >> $TMP_LOG_FILE
	limit_file_size $TMP_LOG_FILE
}

collect_log_from_dbg(){
	freq=$1
	hline=`grep -nr "high_freq_cmd" $RA_DBG_CFG | awk -F ':' '{print $1}'`
	mline=`grep -nr "med_freq_cmd" $RA_DBG_CFG | awk -F ':' '{print $1}'`
	lline=`grep -nr "low_freq_cmd" $RA_DBG_CFG| awk -F ':' '{print $1}'`
	endline=`wc -l $RA_DBG_CFG |awk '{print $1}'`
	case "$freq" in
		"high_freq")
		firstline=$(($hline+1))
		endline=$(($mline-1))
		;;
		"med_freq")
		firstline=$(($mline+1))
		endline=$(($lline-1))
		;;
		"low_freq")
		firstline=$(($lline+1))
		;;
	esac
	while true
	do
		if [ $firstline -lt $endline ]; then
			cmd=`head -n$firstline $RA_DBG_CFG |tail -1|awk -F ';' '{print $1}'`
			if [ "x$cmd" != "x" ] ; then
				run_cmd "$cmd"
			else
				break
			fi
			firstline=$(($firstline+1))
		else 
			break;
		fi 
	done
}

collect_log_by_default()
{
	case $1 in
		"high_freq")
			cmdpool=$HIGH_FREQ_CMD
		;;
		"med_freq")
			cmdpool=$MED_FREQ_CMD
		;;
		"low_freq")
			cmdpool=$LOW_FREQ_CMD
		;;
	esac
	i=1
	while true
	do
		cmd=`echo $cmdpool |awk -F ';' '{print $'$i'}'`
		if [ "x$cmd" != "x" ] ; then
			run_cmd "$cmd"
		else
			break;
		fi
		i=$(($i+1))
	done
}

collect_log()
{
	dos2unix $RA_DBG_CFG
	if [ -f $RA_DBG_CFG ];then
		collect_log_from_dbg $1
	else
		collect_log_by_default $1
	fi
}

#$1 high_freq med_freq low_freq#
	
case "$1" in
	"collect")
	collect_log $2
	;;
	"check_size")
	check_log_size $TMP_LOG_FILE1
	;;
esac
