#!/bin/sh

num=0
while read line
do
	if [ "x$(echo $line |awk '{print $2}')" = "x1" ];then
		mac=$(echo $line |awk '{print $1}')
		grep -q $mac /tmp/hyt_result && num=$(( $num + 1 ))
	fi
done < /tmp/soapclient/allconfig_result

exit $num
