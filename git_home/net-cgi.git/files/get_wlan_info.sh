#!/bin/sh
WLAN_INFO_FILE="/tmp/wlan_info_file"

INTERFACE=$@

rm -rf $WLAN_INFO_FILE
for interface in ${INTERFACE}; do
	apmac=`iwconfig $interface |grep 'Access Point'|awk '{printf $6}'`
	hwaddr=`ifconfig $interface |grep 'HWaddr' |awk '{printf $5}'`
	hop=`iwpriv $interface get_whc_dist |awk -F ':' '{printf $2}'`
	rx=`iwpriv $interface get_rxrate |awk -F ':' '{printf $2}'`
	tx=`iwpriv $interface get_txrate |awk -F ':' '{printf $2}'`
	cat << EOF >> $WLAN_INFO_FILE
$interface $hwaddr $apmac $hop $rx $tx
EOF
done
