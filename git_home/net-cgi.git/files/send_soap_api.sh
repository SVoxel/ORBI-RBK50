#! /bin/sh

CONFIG=/bin/config
KILLALL=/usr/bin/killall
NUM=0
API=$1

[ "x$API" = "x" ] && exit

PS0=`ps |grep $0 |grep -v grep | wc -l`

if [ $PS0 -gt 2 ];then
	exit
fi

sleep 1

# for newsoap model machine
if [ "$($CONFIG get newsoap_model)" = "1" ]; then
	if [ "$($CONFIG get soap_setting)" != $API ]; then
		$CONFIG set soap_setting=$API
	fi
	$KILLALL -SIGUSR1 soap_agent
	exit 0
fi

if [ "$($CONFIG get soap_setting)" = $API ]; then
	$KILLALL -SIGUSR1 soap_agent
else
	while [ $NUM -lt 60 ]
		do
			PS=`ps | grep soapclient |grep -v grep`
			if [ "x$PS" = "x" ]; then
				$CONFIG set soap_setting=$API
				$KILLALL -SIGUSR1 soap_agent
				break
			else
				sleep 2
				NUM=$(($NUM + 1))
			fi
		done
fi

