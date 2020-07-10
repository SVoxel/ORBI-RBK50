#!/bin/sh

#$1 is satellite's mac

[ -z "$1" ] && exit

num=`ps -w | grep soapclient | grep "$1" | grep -v grep | awk -F ' ' '{print $1}'`

for info in $num
do
	if [ -n $info ]; then
		kill -9 $info
	fi
done



