#!/bin/sh
#
# Copyright (c) 2014, The Linux Foundation. All rights reserved.
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

IFNAME=$1
CMD=$2

if [ $CMD = "CONNECTED" ]; then
	. /sbin/wlan detect 1
fi

local parent=$(cat /sys/class/net/${IFNAME}/parent)

wifi_topology_file=${WIFI_TOPOLOGY_FILE:-/tmp/wifi_topology}

is_section_ifname() {
	local config=$1
	local ifname
	config_get ifname "$config" ifname
	[ "${ifname}" = "$2" ] && echo ${config}
}

get_ssid() {
	local conf=$1
	ssid=$(awk 'BEGIN{FS="="} /ssid=/ {print $0}' $conf |grep "ssid=" |tail -n 1 | cut -f 2 -d= | sed -e 's/^"\(.*\)"/\1/')
}

get_wpaver() {
	local conf=$1
	local proto
	local key_mgmt
	proto=$(awk 'BEGIN{FS="="} /proto=/ {print $0}' $conf |grep "proto=" |tail -n 1 | cut -f 2 -d= | sed -e 's/^"\(.*\)"/\1/')
	key_mgmt=$(awk 'BEGIN{FS="="} /key_mgmt=/ {print $0}' $conf |grep "key_mgmt=" |tail -n 1 | cut -f 2 -d= | sed -e 's/^"\(.*\)"/\1/')
	case "$key_mgmt:$proto" in
		NONE:*)
			wpa_version=NONE
			;;
		WPA-PSK:RSN)
			wpa_version=WPA2-PSK
			;;
		WPA-PSK:WPA)
			wpa_version=WPA-PSK
			;;
	esac
}

get_psk() {
	local count=
	local conf=$1
	local index=
	# This finds the last PSK in the supplicant config and strips off leading
	# and trailing quotes (if it has them). Generally the quotes are not there
	# when doing WPS push button.
	psk=$(awk 'BEGIN{FS="="} /psk=/ {print $0}' $conf |grep "psk=" |tail -n 1 | cut -f 2 -d= | sed -e 's/^"\(.*\)"/\1/')
}

wps_pbc_enhc_get_ap_overwrite() {
	local wps_pbc_enhc_file=/var/run/wifi-wps-enhc-extn.conf
	if [ -r $wps_pbc_enhc_file ]; then
		local overwrite_ap_all=$(awk "/\-:overwrite_ap_settings_all/ {print;exit}" $wps_pbc_enhc_file | sed "s/\-://")
		local overwrite_ap=$(awk "/$parent:overwrite_ap_settings/ {print;exit}" $wps_pbc_enhc_file | sed "s/$parent://")

		[ -n "$overwrite_ap_all" ] && \
			IFNAME_OVERWRITE=$(awk "/:[0-9\-]*:[0-9\-]*:/" $wps_pbc_enhc_file | cut -f1 -d:)

		[ -z "$overwrite_ap_all" -a -n "$overwrite_ap" ] && \
			IFNAME_OVERWRITE=$(awk "/:[0-9\-]*:[0-9\-]*:$parent/" $wps_pbc_enhc_file | cut -f1 -d:)
	fi
}

wps_pbc_enhc_overwrite_ap_settings() {
	local wps_pbc_enhc_file=/var/run/wifi-wps-enhc-extn.conf
	local ifname_overwrite=$1
	local ssid_overwrite=$2
	local auth_overwrite=$3
	local encr_overwrite=$4
	local key_overwrite=
	local parent_overwrite=$(cat /sys/class/net/${ifname_overwrite}/parent)
	local ssid_suffix=$(awk "/\-:overwrite_ssid_suffix:/ {print;exit}" $wps_pbc_enhc_file | \
						sed "s/\-:overwrite_ssid_suffix://")
	local ssid_band_suffix=$(awk "/$parent_overwrite:overwrite_ssid_band_suffix:/ {print;exit}" $wps_pbc_enhc_file | \
						sed "s/$parent_overwrite:overwrite_ssid_band_suffix://")

	[ "${auth_overwrite}" = "WPA2PSK" -o "${auth_overwrite}" = "WPAPSK" ] && key_overwrite=$5

	if [ -r /var/run/hostapd-${parent_overwrite}/${ifname_overwrite} ]; then
		hostapd_cli -i${ifname_overwrite} -p/var/run/hostapd-${parent_overwrite} wps_config \
			${ssid_overwrite}${ssid_suffix}${ssid_band_suffix} ${auth_overwrite} ${encr_overwrite} ${key_overwrite}
	fi
}

wps_update_running_supplicant() {
	local ifname="$1"
	local section=$(config_foreach is_section_ifname wifi-iface $ifname)
	local bridge=`uci get wireless.${section}.bridge`
	[ -z "$bridge" ] && bridge="br0"
	[ -f "/var/run/wpa_supplicant-${ifname}.lock" ] && {
		wpa_cli -g /var/run/wpa_supplicantglobal interface_remove ${ifname}
		rm /var/run/wpa_supplicant-${ifname}.lock
	} || {
		wpa_cli -g /var/run/wpa_supplicantglobal interface_remove ${ifname}
	}
	cp -f /var/run/wpa_supplicant-$IFNAME.conf /var/run/wpa_supplicant-$ifname.conf
	# Replace control interface
	sed -i -e "s/ctrl_interface=.*/ctrl_interface=\/var\/run\/wpa_supplicant-${ifname}/g" /var/run/wpa_supplicant-$ifname.conf
	sync
	wpa_cli -g /var/run/wpa_supplicantglobal interface_add $ifname /var/run/wpa_supplicant-$ifname.conf athr /var/run/wpa_supplicant-$ifname "" $bridge
	touch /var/run/wpa_supplicant-$ifname.lock
}

wps_setup_other_same_type_interfaces(){
	local ssid="$1"
	local wpa_version="$2"
	local psk="$3"
	# Find out the VAP name of other interface with same type and mode.
	for ifname in `awk -v input_ifname=$IFNAME -v search_rule=optype_opmode -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`; do
		local section=$(config_foreach is_section_ifname wifi-iface $ifname)
		case "$wpa_version" in
			WPA2-PSK)
				uci set wireless.${section}.encryption='psk2'
				uci set wireless.${section}.key=$psk
				for intf in $IFNAME_OVERWRITE; do
					wps_pbc_enhc_overwrite_ap_settings $intf $ssid WPA2PSK CCMP $psk
				done
				;;
			WPA-PSK)
				uci set wireless.${section}.encryption='psk'
				uci set wireless.${section}.key=$psk
				for intf in $IFNAME_OVERWRITE; do
					wps_pbc_enhc_overwrite_ap_settings $intf $ssid WPAPSK TKIP $psk
				done
				;;
			NONE)
				uci set wireless.${section}.encryption='none'
				uci set wireless.${section}.key=''
				for intf in $IFNAME_OVERWRITE; do
					wps_pbc_enhc_overwrite_ap_settings $intf $ssid OPEN NONE
				done
				;;
		esac
		uci set wireless.${section}.ssid="$ssid"
		uci commit wireless
		kill -9 "$(cat "/var/run/wps-hotplug-$ifname.pid")"
		rm -rf /var/run/wps-hotplug-$ifname.pid
		env -i PROG_SRC=athr-hostapd ACTION=SET_CONFIG SUPPLICANT_MODE=1 SECTION=$section IFNAME=$ifname FILE=/var/run/wpa_supplicant-$ifname.conf /sbin/hotplug-call wps
		wps_update_running_supplicant "$ifname"
	done
}

local psk=
local ssid=
local wpa_version=
local IFNAME_OVERWRITE=
local DAISYCHAIN_IFNAME_OVERWRITE=
local supplicant_lock_file="/var/run/supplicant.lock"

case "$CMD" in
	CONNECTED)
		# Cancel WPS PBC activating on other VAP with same type and mode.
		[ -f $supplicant_lock_file ] && exit
		touch $supplicant_lock_file
		local save_result
		echo "1" > /tmp/allconfig_flag
		for wifivap in `awk -v input_ifname=$IFNAME -v search_rule=opmode -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`; do
			wpa_cli -i$wifivap -p/var/run/wpa_supplicant-$wifivap wps_cancel
		done
		save_result=`wpa_cli -i$IFNAME -p/var/run/wpa_supplicant-$IFNAME save_config`
		[ -f /etc/list-network-id.awk -a "$save_result" != "FAIL" ] && {
			for id in `wpa_cli -i$IFNAME -p/var/run/wpa_supplicant-$IFNAME list_network | awk -v list_type="old" -f /etc/list-network-id.awk`; do
				wpa_cli -i$IFNAME -p/var/run/wpa_supplicant-$IFNAME remove_network $id
			done
			wpa_cli -i$IFNAME -p/var/run/wpa_supplicant-$IFNAME save_config
		}
		ssid=$(wpa_cli -i$IFNAME -p/var/run/wpa_supplicant-$IFNAME status | grep ^ssid= | cut -f2- -d =)
		wpa_version=$(wpa_cli -i$IFNAME -p/var/run/wpa_supplicant-$IFNAME status | grep ^key_mgmt= | cut -f2- -d=)
		[ -z "$ssid" ] && get_ssid /var/run/wpa_supplicant-$IFNAME.conf
		[ -z "$wpa_version" ] && get_wpaver /var/run/wpa_supplicant-$IFNAME.conf
		get_psk /var/run/wpa_supplicant-$IFNAME.conf
		wps_pbc_enhc_get_ap_overwrite
		local section=$(config_foreach is_section_ifname wifi-iface $IFNAME)

		config_load 'repacd'
		config_get_bool repacd_Enable repacd 'Enable' '0'
		config_get_bool wifimon_cfg config 'cfg80211_enable' '0'
		config_get_bool DaisyChain_Enable WiFiLink 'DaisyChain' '0'
		config_load 'wireless'

		if [ "$repacd_Enable" == "1" -a "$DaisyChain_Enable" == "1" ]; then
			DAISYCHAIN_IFNAME_OVERWRITE=`awk -v input_optype=BACKHAUL input_opmode=AP output_rule=ifname -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
		fi

		case "$wpa_version" in
			WPA2-PSK)
				uci set wireless.${section}.encryption='psk2'
				uci set wireless.${section}.key=$psk
				for intf in $IFNAME_OVERWRITE; do
					wps_pbc_enhc_overwrite_ap_settings $intf $ssid WPA2PSK CCMP $psk
				done
				if [ "$repacd_Enable" == "1" -a "$DaisyChain_Enable" == "1" ]; then
					for intf in $DAISYCHAIN_IFNAME_OVERWRITE; do
						qca_hostapd_config_file=/var/run/hostapd-`echo $intf`.conf
						sed -i '/^wpa/d' $qca_hostapd_config_file
						sed -i '/^ssid/d' $qca_hostapd_config_file

						echo "ssid=$ssid" >> $qca_hostapd_config_file
						echo "wpa=3" >> $qca_hostapd_config_file
						echo "wpa_pairwise=CCMP TKIP" >> $qca_hostapd_config_file
						echo "wpa_key_mgmt=WPA-PSK" >> $qca_hostapd_config_file

						if [ ${#psk} -eq 64 ]; then
							echo "wpa_psk=$psk" >> $qca_hostapd_config_file
						else
							echo "wpa_passphrase=$psk" >> $qca_hostapd_config_file
						fi
						wpa_cli -g /var/run/hostapd/global raw REMOVE $intf
						wpa_cli -g /var/run/hostapd/global raw ADD bss_config=`echo $intf`:$qca_hostapd_config_file
						overwrite_section=`awk -v output_rule=section -v input_ifname=$intf -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
						device=`uci get wireless.${overwrite_section}.device`
						pid=/var/run/hostapd_cli-`echo $intf`.pid
						hostapd_cli -i $intf -P $pid -a /lib/wifi/wps-hostapd-update-uci -p /var/run/hostapd-$device -B
					done
				fi
				;;
			WPA-PSK)
				uci set wireless.${section}.encryption='psk'
				uci set wireless.${section}.key=$psk
				for intf in $IFNAME_OVERWRITE; do
					wps_pbc_enhc_overwrite_ap_settings $intf $ssid WPAPSK TKIP $psk
				done
				if [ "$repacd_Enable" == "1" -a "$DaisyChain_Enable" == "1" ]; then
					for intf in $DAISYCHAIN_IFNAME_OVERWRITE; do
						qca_hostapd_config_file=/var/run/hostapd-`echo $intf`.conf
						sed -i '/^wpa/d' $qca_hostapd_config_file
						sed -i '/^ssid/d' $qca_hostapd_config_file

						echo "ssid=$ssid" >> $qca_hostapd_config_file
						echo "wpa=2" >> $qca_hostapd_config_file
						echo "wpa_pairwise=CCMP" >> $qca_hostapd_config_file
						echo "wpa_key_mgmt=WPA-PSK" >> $qca_hostapd_config_file

						if [ ${#psk} -eq 64 ]; then
							echo "wpa_psk=$psk" >> $qca_hostapd_config_file
						else
							echo "wpa_passphrase=$psk" >> $qca_hostapd_config_file
						fi
						wpa_cli -g /var/run/hostapd/global raw REMOVE $intf
						wpa_cli -g /var/run/hostapd/global raw ADD bss_config=$intf:$qca_hostapd_config_file
						overwrite_section=`awk -v output_rule=section -v input_ifname=$intf -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
						device=`uci get wireless.${overwrite_section}.device`
						pid=/var/run/hostapd_cli-`echo $intf`.pid
						hostapd_cli -i $intf -P $pid -a /lib/wifi/wps-hostapd-update-uci -p /var/run/hostapd-$device -B
					done
				fi
				;;
			NONE)
				uci set wireless.${section}.encryption='none'
				uci set wireless.${section}.key=''
				for intf in $IFNAME_OVERWRITE; do
					wps_pbc_enhc_overwrite_ap_settings $intf $ssid OPEN NONE
				done
				if [ "$repacd_Enable" == "1" -a "$DaisyChain_Enable" == "1" ]; then
					for intf in $DAISYCHAIN_IFNAME_OVERWRITE; do
						qca_hostapd_config_file=/var/run/hostapd-`echo $intf`.conf
						sed -i '/^wpa/d' $qca_hostapd_config_file
						sed -i '/^ssid/d' $qca_hostapd_config_file

						echo "ssid=$ssid" >> $qca_hostapd_config_file
						echo "wpa=0" >> $qca_hostapd_config_file
						wpa_cli -g /var/run/hostapd/global raw REMOVE $intf
						wpa_cli -g /var/run/hostapd/global raw ADD bss_config=$intf:$qca_hostapd_config_file
						overwrite_section=`awk -v output_rule=section -v input_ifname=$intf -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
						device=`uci get wireless.${overwrite_section}.device`
						pid=/var/run/hostapd_cli-`echo $intf`.pid
						hostapd_cli -i $intf -P $pid -a /lib/wifi/wps-hostapd-update-uci -p /var/run/hostapd-$device -B
					done
				fi
				;;
		esac
		uci set wireless.${section}.ssid="$ssid"
		uci commit wireless
		if [ -r /var/run/wifi-wps-enhc-extn.pid ]; then
			echo $IFNAME > /var/run/wifi-wps-enhc-extn.done
			kill -SIGUSR1 "$(cat "/var/run/wifi-wps-enhc-extn.pid")"
		fi
		kill "$(cat "/var/run/wps-hotplug-$IFNAME.pid")"
		rm -rf /var/run/wps-hotplug-$IFNAME.pid
		#post hotplug event to whom take care of
		env -i ACTION="wps-connected" INTERFACE=$IFNAME /sbin/hotplug-call iface
		# Save to DNI configuration system.
		env -i PROG_SRC=athr-hostapd ACTION=SET_CONFIG SUPPLICANT_MODE=1 SECTION=$section IFNAME=$IFNAME FILE=/var/run/wpa_supplicant-$IFNAME.conf /sbin/hotplug-call wps
		wps_setup_other_same_type_interfaces "$ssid" "$wpa_version" "$psk"

		backhaul_ap=`awk -v input_optype=BACKHAUL input_opmode=AP output_rule=ifname -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
		[ -z "$backhaul_ap" ] && {
			rm -rf $supplicant_lock_file
			return
		}

		for ifname in $backhaul_ap; do
			section=`awk -v output_rule=section -v input_ifname=$ifname -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`

			uci set wireless."$section".ssid=$ssid
			uci set wireless."$section".key=$psk
			uci commit wireless

			env -i PROG_SRC=athr-hostapd ACTION=SET_CONFIG SECTION=$section IFNAME=$ifname FILE=/var/run/hostapd-${ifname}.conf /sbin/hotplug-call wps
		done

		rm -rf $supplicant_lock_file
		if [ "$repacd_Enable" == "1" -a "$DaisyChain_Enable" == "1" ]; then

			if [ "$wifimon_cfg" == "1" ]; then
				REPACD_CFG80211=-cfg80211
			else
				REPACD_CFG80211=
			fi

			backhaul_sta=`awk -v input_optype=BACKHAUL input_opmode=STA output_rule=ifname -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`

			backhaul5g_sta=
			backhaul2g_sta=
			backhaul5g_sta_section=
			backhaul2g_sta_section=
			backhaul5g_disconnected=
			backhaul2g_disconnected=

			for ifname in $backhaul_sta; do

				hwmode=`iwconfig $ifname | grep IEEE | awk  '{print $3}'`
				case "$hwmode" in
				802.11ac|802.11na|802.11a)
					backhaul5g_sta="$ifname"
					backhaul5g_sta_section=`awk -v output_rule=section -v input_ifname=$ifname -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
					backhaul5g_disconnected=`iwconfig $ifname | grep "Not-Associated"`
				;;
				*)
					backhaul2g_sta="$ifname"
					backhaul2g_sta_section=`awk -v output_rule=section -v input_ifname=$ifname -f /etc/search-wifi-interfaces.awk /tmp/wifi_topology`
					backhaul2g_disconnected=`iwconfig $ifname | grep "Not-Associated"`
				;;
				esac
			done

			if [  -z "$backhaul5g_disconnected" ]; then

				if [ -z $REPACD_CFG80211 ]; then
					iwpriv $backhaul5g_sta sendprobereq 1
					best_bssid=`iwpriv $backhaul5g_sta get_whc_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`
					best_otherband_bssid=`iwpriv $backhaul5g_sta g_best_ob_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`

				else
					cfg80211tool $backhaul5g_sta sendprobereq 1
					best_bssid=`cfg80211tool $ifname get_whc_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`
					best_otherband_bssid=`cfg80211tool $sta_iface g_best_ob_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`
				fi

				uci set wireless."$backhaul5g_sta_section".bssid=$best_bssid
				uci set wireless."$backhaul2g_sta_section".bssid=$best_otherband_bssid
				uci commit wireless

				/bin/config set wla_ul_bssid="$best_bssid"
				/bin/config set wla_2nd_ul_bssid="$best_bssid"
				/bin/config set wlg_ul_bssid="$best_otherband_bssid"
				/bin/config commit

				wpa_cli -p /var/run/wpa_supplicant-$backhaul5g_sta disable_network 0
				wpa_cli -p /var/run/wpa_supplicant-$backhaul5g_sta set_network 0 bssid $best_bssid
				wpa_cli -p /var/run/wpa_supplicant-$backhaul5g_sta enable_network 0

				wpa_cli -p /var/run/wpa_supplicant-$backhaul2g_sta disable_network 0
				wpa_cli -p /var/run/wpa_supplicant-$backhaul2g_sta set_network 0 bssid $best_otherband_bssid
				wpa_cli -p /var/run/wpa_supplicant-$backhaul2g_sta enable_network 0
			elif [ -z "$backhaul2g_disconnected" ]; then
				if [ -z $REPACD_CFG80211 ]; then
					iwpriv $backhaul2g_sta sendprobereq 1
					best_bssid=`iwpriv $backhaul2g_sta get_whc_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`
					best_otherband_bssid=`iwpriv $backhaul2g_sta g_best_ob_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`

				else
					cfg80211tool $backhaul2g_sta sendprobereq 1
					best_bssid=`cfg80211tool $backhaul2g_sta get_whc_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`
					best_otherband_bssid=`cfg80211tool $backhaul5g_sta g_best_ob_bssid | awk -F":" '{print $2}' | \
					sed -e "s/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1:\2:\3:\4:\5:\6/"`
				fi

				uci set wireless."$backhaul2g_sta_section".bssid=$best_bssid
				uci set wireless."$backhaul5g_sta_section".bssid=$best_otherband_bssid
				uci commit wireless

				/bin/config set wla_ul_bssid="$best_otherband_bssid"
				/bin/config set wla_2nd_ul_bssid="$best_otherband_bssid"
				/bin/config set wlg_ul_bssid="$best_bssid"
				/bin/config commit

				wpa_cli -p /var/run/wpa_supplicant-$backhaul5g_sta disable_network 0
				wpa_cli -p /var/run/wpa_supplicant-$backhaul5g_sta set_network 0 bssid $best_otherband_bssid
				wpa_cli -p /var/run/wpa_supplicant-$backhaul5g_sta enable_network 0

				wpa_cli -p /var/run/wpa_supplicant-$backhaul2g_sta disable_network 0
				wpa_cli -p /var/run/wpa_supplicant-$backhaul2g_sta set_network 0 bssid $best_bssid
				wpa_cli -p /var/run/wpa_supplicant-$backhaul2g_sta enable_network 0
			else
				uci set wireless."$backhaul2g_sta_section".bssid='00:00:00:00:00:00'
				uci commit wireless
				/bin/config set wlg_ul_bssid="00:00:00:00:00:00"
				/bin/config commit
			fi

		fi
		;;
	WPS-TIMEOUT)
		kill "$(cat "/var/run/wps-hotplug-$IFNAME.pid")"
		env -i ACTION="wps-timeout" INTERFACE=$IFNAME /sbin/hotplug-call iface
		;;
	DISCONNECTED)
		;;
esac

