#!/bin/sh

CONFIG=/bin/config

action=$1

if [ "$action" = "restart" ]; then
	#For Advanced WLAN debug
	local enable_wifi_debug=$($CONFIG get enable_wifi_debug)
	local wifi_debug_option=$($CONFIG get wifi_debug_option)
	local enable_wifi_debug=$($CONFIG get enable_wifi_debug)
	
	#Device Steering Function debug
	local enable_band_steering=$($CONFIG get enable_band_steering)
	local steer_80211kv_enable=$($CONFIG get steer_80211kv_enable)
	local multi_ap_disablesteering=$($CONFIG get multi_ap_disablesteering)
	if [ "$enable_wifi_debug" = "1" ]; then
		 $CONFIG set hostapd_debug_level=2
	else
		 $CONFIG unset hostapd_debug_level
	fi

	if [ "$enable_band_steering" = "0" ]; then
		$CONFIG set steer_80211kv_enable=0
		$CONFIG set steer_legacy_enable=0
	else
		$CONFIG set steer_80211kv_enable=1
		$CONFIG set steer_legacy_enable=1
	fi
	
	$CONFIG commit
	wifison.sh updateconf all
	wifison.sh restart all
	if [ "$enable_band_steering" = "1" -o "$multi_ap_disablesteering" = "0" ]; then
		$CONFIG set wl_rrm=1
		$CONFIG set wla_rrm=1
	elif [ "$enable_band_steering" = "0" -a "$multi_ap_disablesteering" = "1" ]; then
		$CONFIG set wl_rrm=0
		$CONFIG set wla_rrm=0
	fi
	
	$CONFIG commit
	wlan updateconf
	wlan down; wlan up

fi	
