#!/bin/sh

status=`ps | grep soap_agent | grep -v grep`
echo "$status"
if [ -z "$status" ];then
	killall soap_agent
	time=`date '+%Y-%m-%dT%H:%M:%SZ'`
	echo "Restart soap_agent:$time" >> /tmp/soapclient/terminal
	/usr/sbin/soap_agent &
	
fi
