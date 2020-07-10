#!/bin/sh

#wireless RA for installation
CONFIG="/bin/config"

hijack=`$CONFIG get dns_hijack`
[ "x$hijack" = "x0" ] && return 0

[ ! -d "/tmp/base" ] && /bin/mkdir -p /tmp/base/clients_event; /bin/mkdir -p /tmp/base/vaps_event
[ ! -d "/tmp/satellite" ] && /bin/mkdir -p /tmp/satellite/clients_event;/bin/mkdir -p /tmp/base/vaps_event

FILE_PATH_BASE_CLIENT="/tmp/base/clients_event"
FILE_PATH_BASE_VAP="/tmp/base/vaps_event"
FILE_PATH_SATE_CLIENT="/tmp/satellite/clients_event"
FILE_PATH_SATE_VAP="/tmp/satellite/vaps_event"

if [ "`/bin/cat /tmp/orbi_type`" = "Base" ];then
	FILE_PATH_CLIENT=$FILE_PATH_BASE_CLIENT
	FILE_PATH_VAP=$FILE_PATH_BASE_VAP
else
	FILE_PATH_CLIENT=$FILE_PATH_SATE_CLIENT
	FILE_PATH_VAP=$FILE_PATH_SATE_VAP
fi

ifname_2g=`$CONFIG get wl2g_NORMAL_AP`
ifname_5g=`$CONFIG get wl5g_NORMAL_AP`

pre_vap_state=""
cur_vap_state=""

pre_clients_2g=""
cur_clients_2g=""
pre_clients_5g=""
cur_clients_5g=""

check_client_event(){
	mac_2g=`iwconfig $ifname_2g|grep "Access Point"|awk -F ' ' '{print $6}'`
	mac_5g=`iwconfig $ifname_5g|grep "Access Point"|awk -F ' ' '{print $6}'`
	channel_2g=`iwlist $ifname_2g chan|grep "Current Frequency"|awk '{printf "%d", substr($5,1,length($5))}'`
	channel_5g=`iwlist $ifname_5g chan|grep "Current Frequency"|awk '{printf "%d", substr($5,1,length($5))}'`
	cur_clients_2g=`wlanconfig $ifname_2g list sta|grep ^..:..:..:..:..:..|awk -F ' ' '{print $1}'`
	cur_clients_5g=`wlanconfig $ifname_5g list sta|grep ^..:..:..:..:..:..|awk -F ' ' '{print $1}'`
	#find connect clients
	echo "$cur_clients_2g"|while read line;do
		[ -z "$cur_clients_2g" ] && break
		clients_state=`echo "$pre_clients_2g"|grep $line`
		if [ -z "$clients_state" ];then
			echo "timestamp:`date`" > "$FILE_PATH_CLIENT/$line"
			echo "EVENT:CONNNECT SUCCESS" >> "$FILE_PATH_CLIENT/$line"
			echo "clientMAC:$line" >> "$FILE_PATH_CLIENT/$line"
			echo "apMAC:$mac_2g" >> "$FILE_PATH_CLIENT/$line"
			echo "band:2.4G" >> "$FILE_PATH_CLIENT/$line"
			echo "channel:$channel_2g" >> "$FILE_PATH_CLIENT/$line"
			echo "Capability:" >> "$FILE_PATH_CLIENT/$line"
			echo "phymode:" >> "$FILE_PATH_CLIENT/$line"
			echo "KCS:" >> "$FILE_PATH_CLIENT/$line"
			echo "nss" >> "$FILE_PATH_CLIENT/$line"
			echo "************client:$line connected 2.4G****************" >/dev/console
			/usr/sbin/ra_installevent  wificlientconnect "$FILE_PATH_CLIENT/$line"
		fi
	done
	#find disconnect clients
	echo "$pre_clients_2g"|while read line;do
		[ -z "$pre_clients_2g" ] && break
		clients_state=`echo "$cur_clients_2g"|grep $line`
		if [ -z "$clients_state" ];then
			echo "timestamp:`date`" > "$FILE_PATH_CLIENT/$line"
			echo "EVENT:DISCONNNECTED" >> "$FILE_PATH_CLIENT/$line"
			echo "clientMAC:$line" >> "$FILE_PATH_CLIENT/$line"
			echo "apMAC:$mac_2g" >> "$FILE_PATH_CLIENT/$line"
			echo "band:2.4G" >> "$FILE_PATH_CLIENT/$line"
			echo "channel:$channel_2g" >> "$FILE_PATH_CLIENT/$line"
			echo "Capability:" >> "$FILE_PATH_CLIENT/$line"
			echo "phymode:" >> "$FILE_PATH_CLIENT/$line"
			echo "KCS:" >> "$FILE_PATH_CLIENT/$line"
			echo "nss" >> "$FILE_PATH_CLIENT/$line"
			echo "************client:$line disconnected 2.4G****************" >/dev/console
			/usr/sbin/ra_installevent  wificlientdisconnect "$FILE_PATH_CLIENT/$line"
		fi
	done
	#find 5G connect clients
	pre_clients_2g="$cur_clients_2g"
	echo "$cur_clients_5g"|while read line;do
		[ -z "$cur_clients_5g" ] && break
		clients_state=`echo "$pre_clients_5g"|grep $line`
		if [ -z "$clients_state" ];then
			echo "timestamp:`date`" > "$FILE_PATH_CLIENT/$line"
			echo "EVENT:CONNNECT SUCCESS" >> "$FILE_PATH_CLIENT/$line"
			echo "clientMAC:$line" >> "$FILE_PATH_CLIENT/$line"
			echo "apMAC:$mac_5g" >> "$FILE_PATH_CLIENT/$line"
			echo "band:5G" >> "$FILE_PATH_CLIENT/$line"
			echo "channel:$channel_5g" >> "$FILE_PATH_CLIENT/$line"
			echo "Capability:" >> "$FILE_PATH_CLIENT/$line"
			echo "phymode:" >> "$FILE_PATH_CLIENT/$line"
			echo "KCS:" >> "$FILE_PATH_CLIENT/$line"
			echo "nss" >> "$FILE_PATH_CLIENT/$line"
			echo "************client:$line connected 5G****************" >/dev/console
			/usr/sbin/ra_installevent  wificlientconnect "$FILE_PATH_CLIENT/$line"
		fi
	done
	#find disconnect clients
	echo "$pre_clients_5g"|while read line;do
		[ -z "$pre_clients_5g" ] && break
		clients_state=`echo "$cur_clients_5g"|grep $line`
		if [ -z "$clients_state" ];then
			echo "timestamp:`date`" > "$FILE_PATH_CLIENT/$line"
			echo "EVENT:DISCONNNECTED" >> "$FILE_PATH_CLIENT/$line"
			echo "clientMAC:$line" >> "$FILE_PATH_CLIENT/$line"
			echo "apMAC:$mac_5g" >> "$FILE_PATH_CLIENT/$line"
			echo "band:5G" >> "$FILE_PATH_CLIENT/$line"
			echo "channel:$channel_5g" >> "$FILE_PATH_CLIENT/$line"
			echo "Capability:" >> "$FILE_PATH_CLIENT/$line"
			echo "phymode:" >> "$FILE_PATH_CLIENT/$line"
			echo "KCS:" >> "$FILE_PATH_CLIENT/$line"
			echo "nss" >> "$FILE_PATH_CLIENT/$line"
			echo "************client:$line disconnected 5G****************" >/dev/console
			/usr/sbin/ra_installevent  wificlientdisconnect "$FILE_PATH_CLIENT/$line"
		fi
	done
	pre_clients_5g="$cur_clients_5g"
}
#when vap off, client is disconnect.
check_client_event_wifi_off(){
	cur_clients_2g=""
	cur_clients_5g=""
	#find disconnect clients
	echo "$pre_clients_2g"|while read line;do
		[ -z "$pre_clients_2g" ] && break
		clients_state=`echo "$cur_clients_2g"|grep $line`
		if [ -z "$clients_state" ];then
			echo "timestamp:`date`" > "$FILE_PATH_CLIENT/$line"
			echo "EVENT:DISCONNNECTED" >> "$FILE_PATH_CLIENT/$line"
			echo "clientMAC:$line" >> "$FILE_PATH_CLIENT/$line"
			echo "apMAC:$mac_2g" >> "$FILE_PATH_CLIENT/$line"
			echo "band:2.4G" >> "$FILE_PATH_CLIENT/$line"
			echo "channel:$channel_2g" >> "$FILE_PATH_CLIENT/$line"
			echo "Capability:" >> "$FILE_PATH_CLIENT/$line"
			echo "phymode:" >> "$FILE_PATH_CLIENT/$line"
			echo "KCS:" >> "$FILE_PATH_CLIENT/$line"
			echo "nss" >> "$FILE_PATH_CLIENT/$line"
			echo "************client:$line disconnected 2.4G****************" >/dev/console
			/usr/sbin/ra_installevent  wificlientdisconnect "$FILE_PATH_CLIENT/$line"
		fi
	done
	#find disconnect clients
	echo "$pre_clients_5g"|while read line;do
		[ -z "$pre_clients_5g" ] && break
		clients_state=`echo "$cur_clients_5g"|grep $line`
		if [ -z "$clients_state" ];then
			echo "timestamp:`date`" > "$FILE_PATH_CLIENT/$line"
			echo "EVENT:DISCONNNECTED" >> "$FILE_PATH_CLIENT/$line"
			echo "clientMAC:$line" >> "$FILE_PATH_CLIENT/$line"
			echo "apMAC:$mac_5g" >> "$FILE_PATH_CLIENT/$line"
			echo "band:5G" >> "$FILE_PATH_CLIENT/$line"
			echo "channel:$channel_5g" >> "$FILE_PATH_CLIENT/$line"
			echo "Capability:" >> "$FILE_PATH_CLIENT/$line"
			echo "phymode:" >> "$FILE_PATH_CLIENT/$line"
			echo "KCS:" >> "$FILE_PATH_CLIENT/$line"
			echo "nss" >> "$FILE_PATH_CLIENT/$line"
			echo "************client:$line disconnected 5G****************" >/dev/console
			/usr/sbin/ra_installevent  wificlientdisconnect "$FILE_PATH_CLIENT/$line"
		fi
	done
	pre_clients_5g="$cur_clients_5g"
}

check_vap_event(){
	info_2g=`iwconfig $ifname_2g`
	info_5g=`iwconfig $ifname_5g`
	status_2g=`echo "$info_2g"|grep "Not-Associated"`
	status_5g=`echo "$info_5g"|grep "Not-Associated"`
	if [ -z "$status_2g" -a -z "$status_5g" ] && [ -n "$info_5g" -a -n "$info_2g" ];then
		cur_vap_state="on"
	else
		cur_vap_state="off"
	fi
	if [ "$pre_vap_state" != "$cur_vap_state" ];then
		if [ "$cur_vap_state" = "on" ];then
			echo "************vap on****************" >/dev/console
			/usr/sbin/ra_installevent wifion ""
		else
			echo "************vap off****************" >/dev/console
			/usr/sbin/ra_installevent wifioff ""
		fi
		pre_vap_state="$cur_vap_state"
	fi
}

while [ "x$hijack" = "x1" ];do

	check_vap_event
	if [ "x$cur_vap_state" = "xon" ];then
		check_client_event
	else
		check_client_event_wifi_off
	fi
	sleep 2
	hijack=`$CONFIG get dns_hijack`
done
echo "Exit hijack mode -> Exit wireless RA" >/dev/console
