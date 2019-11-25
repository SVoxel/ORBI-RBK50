#!/bin/sh

# get the hop count,1. ethernet backhual:iwpriv ath0 get_whc_dist
#                   2. wilress backhual:iwpriv connected_interface get_whc_dist

ifname_backhaul_sta_2g=
ifname_backhaul_sta_5g=
ifname_fronthaul_ap_2g=
ifname_fronthaul_ap_5g=
not_connnected_2g=
not_connnected_5g=
hopcount=

satellite_hop_count=/tmp/satellite_hop_count
ifname_backhaul_sta_2g=`/bin/config get wl2g_BACKHAUL_STA`
ifname_backhaul_sta_5g=`/bin/config get wl5g_BACKHAUL_STA`
ifname_fronthaul_ap_2g=`/bin/config get wl2g_NORMAL_AP`
ifname_fronthaul_ap_5g=`/bin/config get wl5g_NORMAL_AP`

not_connnected_5g=`iwconfig $ifname_backhaul_sta_5g 2>/dev/null | grep "Not-Associated" `
not_connnected_2g=`iwconfig $ifname_backhaul_sta_2g 2>/dev/null | grep "Not-Associated" `

if [ "x`uci get repacd.repacd.Role`" = "xCAP" ]; then
	hopcount=`iwpriv $ifname_fronthaul_ap_2g get_whc_dist |awk -F ":" '{print $2}'`
	echo $hopcount > $satellite_hop_count 2>/dev/null
	exit 0
else
	if [ -z "$not_connnected_5g" ]; then
		hopcount=`iwpriv $ifname_backhaul_sta_5g get_whc_dist |awk -F ":" '{print $2}'`
		echo $hopcount > $satellite_hop_count 2>/dev/null
		exit 0
    elif [ -z "$not_connnected_2g" ]; then
		hopcount=`iwpriv $ifname_backhaul_sta_2g get_whc_dist |awk -F ":" '{print $2}'`
		echo $hopcount > $satellite_hop_count 2>/dev/null
		exit 0
	else
		hopcount=`iwpriv $ifname_backhaul_sta_5g get_whc_dist |awk -F ":" '{print $2}'`
		echo $hopcount > $satellite_hop_count 2>/dev/null
		exit 0
	fi
fi
