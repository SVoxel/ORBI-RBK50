#!/bin/sh
CONFIG=/bin/config
PID_file=/var/run/iwlist_scan.pid
[ -f $PID_file ] && return 1
echo "$$" > $PID_file
ath_back=$($CONFIG get wl2g_BACKHAUL_AP)
freq=`iwlist $ath_back channel | grep "Current" | cut -d ":" -f 2`
channel=`echo $freq | cut -d " " -f 4 | tr -cd "[0-9]"`
wifitool $ath_back setchanlist $channel
iwpriv $ath_back acsreport 1
sleep 2
APs_num=`iwlist $ath_back scanning last | grep "$freq" | wc -l`
$CONFIG set APs_num=$APs_num
rm -f $PID_file
