#!/bin/sh

get_base_mac_ip(){
        base_result=`(echo "td s2";sleep 2)| hyt|grep "Network relaying device"`
        mac=`echo $base_result|awk -F " " '{print $6}'|awk -F "," '{print $1}'`
        ip=`echo $base_result|awk -F " " '{print $9}'`
        [ "x$1" = "xmac" ] && echo $mac || echo $ip
}

case "$1" in
        mac)
        	get_base_mac_ip "$1"
        	;;
        ip)
        	get_base_mac_ip "$1"
        	;;
        *)
        	;;
esac