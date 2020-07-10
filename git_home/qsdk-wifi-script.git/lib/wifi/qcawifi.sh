#!/bin/sh
#
# Copyright (c) 2014, 2016, The Linux Foundation. All rights reserved.
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
append DRIVERS "qcawifi"

[ -f /etc/ath/wifi.conf ] && . /etc/ath/wifi.conf

#
# Put qcawifi's country (ISO 3166-1 Alpha-2) to country code conversion
# (digits) table to /etc/ath/country_code_mapping_table.txt for all later code
# to access.
#
countrycode_mapping_qcawifi() {
    cp /lib/wifi/qcawifi_countrycode.txt \
       /etc/ath/country_code_mapping_table.txt
}

#
# Convert country code to country (ISO 3166-1 Alpha-2)
#
# Look up conversion table to convert country code (digits) to country (ISO
# 3166-1 Alpha-2).
#
# input:  $1 - country code (digits).
# output: $2 - country (ISO 3166-1 Alpha-2).
#              If no input country code (digits) is found, then return digits.
#
countrycode2str() {
    local digit_country_code=$1

    local str_country_code=$(
            eval awk \'/ ${digit_country_code}\$/ { print \$1 }\' \
                     /etc/ath/country_code_mapping_table.txt)

    if [ -z "$str_country_code" ]; then
        eval "$2"="$digit_country_code"
    else
        eval "$2"="$str_country_code"
    fi
}

VLAN_DHCPD=/sbin/vlan-dhcpd

find_qca_wifi_dir() {
    if [ `find /etc/modules.d/ -type f -name "33-qca-wifi*" | wc -l` -ge 1 ]; then
        eval export -- "${1}=/etc/modules.d"
    else
        eval export -- "${1}=/lib/wifi"
    fi
}

portal_acl_redirect_rules() {
    local ETH_P_IP=0x0800
    local IPPROTO_TCP=6
    Chain="$1"

    [ -f "/module_name" ] && product=`/bin/cat /module_name`
    if [ "$product" = "SRR60"  -o "$product" = "SRS60" -o "$product" = "RBS50Y" -o "$product" = "SRS60E" ]; then
        CP_HTTP_PORT="$(/bin/config get cp_http_port)"
        CP_HTTPS_PORT="$(/bin/config get cp_https_port)"
        if [ "x$CP_HTTP_PORT" = "x" ]; then
            CP_HTTP_PORT=12000
        fi
        if [ "x$CP_HTTPS_PORT" = "x" ]; then
            CP_HTTPS_PORT=13000
        fi
        if [ "$2" = "ADD" ]; then
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto "$IPPROTO_TCP" --ip-sport "$CP_HTTP_PORT" -j ACCEPT
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto "$IPPROTO_TCP" --ip-dport "$CP_HTTP_PORT" -j ACCEPT
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto "$IPPROTO_TCP" --ip-sport "$CP_HTTPS_PORT" -j ACCEPT
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto "$IPPROTO_TCP" --ip-dport "$CP_HTTPS_PORT" -j ACCEPT
        elif [ "$2" = "DELETE" ]; then
            ebtables -D "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_TCP" --ip-dport "$CP_HTTP_PORT" -j ACCEPT 2>/dev/null >/dev/null
            ebtables -D "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_TCP" --ip-sport "$CP_HTTP_PORT" -j ACCEPT 2>/dev/null >/dev/null
            ebtables -D "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_TCP" --ip-dport "$CP_HTTPS_PORT" -j ACCEPT 2>/dev/null >/dev/null
            ebtables -D "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_TCP" --ip-sport "$CP_HTTPS_PORT" -j ACCEPT 2>/dev/null >/dev/null
        fi
    fi
}

add_lan_restricted_chain()
{
    IN_Chain="GUEST_IN"
    FWD_IN_Chain="GUEST_FWD_IN"
    FWD_OUT_Chain="GUEST_FWD_OUT"

    add_lan_restricted_guest_rule "$IN_Chain"
    add_lan_restricted_guest_rule "$FWD_IN_Chain"
    add_lan_restricted_guest_rule "$FWD_OUT_Chain"
}

add_ipv6_restricated_rules()
{
	local Chain="$1"
	local ETH_P_IPv6=0x86dd
	lan_ipv6addr=$(ifconfig $bridge | grep "inet6 addr" | awk '{print $3}')
	for ipv6addr in $lan_ipv6addr ; do
		ebtables -A "$Chain" -p "$ETH_P_IPv6" --ip6-dst "$ipv6addr" -j DROP
	done
}

add_lan_restricted_guest_rule()
{
    Chain="$1"
    IN_Chain="GUEST_IN"
    FWD_IN_Chain="GUEST_FWD_IN"
    FWD_OUT_Chain="GUEST_FWD_OUT"
    local ETH_P_ARP=0x0806
    local ETH_P_RARP=0x8035
    local ETH_P_IP=0x0800
    local ETH_P_IPv6=0x86dd
    local IPPROTO_UDP=17
    local IPPROTO_ICMPv6=58
    local DHCPS_DHCPC=67:68
    local DHCP6S_DHCP6C=546:547
    local PORT_DNS=53

    if [ "x$Chain" = "x" ]; then
	return
    fi

    ebtables -N "$Chain"
    ebtables -P "$Chain" RETURN
    ebtables -A "$Chain" -p "$ETH_P_ARP" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_RARP" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_UDP" --ip6-sport "$PORT_DNS" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_UDP" --ip6-dport "$PORT_DNS" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_UDP" --ip6-dport "$DHCP6S_DHCP6C" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_UDP" --ip-sport "$PORT_DNS" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_UDP" --ip-dport "$PORT_DNS" -j ACCEPT
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-proto "$IPPROTO_UDP" --ip-dport "$DHCPS_DHCPC" -j ACCEPT
    portal_acl_redirect_rules "$Chain" "ADD"

    config_get bridge "$vif" bridge
    lan_ipaddr=$(ifconfig $bridge | grep "inet addr" | awk '{print $2}'| awk -F ':' '{print $2}')
    netmask=$(ifconfig $bridge | grep "inet addr" | awk '{print $4}'| awk -F ':' '{print $2}')
    calculate_subnet $lan_ipaddr $netmask brsubnet

    if [ "$Chain" = "$IN_Chain" ]; then
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-dst "$brsubnet" -j DROP
    add_ipv6_restricated_rules "$Chain"
	[ -f "/tmp/orbi_type" ] && product_type=`/bin/cat /tmp/orbi_type`
        if [ "$product_type" = "Satellite" ]; then
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto tcp --ip-dport 22 -j DROP
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto tcp --ip-dport 23 -j DROP
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto tcp --ip-dport 80 -j DROP
            ebtables -A "$Chain" -p $ETH_P_IP --ip-proto icmp -j DROP
        fi
    elif [ "$Chain" = "$FWD_IN_Chain" ]; then
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-dst "$brsubnet" -j DROP
    add_ipv6_restricated_rules "$Chain"
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-dst 224.0.0.0/4 -j DROP
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-dst 255.255.255.255 -j DROP
    ebtables -A "$Chain" -p "$ETH_P_IPv6" --ip6-dst FF00::/8 -j DROP
    ebtables -A "$Chain" -d 01:00:00:00:00:00/01:00:00:00:00:00 -j DROP
    elif [ "$Chain" = "$FWD_OUT_Chain" ]; then
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-src "$brsubnet" -j DROP
    add_ipv6_restricated_rules "$Chain"
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-dst 224.0.0.0/4 -j DROP
    ebtables -A "$Chain" -p "$ETH_P_IP" --ip-dst 255.255.255.255 -j DROP
    ebtables -A "$Chain" -p "$ETH_P_IPv6" --ip6-dst FF00::/8 -j DROP
    ebtables -A "$Chain" -d 01:00:00:00:00:00/01:00:00:00:00:00 -j DROP
    fi
}

del_lan_restricted_chain()
{
    IN_Chain="GUEST_IN"
    FWD_IN_Chain="GUEST_FWD_IN"
    FWD_OUT_Chain="GUEST_FWD_OUT"
    ebtables -X "$IN_Chain"
    ebtables -X "$FWD_IN_Chain"
    ebtables -X "$FWD_OUT_Chain"
}

reload_time_qcawifi() {
	local devices="$2"
	local wifi_reload_time=14
	local wifi_reload_vap_time=2
	local module_reload_time=16
	local module_reload=$(uci_get wireless qcawifi module_reload 1)

	test "$module_reload" = "1" && wifi_reload_time=$(( $wifi_reload_time + $module_reload_time ))
	for device in ${devices}; do
		config_get vifs "$device" vifs
		for vif in $vifs; do
			wifi_reload_time=$(( $wifi_reload_time + $wifi_reload_vap_time ))
		done
	done
	eval "export $1=$wifi_reload_time"
}

wlanconfig() {
	[ -n "${DEBUG}" ] && echo wlanconfig "$@"
	/usr/sbin/wlanconfig "$@"
}

iwconfig() {
	[ -n "${DEBUG}" ] && echo iwconfig "$@"
	/usr/sbin/iwconfig "$@"
}

iwpriv() {
	[ -n "${DEBUG}" ] && echo iwpriv "$@"
	/usr/sbin/iwpriv "$@"
}

find_qcawifi_phy() {
	local device="$1"

	local macaddr="$(config_get "$device" macaddr | tr 'A-Z' 'a-z')"
	config_get phy "$device" phy
	[ -z "$phy" -a -n "$macaddr" ] && {
		cd /sys/class/net
		for phy in $(ls -d wifi* 2>&-); do
			[ "$macaddr" = "$(cat /sys/class/net/${phy}/address)" ] || continue
			config_set "$device" phy "$phy"
			break
		done
		config_get phy "$device" phy
	}
	[ -n "$phy" -a -d "/sys/class/net/$phy" ] || {
		echo "phy for wifi device $1 not found"
		return 1
	}
	[ -z "$macaddr" ] && {
		config_set "$device" macaddr "$(cat /sys/class/net/${phy}/address)"
	}
	return 0
}

scan_qcawifi() {
	local device="$1"
	local wds
	local adhoc sta ap monitor ap_monitor ap_smart_monitor mesh ap_lp_iot disabled

	[ ${device%[0-9]} = "wifi" ] && config_set "$device" phy "$device"

	local ifidx=0
	local radioidx=${device#wifi}

	config_get vifs "$device" vifs
	for vif in $vifs; do
		config_get_bool disabled "$vif" disabled 0
		[ $disabled = 0 ] || continue

		local vifname
		[ $ifidx -gt 0 ] && vifname="ath${radioidx}$ifidx" || vifname="ath${radioidx}"

		config_get ifname "$vif" ifname
		[ -z "$ifname" ] && config_set "$vif" ifname $vifname

		config_get mode "$vif" mode
		case "$mode" in
			adhoc|sta|ap|monitor|wrap|ap_monitor|ap_smart_monitor|mesh|ap_lp_iot)
				append "$mode" "$vif"
			;;
			wds)
				config_get ssid "$vif" ssid
				[ -z "$ssid" ] && continue

				config_set "$vif" wds 1
				config_set "$vif" mode sta
				mode="sta"
				addr="$ssid"
				${addr:+append "$mode" "$vif"}
			;;
			*) echo "$device($vif): Invalid mode, ignored."; continue;;
		esac

		ifidx=$(($ifidx + 1))
	done

	case "${adhoc:+1}:${sta:+1}:${ap:+1}" in
		# valid mode combinations
		1::) wds="";;
		1::1);;
		:1:1)config_set "$device" nosbeacon 1;; # AP+STA, can't use beacon timers for STA
		:1:);;
		::1);;
		::);;
		*) echo "$device: Invalid mode combination in config"; return 1;;
	esac

	config_set "$device" vifs "${ap:+$ap }${ap_monitor:+$ap_monitor }${mesh:+$mesh }${ap_smart_monitor:+$ap_smart_monitor }${wrap:+$wrap }${sta:+$sta }${adhoc:+$adhoc }${wds:+$wds }${monitor:+$monitor}${ap_lp_iot:+$ap_lp_iot}"
}

# The country ID is set at the radio level. When the driver attaches the radio,
# it sets the default country ID to 840 (US STA). This is because the desired
# VAP modes are not known at radio attach time, and STA functionality is the
# common unit of 802.11 operation.
# If the user desires any of the VAPs to be in AP mode, then we set a new
# default of 843 (US AP with TDWR) from this script. Even if any of the other
# VAPs are in non-AP modes like STA or Monitor, the stricter default of 843
# will apply.
# No action is required here if none of the VAPs are in AP mode.
set_default_country() {
	local device="$1"
	local mode

	find_qcawifi_phy "$device" || return 1
	config_get phy "$device" phy

	config_get vifs "$device" vifs
	for vif in $vifs; do
		config_get_bool disabled "$vif" disabled 0
		[ $disabled = 0 ] || continue

		config_get mode "$vif" mode
		case "$mode" in
			ap|wrap|ap_monitor|ap_smart_monitor|ap_lp_iot)
				iwpriv "$phy" setCountryID 843
				return 0;
			;;
		*) ;;
		esac
	done

	return 0
}

config_low_targ_clkspeed() {
        local board_name
        [ -f /tmp/sysinfo/board_name ] && {
                board_name=$(cat /tmp/sysinfo/board_name)
        }

        case "$board_name" in
                ap147 | ap151)
                   echo "true"
                ;;
                *) echo "false"
                ;;
        esac
}

# configure tx queue fc_buf_max
config_tx_fc_buf() {
	local phy="$1"
	local board_name
	[ -f /tmp/sysinfo/board_name ] && {
		board_name=$(cat /tmp/sysinfo/board_name)
	}
	memtotal=$(grep MemTotal /proc/meminfo | awk '{print $2}')

	case "$board_name" in
		ap-dk*)
			if [ $memtotal -le 131072 ]; then
				# 4MB tx queue max buffer size
				iwpriv "$phy" fc_buf_max 4096
				iwpriv "$phy" fc_q_max 512
				iwpriv "$phy" fc_q_min 32
			elif [ $memtotal -le 256000 ]; then
				# 8MB tx queue max buffer size
				iwpriv "$phy" fc_buf_max 8192
				iwpriv "$phy" fc_q_max 1024
				iwpriv "$phy" fc_q_min 64
			fi
				# default value from code memsize > 256MB
		;;

		*)
		;;
	esac
}

load_qcawifi() {
	lock /var/run/wifilock
	local umac_args
	local qdf_args
	local ol_args
        local cfg_low_targ_clkspeed
	local qca_da_needed=0
	local qca_ol_needed=0
	local device
	local board_name
	local def_pktlog_support=1
	local ath_dev_args

	[ -f /tmp/sysinfo/board_name ] && {
		board_name=$(cat /tmp/sysinfo/board_name)
	}
	memtotal=$(grep MemTotal /proc/meminfo | awk '{print $2}')

	case "$board_name" in
		ap-dk01.1-c1 | ap-dk01.1-c2 | ap-dk04.1-c1 | ap-dk04.1-c2 | ap-dk04.1-c3)
			if [ $memtotal -le 131072 ]; then
				echo 1 > /proc/net/skb_recycler/max_skbs
				echo 1 > /proc/net/skb_recycler/max_spare_skbs
				append umac_args "low_mem_system=1"
			fi
		;;
		ap152 | ap147 | ap151 | ap135 | ap137)
			if [ $memtotal -le 66560 ]; then
				def_pktlog_support=0
			fi
		;;
	esac

	config_get_bool testmode qcawifi testmode
	[ -n "$testmode" ] && append ol_args "testmode=$testmode"

	config_get vow_config qcawifi vow_config
	[ -n "$vow_config" ] && append ol_args "vow_config=$vow_config"

	config_get ol_bk_min_free qcawifi ol_bk_min_free
	[ -n "$ol_bk_min_free" ] && append ol_args "OL_ACBKMinfree=$ol_bk_min_free"

	config_get ol_be_min_free qcawifi ol_be_min_free
	[ -n "$ol_be_min_free" ] && append ol_args "OL_ACBEMinfree=$ol_be_min_free"

	config_get ol_vi_min_free qcawifi ol_vi_min_free
	[ -n "$ol_vi_min_free" ] && append ol_args "OL_ACVIMinfree=$ol_vi_min_free"

	config_get ol_vo_min_free qcawifi ol_vo_min_free
	[ -n "$ol_vo_min_free" ] && append ol_args "OL_ACVOMinfree=$ol_vo_min_free"

	config_get_bool ar900b_emu qcawifi ar900b_emu
	[ -n "$ar900b_emu" ] && append ol_args "ar900b_emu=$ar900b_emu"

	config_get frac qcawifi frac
	[ -n "$frac" ] && append ol_args "frac=$frac"

	config_get intval qcawifi intval
	[ -n "$intval" ] && append ol_args "intval=$intval"

	config_get atf_mode qcawifi atf_mode
	[ -n "$atf_mode" ] && append umac_args "atf_mode=$atf_mode"

        config_get atf_msdu_desc qcawifi atf_msdu_desc
        [ -n "$atf_msdu_desc" ] && append umac_args "atf_msdu_desc=$atf_msdu_desc"

        config_get atf_peers qcawifi atf_peers
        [ -n "$atf_peers" ] && append umac_args "atf_peers=$atf_peers"

        config_get atf_max_vdevs qcawifi atf_max_vdevs
        [ -n "$atf_max_vdevs" ] && append umac_args "atf_max_vdevs=$atf_max_vdevs"

	config_get fw_dump_options qcawifi fw_dump_options
	[ -n "$fw_dump_options" ] && append ol_args "fw_dump_options=$fw_dump_options"

	config_get enableuartprint qcawifi enableuartprint
	[ -n "$enableuartprint" ] && append ol_args "enableuartprint=$enableuartprint"

	config_get ar900b_20_targ_clk qcawifi ar900b_20_targ_clk
	[ -n "$ar900b_20_targ_clk" ] && append ol_args "ar900b_20_targ_clk=$ar900b_20_targ_clk"

	config_get qca9888_20_targ_clk qcawifi qca9888_20_targ_clk
	[ -n "$qca9888_20_targ_clk" ] && append ol_args "qca9888_20_targ_clk=$qca9888_20_targ_clk"

        cfg_low_targ_clkspeed=$(config_low_targ_clkspeed)
        [ -z "$qca9888_20_targ_clk" ] && [ $cfg_low_targ_clkspeed = "true" ] && append ol_args "qca9888_20_targ_clk=300000000"

	config_get max_descs qcawifi max_descs
	[ -n "$max_descs" ] && append ol_args "max_descs=$max_descs"

	config_get max_peers qcawifi max_peers
	[ -n "$max_peers" ] && append ol_args "max_peers=$max_peers"

	config_get qwrap_enable qcawifi qwrap_enable
	[ -n "$qwrap_enable" ] && append ol_args "qwrap_enable=$qwrap_enable"

	config_get otp_mod_param qcawifi otp_mod_param
	[ -n "$otp_mod_param" ] && append ol_args "otp_mod_param=$otp_mod_param"

	config_get max_active_peers qcawifi max_active_peers
	[ -n "$max_active_peers" ] && append ol_args "max_active_peers=$max_active_peers"

	config_get enable_smart_antenna qcawifi enable_smart_antenna
	[ -n "$enable_smart_antenna" ] && append ol_args "enable_smart_antenna=$enable_smart_antenna"

	#
	# Meanings of values of "wl_power_limit":
	#     1: Keep wireless driver power limits
	#     0: Remove wireless driver power limits to always honor power
	#        limits in Wi-Fi boarddata files (BDF)
	#
	config_get wl_super_wifi qcawifi wl_super_wifi
	config_get wl_power_limit qcawifi wl_power_limit
	if [ "$wl_super_wifi" == "1" ] || [ "$wl_power_limit" == "0" ]; then
		append ol_args "wl_power_limit=0"
	else
		append ol_args "wl_power_limit=1"
	fi

	#
	# Meanings of values of "wla_power_limit":
	#     1: Keep wireless driver power limits
	#     0: Remove wireless driver power limits to always honor power
	#        limits in Wi-Fi boarddata files (BDF)
	#
	config_get wla_super_wifi qcawifi wla_super_wifi
	config_get wla_power_limit qcawifi wla_power_limit
	if [ "$wla_super_wifi" == "1" ] || [ "$wla_power_limit" == "0" ]; then
		append ol_args "wla_power_limit=0"
	else
		append ol_args "wla_power_limit=1"
	fi

	config_get nss_wifi_olcfg qcawifi nss_wifi_olcfg
	if [ -n "$nss_wifi_olcfg" ]; then
		append ol_args "nss_wifi_olcfg=$nss_wifi_olcfg"
	elif [ -f /lib/wifi/wifi_nss_olcfg ]; then
		nss_wifi_olcfg="$(cat /lib/wifi/wifi_nss_olcfg)"

		if [ $nss_wifi_olcfg != 0 ]; then
			if [ -f /lib/wifi/wifi_nss_override ] && [ $(cat /lib/wifi/wifi_nss_override) = 1 ]; then
				echo "NSS offload disabled due to unsupported config" >&2
				append ol_args "nss_wifi_olcfg=0"
			else
				append ol_args "nss_wifi_olcfg=$nss_wifi_olcfg"
			fi
		fi
	fi

	config_get max_clients qcawifi max_clients
	[ -n "$max_clients" ] && append ol_args "max_clients=$max_clients"

	config_get max_vaps qcawifi max_vaps
	[ -n "$max_vaps" ] && append ol_args "max_vaps=$max_vaps"

	config_get enable_smart_antenna_da qcawifi enable_smart_antenna_da
	[ -n "$enable_smart_antenna_da" ] && append umac_args "enable_smart_antenna_da=$enable_smart_antenna_da"

	config_get prealloc_disabled qcawifi prealloc_disabled
	[ -n "$prealloc_disabled" ] && append qdf_args "prealloc_disabled=$prealloc_disabled"

	if [ -n "$nss_wifi_olcfg" ] && [ "$nss_wifi_olcfg" != "0" ]; then
		sysctl dev.nss.n2hcfg.n2h_high_water_core0 >/dev/null 2>/dev/null
	        nss_wifi_olnum="$(cat /lib/wifi/wifi_nss_olnum)"
		if [ "$nss_wifi_olnum" == "2" ]; then
		    sysctl -w dev.nss.n2hcfg.extra_pbuf_core0=5939200 >/dev/null 2>/dev/null
		    sysctl -w dev.nss.n2hcfg.n2h_high_water_core0=59392 >/dev/null 2>/dev/null
		    sysctl -w dev.nss.n2hcfg.n2h_wifi_pool_buf=35584 >/dev/null 2>/dev/null
		else
		    sysctl -w dev.nss.n2hcfg.extra_pbuf_core0=4096000 >/dev/null 2>/dev/null
		    sysctl -w dev.nss.n2hcfg.n2h_high_water_core0=43008 >/dev/null 2>/dev/null
		    sysctl -w dev.nss.n2hcfg.n2h_wifi_pool_buf=19200 >/dev/null 2>/dev/null
		fi
	fi

	config_get lteu_support qcawifi lteu_support
	[ -n "$lteu_support" ] && append ol_args "lteu_support=$lteu_support"

	config_get enable_mesh_support qcawifi enable_mesh_support
	[ -n "$enable_mesh_support" ] && append ol_args "enable_mesh_support=$enable_mesh_support"


	if [ -n "$enable_mesh_support" ]; then
		config_get enable_mesh_peer_cap_update qcawifi enable_mesh_peer_cap_update
		[ -n "$enable_mesh_peer_cap_update" ] && append umac_args "enable_mesh_peer_cap_update=$enable_mesh_peer_cap_update"
	fi

	config_get enable_pktlog_support qcawifi enable_pktlog_support $def_pktlog_support
	[ -n "$enable_pktlog_support" ] && append umac_args "enable_pktlog_support=$enable_pktlog_support"

	config_get paprd_enable qcawifi paprd_enable
	[ -n "$paprd_enable" ] && append ath_dev_args "paprd_enable=$paprd_enable"

	for mod in $(cat /lib/wifi/33-qca-wifi*); do
		case ${mod} in
			umac) [ -d /sys/module/${mod} ] || { \

				insmod ${mod} ${umac_args} || { \
					lock -u /var/run/wifilock
					unload_qcawifi
					return 1
				}
			};;

			qdf) [ -d /sys/module/${mod} ] || { \
				insmod ${mod} ${qdf_args} || { \
					lock -u /var/run/wifilock
					unload_qcawifi
					return 1
				}
			};;

			qca_ol) [ -f /tmp/no_qca_ol ] || { \
					[ -d /sys/module/${mod} ] || { \
					insmod ${mod} ${ol_args} || { \
						lock -u /var/run/wifilock
						unload_qcawifi
						return 1
					}
				}
			};;

			ath_dev) [ -f /tmp/no_qca_da ] || { \
				[ -d /sys/module/${mod} ] || { \
					insmod ${mod} ${ath_dev_args} || { \
						lock -u /var/run/wifilock
						unload_qcawifi
						return 1
					}
				}
			};;

			qca_da|hst_tx99|ath_rate_atheros|ath_hal) [ -f /tmp/no_qca_da ] || { \
				[ -d /sys/module/${mod} ] || { \
					insmod ${mod} || { \
						lock -u /var/run/wifilock
						unload_qcawifi
						return 1
					}
				}
			};;

			ath_pktlog) [ $enable_pktlog_support -eq 0 ] || { \
				[ -d /sys/module/${mod} ] || { \
					insmod ${mod} || { \
						lock -u /var/run/wifilock
						unload_qcawifi
						return 1
					}
				}
			};;

			*) [ -d /sys/module/${mod} ] || { \
				insmod ${mod} || { \
					lock -u /var/run/wifilock
					unload_qcawifi
					return 1
				}
			};;

		esac
	done

       # Remove DA/OL modules, if no DA/OL chipset found
	for device in $(ls -d /sys/class/net/wifi* 2>&-); do
		[[ -f $device/is_offload ]] || {
			qca_da_needed=1
		}
		[[ -f $device/is_offload ]] && {
			qca_ol_needed=1
		}
	done

	if [ $qca_ol_needed -eq 0 ]; then
		if [ ! -f /tmp/no_qca_ol ]; then
			echo "No offload chipsets found." >/dev/console
			rmmod qca_ol > /dev/null 2> /dev/null
			cat "1" > /tmp/no_qca_ol
		fi
	fi

	if [ $qca_da_needed -eq 0 ]; then
		if [ ! -f /tmp/no_qca_da ]; then
			echo "No Direct-Attach chipsets found." >/dev/console
			rmmod qca_da > /dev/null 2> /dev/null
			rmmod ath_dev > /dev/null 2> /dev/null
			rmmod hst_tx99 > /dev/null 2> /dev/null
			rmmod ath_rate_atheros > /dev/null 2> /dev/null
			rmmod ath_hal > /dev/null 2> /dev/null
			cat "1" > /tmp/no_qca_da
		fi
	fi
	lock -u /var/run/wifilock
}

unload_qcawifi() {
	# "config_load wireless" will re-export parameter which will affect original parameter.
	# ex. Device parameter will be changed to last wifiX. At Orbi project, device will be changed to wifi2.
	config_load wireless
	config_foreach disable_qcawifi wifi-device
	eval "type lowi_teardown" >/dev/null 2>&1 && lowi_teardown
	sleep 3
	lock /var/run/wifilock
	for mod in $(cat /lib/wifi/33-qca-wifi* | sed '1!G;h;$!d'); do
        case ${mod} in
            mem_manager) continue;
            esac
		[ -d /sys/module/${mod} ] && rmmod ${mod}
	done
	lock -u /var/run/wifilock
}


_disable_qcawifi() {
	local device="$1"
	local parent
	local retval=0

	# Does this "$device" contain only backhaul ifaces? 1 = yes, 0 = no
	local backhaul_only=1

	echo "$DRIVERS disable radio $1" >/dev/console

	find_qcawifi_phy "$device" >/dev/null || return 1


	config_get phy "$device" phy

	set_wifi_down "$device"

	clear_wifi_ebtables

	include /lib/network
	cd /sys/class/net
	for dev in *; do
		[ -f /sys/class/net/${dev}/parent ] && { \
			local parent=$(cat /sys/class/net/${dev}/parent)
			[ -n "$parent" -a "$parent" = "$device" ] && { \
				[ -f "/var/run/hostapd-${dev}.lock" ] && { \
					wpa_cli -g /var/run/hostapd/global raw REMOVE ${dev}
					rm /var/run/hostapd-${dev}.lock
				}
				[ -f "/var/run/wpa_supplicant-${dev}.lock" ] && { \
					wpa_cli -g /var/run/wpa_supplicantglobal  interface_remove  ${dev}
					rm /var/run/wpa_supplicant-${dev}.lock
				}
				[ -f "/var/run/wapid-${dev}.conf" ] && { \
					kill "$(cat "/var/run/wifi-${dev}.pid")"
				}
				ifconfig "$dev" down
				unbridge "$dev"
				wlanconfig "$dev" destroy
			}
			[ -f /var/run/hostapd_cred_${device}.bin ] && { \
				rm /var/run/hostapd_cred_${device}.bin
			}
		}
	done

	# delete wlan uptime file
	config_get vifs "$device" vifs
	for vif in $vifs; do
		config_get backhaul "$vif" backhaul 0
		[ -n "$backhaul" -a "$backhaul" = 1 ] && continue
		backhaul_only=0
		break
	done

	# don't count wifi status for backhaul vap only radio
	[ "$backhaul_only" = "0" ] && {
		band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
		if [ "$band_type" = "g" ]; then
			rm /tmp/WLAN_uptime
			echo "OFF" > /tmp/WLAN_2G_status
		elif [ "$band_type" = "a" ]; then
			rm /tmp/WLAN_uptime_5G
			echo "OFF" > /tmp/WLAN_5G_status
		fi
	}

	return 0
}

reload_check_qcawifi() {
    [ ! -d /sys/module/umac ] && {
        echo "umac module is expected to be inserted, but not, so load WiFi modules again"
        load_qcawifi
    } || {
        echo "No reload qcawifi modules"
    }
}

set_boarddata() {
	local country_code="$1"

	local country

	REGULATORY_DOMAIN=FCC_ETSI

	IPQ4019_BDF_DIR=/lib/firmware/IPQ4019/hw.1
	QCA9984_BDF_DIR=/lib/firmware/QCA9984/hw.1
	QCA9888_BDF_DIR=/lib/firmware/QCA9888/hw.2

	config_get wl_super_wifi qcawifi wl_super_wifi
	config_get wla_super_wifi qcawifi wla_super_wifi
	if [ "$wl_super_wifi" == "1" ] || [ "$wla_super_wifi" == "1" ]; then
		REGULATORY_DOMAIN=SUPER_WIFI
	else
		countrycode2str "$country_code" country
		case "$country" in
			CA|5001)
				REGULATORY_DOMAIN=Canada
				;;
			AU|5000)
				REGULATORY_DOMAIN=AU
				;;
			KR|412)
				REGULATORY_DOMAIN=Korea
				;;
			IN|356)
				REGULATORY_DOMAIN=INS
				;;
			MX|484)
				REGULATORY_DOMAIN=MX
				;;
			MY|458|CN|156|TH|764)
				REGULATORY_DOMAIN=SRRC
				;;
			SG|702)
				REGULATORY_DOMAIN=Singapore
				;;
			VN|704)
				REGULATORY_DOMAIN=Vietnam
				;;
			HK|344)
				REGULATORY_DOMAIN=HongKong
				;;
		esac
	fi

	BOARD_VERSION=$(/bin/cat /tmp/hw_revision)

	if [ "${BOARD_VERSION}" == "01" ]; then
		BOARD_ID="board-01"
	elif [ "${BOARD_VERSION}" == "02" ]; then
		BOARD_ID="board-02"
	else
		BOARD_ID=""
	fi

	REGULATORY_DOMAIN="$BOARD_ID/$REGULATORY_DOMAIN"

	if [ -d $IPQ4019_BDF_DIR/$REGULATORY_DOMAIN ]; then
		/bin/cp -f $IPQ4019_BDF_DIR/$REGULATORY_DOMAIN/* $IPQ4019_BDF_DIR/
	else
		if [ "$wl_super_wifi" == "1" ] || [ "$wla_super_wifi" == "1" ]; then
			/bin/cp -f $IPQ4019_BDF_DIR/SRRC/* $IPQ4019_BDF_DIR/
		else
			/bin/cp -f $IPQ4019_BDF_DIR/FCC_ETSI/* $IPQ4019_BDF_DIR/
		fi
	fi

	if [ -d $QCA9984_BDF_DIR/$REGULATORY_DOMAIN ]; then
		/bin/cp -f $QCA9984_BDF_DIR/$REGULATORY_DOMAIN/* $QCA9984_BDF_DIR/
	else
		if [ "$wl_super_wifi" == "1" ] || [ "$wla_super_wifi" == "1" ]; then
			/bin/cp -f $QCA9984_BDF_DIR/SRRC/* $QCA9984_BDF_DIR/
		else
			/bin/cp -f $QCA9984_BDF_DIR/FCC_ETSI/* $QCA9984_BDF_DIR/
		fi
	fi

	if [ -d $QCA9888_BDF_DIR/$REGULATORY_DOMAIN ]; then
		/bin/cp -f $QCA9888_BDF_DIR/$REGULATORY_DOMAIN/* $QCA9888_BDF_DIR/
	else
		if [ "$wl_super_wifi" == "1" ] || [ "$wla_super_wifi" == "1" ]; then
			/bin/cp -f $QCA9888_BDF_DIR/SRRC/* $QCA9888_BDF_DIR/
		else
			/bin/cp -f $QCA9888_BDF_DIR/FCC_ETSI/* $QCA9888_BDF_DIR/
		fi
	fi
}

disable_qcawifi() {
	local device="$1"
	lock /var/run/wifilock
	_disable_qcawifi "$device"
	lock -u /var/run/wifilock
}

enable_qcawifi() {
	local device="$1"
	local count=0
	echo "$DRIVERS: enable radio $1" >/dev/console
	local num_radio_instamode=0

	# Does this "$device" contain only backhaul ifaces? 1 = yes, 0 = no
	local backhaul_only=1

	local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`

	config_get country "$device" country
	set_boarddata "$country"

	load_qcawifi

	find_qcawifi_phy "$device" || return 1

	if [ ! -f /lib/wifi/wifi_nss_override ]; then
		if [ -f /lib/wifi/wifi_nss_olcfg ] && [ $(cat /lib/wifi/wifi_nss_olcfg) != 0 ]; then
			touch /lib/wifi/wifi_nss_override
			echo 0 > /lib/wifi/wifi_nss_override
		fi
	fi

	if [ -f /lib/wifi/wifi_nss_override ]; then
		cd /sys/class/net
		for all_device in $(ls -d wifi* 2>&-); do
			config_get_bool disabled "$all_device" disabled 0
			[ $disabled = 0 ] || continue
			config_get vifs "$all_device" vifs

			for vif in $vifs; do
				config_get mode "$vif" mode
				if [ $mode = "sta" ]; then
					num_radio_instamode=$(($num_radio_instamode + 1))
					break
				fi
			done
			if [ $num_radio_instamode = "0" ]; then
				break
			fi
		done

		nss_override="$(cat /lib/wifi/wifi_nss_override)"
		if [ $num_radio_instamode = "3" ]; then
			config_get nss_wifi_olcfg qcawifi nss_wifi_olcfg
			if [ -n "$nss_wifi_olcfg" ] && [ $nss_wifi_olcfg != 0 ]; then
				echo " Invalid Configuration: 3 stations in offload not supported"
				return 1
			fi
			if [ $nss_override = "0" ]; then
				echo 1 > /lib/wifi/wifi_nss_override
				unload_qcawifi
				device=$1
				load_qcawifi
			fi
		else
			if [ $nss_override != "0" ]; then
				echo 0 > /lib/wifi/wifi_nss_override
				unload_qcawifi
				device=$1
				load_qcawifi
			fi
		fi
	fi

	lock /var/run/wifilock

	config_get phy "$device" phy

	config_get preCACEn "$device" preCACEn
	[ -n "$preCACEn" ] && iwpriv "$phy" preCACEn "$preCACEn"

	if [ -z "$country" ]; then
		if ! set_default_country $device; then
			lock -u /var/run/wifilock
			return 1
		fi
	else
		# If the country parameter is a number (either hex or decimal), we
		# assume it's a regulatory domain - i.e. we use iwpriv setCountryID.
		# Else we assume it's a country code - i.e. we use iwpriv setCountry.
		case "$country" in
			[0-9]*)
				iwpriv "$phy" setCountryID "$country"
			;;
			*)
				[ -n "$country" ] && iwpriv "$phy" setCountry "$country"
			;;
		esac
	fi
	config_get channel "$device" channel
	config_get vifs "$device" vifs
	config_get txpower "$device" txpower
	config_get tpscale "$device" tpscale
	[ -n "$tpscale" ] && iwpriv "$phy" tpscale "$tpscale"

	[ auto = "$channel" ] && channel=0

	config_get_bool antdiv "$device" diversity
	config_get antrx "$device" rxantenna
	config_get anttx "$device" txantenna
	config_get_bool softled "$device" softled
	config_get antenna "$device" antenna
	config_get distance "$device" distance

	[ -n "$antdiv" ] && echo "antdiv option not supported on this driver"
	[ -n "$antrx" ] && echo "antrx option not supported on this driver"
	[ -n "$anttx" ] && echo "anttx option not supported on this driver"
	[ -n "$softled" ] && echo "softled option not supported on this driver"
	[ -n "$antenna" ] && echo "antenna option not supported on this driver"
	[ -n "$distance" ] && echo "distance option not supported on this driver"

	# Advanced QCA wifi per-radio parameters configuration
	config_get txchainmask "$device" txchainmask
	[ -n "$txchainmask" ] && iwpriv "$phy" txchainmask "$txchainmask"

	config_get rxchainmask "$device" rxchainmask
	[ -n "$rxchainmask" ] && iwpriv "$phy" rxchainmask "$rxchainmask"

        config_get regdomain "$device" regdomain
        [ -n "$regdomain" ] && iwpriv "$phy" setRegdomain "$regdomain"

	config_get AMPDU "$device" AMPDU
	[ -n "$AMPDU" ] && iwpriv "$phy" AMPDU "$AMPDU"

	config_get ampdudensity "$device" ampdudensity
	[ -n "$ampdudensity" ] && iwpriv "$phy" ampdudensity "$ampdudensity"

	config_get_bool AMSDU "$device" AMSDU
	[ -n "$AMSDU" ] && iwpriv "$phy" AMSDU "$AMSDU"

	config_get AMPDULim "$device" AMPDULim
	[ -n "$AMPDULim" ] && iwpriv "$phy" AMPDULim "$AMPDULim"

	config_get AMPDUFrames "$device" AMPDUFrames
	[ -n "$AMPDUFrames" ] && iwpriv "$phy" AMPDUFrames "$AMPDUFrames"

	config_get AMPDURxBsize "$device" AMPDURxBsize
	[ -n "$AMPDURxBsize" ] && iwpriv "$phy" AMPDURxBsize "$AMPDURxBsize"

	config_get_bool bcnburst "$device" bcnburst 0
	[ "$bcnburst" -gt 0 ] && iwpriv "$phy" set_bcnburst "$bcnburst"

	config_get set_smart_antenna "$device" set_smart_antenna
	[ -n "$set_smart_antenna" ] && iwpriv "$phy" setSmartAntenna "$set_smart_antenna"

	config_get current_ant "$device" current_ant
	[ -n  "$current_ant" ] && iwpriv "$phy" current_ant "$current_ant"

	config_get default_ant "$device" default_ant
	[ -n "$default_ant" ] && iwpriv "$phy" default_ant "$default_ant"

	config_get ant_retrain "$device" ant_retrain
	[ -n "$ant_retrain" ] && iwpriv "$phy" ant_retrain "$ant_retrain"

	config_get retrain_interval "$device" retrain_interval
	[ -n "$retrain_interval" ] && iwpriv "$phy" retrain_interval "$retrain_interval"

	config_get retrain_drop "$device" retrain_drop
	[ -n "$retrain_drop" ] && iwpriv "$phy" retrain_drop "$retrain_drop"

	config_get ant_train "$device" ant_train
	[ -n "$ant_train" ] && iwpriv "$phy" ant_train "$ant_train"

	config_get ant_trainmode "$device" ant_trainmode
	[ -n "$ant_trainmode" ] && iwpriv "$phy" ant_trainmode "$ant_trainmode"

	config_get ant_traintype "$device" ant_traintype
	[ -n "$ant_traintype" ] && iwpriv "$phy" ant_traintype "$ant_traintype"

	config_get ant_pktlen "$device" ant_pktlen
	[ -n "$ant_pktlen" ] && iwpriv "$phy" ant_pktlen "$ant_pktlen"

	config_get ant_numpkts "$device" ant_numpkts
	[ -n "$ant_numpkts" ] && iwpriv "$phy" ant_numpkts "$ant_numpkts"

	config_get ant_numitr "$device" ant_numitr
	[ -n "$ant_numitr" ] && iwpriv "$phy" ant_numitr "$ant_numitr"

	config_get ant_train_thres "$device" ant_train_thres
	[ -n "$ant_train_thres" ] && iwpriv "$phy" train_threshold "$ant_train_thres"

	config_get ant_train_min_thres "$device" ant_train_min_thres
	[ -n "$ant_train_min_thres" ] && iwpriv "$phy" train_threshold "$ant_train_min_thres"

	config_get ant_traffic_timer "$device" ant_traffic_timer
	[ -n "$ant_traffic_timer" ] && iwpriv "$phy" traffic_timer "$ant_traffic_timer"

	config_get dcs_enable "$device" dcs_enable
	[ -n "$dcs_enable" ] && iwpriv "$phy" dcs_enable "$dcs_enable"

	config_get dcs_coch_int "$device" dcs_coch_int
	[ -n "$dcs_coch_int" ] && iwpriv "$phy" set_dcs_coch_int "$dcs_coch_int"

	config_get dcs_errth "$device" dcs_errth
	[ -n "$dcs_errth" ] && iwpriv "$phy" set_dcs_errth "$dcs_errth"

	config_get dcs_phyerrth "$device" dcs_phyerrth
	[ -n "$dcs_phyerrth" ] && iwpriv "$phy" set_dcs_phyerrth "$dcs_phyerrth"

	config_get dcs_usermaxc "$device" dcs_usermaxc
	[ -n "$dcs_usermaxc" ] && iwpriv "$phy" set_dcs_usermaxc "$dcs_usermaxc"

	config_get dcs_debug "$device" dcs_debug
	[ -n "$dcs_debug" ] && iwpriv "$phy" set_dcs_debug "$dcs_debug"

	config_get set_ch_144 "$device" set_ch_144
	[ -n "$set_ch_144" ] && iwpriv "$phy" setCH144 "$set_ch_144"

	config_get eppovrd_ch_144 "$device" eppovrd_ch_144
	[ -n "$eppovrd_ch_144" ] && iwpriv "$phy" setCH144EppOvrd "$eppovrd_ch_144"

	config_get_bool ani_enable "$device" ani_enable
	[ -n "$ani_enable" ] && iwpriv "$phy" ani_enable "$ani_enable"

	config_get_bool acs_bkscanen "$device" acs_bkscanen
	[ -n "$acs_bkscanen" ] && iwpriv "$phy" acs_bkscanen "$acs_bkscanen"

	config_get acs_scanintvl "$device" acs_scanintvl
	[ -n "$acs_scanintvl" ] && iwpriv "$phy" acs_scanintvl "$acs_scanintvl"

	config_get acs_rssivar "$device" acs_rssivar
	[ -n "$acs_rssivar" ] && iwpriv "$phy" acs_rssivar "$acs_rssivar"

	config_get acs_chloadvar "$device" acs_chloadvar
	[ -n "$acs_chloadvar" ] && iwpriv "$phy" acs_chloadvar "$acs_chloadvar"

	config_get acs_lmtobss "$device" acs_lmtobss
	[ -n "$acs_lmtobss" ] && iwpriv "$phy" acs_lmtobss "$acs_lmtobss"

	config_get acs_ctrlflags "$device" acs_ctrlflags
	[ -n "$acs_ctrlflags" ] && iwpriv "$phy" acs_ctrlflags "$acs_ctrlflags"

	config_get acs_dbgtrace "$device" acs_dbgtrace
	[ -n "$acs_dbgtrace" ] && iwpriv "$phy" acs_dbgtrace "$acs_dbgtrace"

	config_get acs_samech_th "$device" acs_samech_th
	[ -n "$acs_samech_th" ] && iwpriv "$phy" acs_samech_th "$acs_samech_th"

	config_get_bool dscp_ovride "$device" dscp_ovride
	[ -n "$dscp_ovride" ] && iwpriv "$phy" set_dscp_ovride "$dscp_ovride"

	config_get reset_dscp_map "$device" reset_dscp_map
	[ -n "$reset_dscp_map" ] && iwpriv "$phy" reset_dscp_map "$reset_dscp_map"

	config_get dscp_tid_map "$device" dscp_tid_map
	[ -n "$dscp_tid_map" ] && iwpriv "$phy" set_dscp_tid_map $dscp_tid_map

        #Default enable IGMP overide & TID=6
	iwpriv "$phy" sIgmpDscpOvrid 1
	iwpriv "$phy" sIgmpDscpTidMap 6

	config_get_bool igmp_dscp_ovride "$device" igmp_dscp_ovride
	[ -n "$igmp_dscp_ovride" ] && iwpriv "$phy" sIgmpDscpOvrid "$igmp_dscp_ovride"

	config_get igmp_dscp_tid_map "$device" igmp_dscp_tid_map
	[ -n "$igmp_dscp_tid_map" ] && iwpriv "$phy" sIgmpDscpTidMap "$igmp_dscp_tid_map"

	config_get_bool hmmc_dscp_ovride "$device" hmmc_dscp_ovride
	[ -n "$hmmc_dscp_ovride" ] && iwpriv "$phy" sHmmcDscpOvrid "$hmmc_dscp_ovride"

	config_get hmmc_dscp_tid_map "$device" hmmc_dscp_tid_map
	[ -n "$hmmc_dscp_tid_map" ] && iwpriv "$phy" sHmmcDscpTidMap "$hmmc_dscp_tid_map"

	config_get_bool blk_report_fld "$device" blk_report_fld
	[ -n "$blk_report_fld" ] && iwpriv "$phy" setBlkReportFld "$blk_report_fld"

	config_get_bool drop_sta_query "$device" drop_sta_query
	[ -n "$drop_sta_query" ] && iwpriv "$phy" setDropSTAQuery "$drop_sta_query"

	config_get_bool burst "$device" burst
	[ -n "$burst" ] && iwpriv "$phy" burst "$burst"

	config_get burst_dur "$device" burst_dur
	[ -n "$burst_dur" ] && iwpriv "$phy" burst_dur "$burst_dur"

	config_get TXPowLim2G "$device" TXPowLim2G
	[ -n "$TXPowLim2G" ] && iwpriv "$phy" TXPowLim2G "$TXPowLim2G"

	config_get TXPowLim5G "$device" TXPowLim5G
	[ -n "$TXPowLim5G" ] && iwpriv "$phy" TXPowLim5G "$TXPowLim5G"

	config_get_bool enable_ol_stats "$device" enable_ol_stats 1
	[ -n "$enable_ol_stats" ] && iwpriv "$phy" enable_ol_stats "$enable_ol_stats"

	config_get emiwar80p80 "$device" emiwar80p80
	[ -n "$emiwar80p80" ] && iwpriv "$phy" emiwar80p80 "$emiwar80p80"

	config_get_bool rst_tso_stats "$device" rst_tso_stats
	[ -n "$rst_tso_stats" ] && iwpriv "$phy" rst_tso_stats "$rst_tso_stats"

	config_get_bool rst_lro_stats "$device" rst_lro_stats
	[ -n "$rst_lro_stats" ] && iwpriv "$phy" rst_lro_stats "$rst_lro_stats"

	config_get_bool rst_sg_stats "$device" rst_sg_stats
	[ -n "$rst_sg_stats" ] && iwpriv "$phy" rst_sg_stats "$rst_sg_stats"

	config_get_bool set_fw_recovery "$device" set_fw_recovery
	[ -n "$set_fw_recovery" ] && iwpriv "$phy" set_fw_recovery "$set_fw_recovery"

	config_get_bool allowpromisc "$device" allowpromisc
	[ -n "$allowpromisc" ] && iwpriv "$phy" allowpromisc "$allowpromisc"

	config_get set_sa_param "$device" set_sa_param
	[ -n "$set_sa_param" ] && iwpriv "$phy" set_sa_param $set_sa_param

	config_get_bool aldstats "$device" aldstats
	[ -n "$aldstats" ] && iwpriv "$phy" aldstats "$aldstats"

	config_get macaddr "$device" macaddr
	[ -n "$macaddr" ] && iwpriv "$phy" setHwaddr "$macaddr"

	config_get promisc "$device" promisc
	[ -n "$promisc" ] && iwpriv "$phy" promisc $promisc

	config_get mode0 "$device" mode0
	[ -n "$mode0" ] && iwpriv "$phy" fc_buf_min 2501

	config_get mode1 "$device" mode1
	[ -n "$mode1" ] && iwpriv "$phy" fc_buf_min 0

	config_get nf_baseline "$device" nf_baseline
	[ -n "$nf_baseline" ] && iwpriv "$phy" nf_baseline $nf_baseline

	handle_aggr_burst() {
		local value="$1"
		[ -n "$value" ] && iwpriv "$phy" aggr_burst $value
	}

	config_list_foreach "$device" aggr_burst handle_aggr_burst

	config_get_bool block_interbss "$device" block_interbss
	[ -n "$block_interbss" ] && iwpriv "$phy" block_interbss "$block_interbss"

	config_get set_pmf "$device" set_pmf
	[ -n "$set_pmf" ] && iwpriv "$phy" set_pmf "${set_pmf}"

	config_get txbf_snd_int "$device" txbf_snd_int 100
	[ -n "$txbf_snd_int" ] && iwpriv "$phy" txbf_snd_int "$txbf_snd_int"

	config_get mcast_echo "$device" mcast_echo
	[ -n "$mcast_echo" ] && iwpriv "$phy" mcast_echo "${mcast_echo}"

	config_get obss_rssi_th "$device" obss_rssi_th 35
	[ -n "$obss_rssi_th" ] && iwpriv "$phy" obss_rssi_th "${obss_rssi_th}"

	config_get obss_rx_rssi_th "$device" obss_rx_rssi_th 35
	[ -n "$obss_rx_rssi_th" ] && iwpriv "$phy" obss_rxrssi_th "${obss_rx_rssi_th}"

        config_get acs_txpwr_opt "$device" acs_txpwr_opt
        [ -n "$acs_txpwr_opt" ] && iwpriv "$phy" acs_tcpwr_opt "${acs_txpwr_opt}"

	config_get obss_long_slot "$device" obss_long_slot
	[ -n "$obss_long_slot" ] && iwpriv "$phy" obss_long_slot "${obss_long_slot}"

	config_get staDFSEn "$device" staDFSEn
	[ -n "$staDFSEn" ] && iwpriv "$phy" staDFSEn "${staDFSEn}"

        config_get dbdc_enable "$device" dbdc_enable
        [ -n "$dbdc_enable" ] && iwpriv "$phy" dbdc_enable "${dbdc_enable}"

        config_get client_mcast "$device" client_mcast
        [ -n "$client_mcast" ] && iwpriv "$phy" client_mcast "${client_mcast}"

        config_get pas_scanen "$device" pas_scanen
        [ -n "$pas_scanen" ] && iwpriv "$phy" pas_scanen "${pas_scanen}"

        config_get delay_stavapup "$device" delay_stavapup
        [ -n "$delay_stavapup" ] && iwpriv "$phy" delay_stavapup "${delay_stavapup}"

        config_get cca_threshold "$device" cca_threshold
        [ -n "$cca_threshold" ] && iwpriv "$phy" cca_threshold "${cca_threshold}"

        config_get tid_override_queue_map "$device" tid_override_queue_map
        [ -n "$tid_override_queue_map" ] && iwpriv "$phy" queue_map "${tid_override_queue_map}"

        config_get channel_block_mode "$device" channel_block_mode
        [ -n "$channel_block_mode" ] && iwpriv "$phy" acs_bmode "${channel_block_mode}"

        config_get no_vlan "$device" no_vlan
        [ -n "$no_vlan" ] && iwpriv "$phy" no_vlan "${no_vlan}"

        config_get ul_hyst "$device" ul_hyst
        [ -n "$ul_hyst" ] && iwpriv "$phy" ul_hyst "${ul_hyst}"

        config_get discon_time qcawifi discon_time 10
        [ -n "$discon_time" ] && iwpriv "$phy" discon_time "${discon_time}"

        config_get reconfig_time qcawifi reconfig_time 60
        [ -n "$reconfig_time" ] && iwpriv "$phy" reconfig_time "${reconfig_time}"

        config_get alwaysprimary qcawifi alwaysprimary
        [ -n "$alwaysprimary" ] && iwpriv "$phy" alwaysprimary "${alwaysprimary}"

	if [ -f /lib/wifi/wifi_nss_olcfg ]; then
		nss_wifi_olcfg="$(cat /lib/wifi/wifi_nss_olcfg)"
		if [ $nss_wifi_olcfg != 0 ]; then
			config_get hwmode "$device" hwmode auto
			case "$hwmode" in
				*ng)
					iwpriv "$phy" fc_buf0_max 5120
					iwpriv "$phy" fc_buf1_max 8192
					iwpriv "$phy" fc_buf2_max 12288
					iwpriv "$phy" fc_buf3_max 16384
					;;
				*ac)
					iwpriv "$phy" fc_buf0_max 8192
					iwpriv "$phy" fc_buf1_max 16384
					iwpriv "$phy" fc_buf2_max 24576
					iwpriv "$phy" fc_buf3_max 32768
					;;
				*)
					iwpriv "$phy" fc_buf0_max 5120
					iwpriv "$phy" fc_buf1_max 8192
					iwpriv "$phy" fc_buf2_max 12288
					iwpriv "$phy" fc_buf3_max 16384
					;;
			esac
		fi
	fi

	config_tx_fc_buf "$phy"

	# Enable RPS and disable qrfs, if rxchainmask is 15 for some platforms
	disable_qrfs_wifi=0
	enable_rps_wifi=0
	if [ $(iwpriv "$phy" get_rxchainmask | awk -F ':' '{ print $2 }') == 15 ]; then
		disable_qrfs_wifi=1
		enable_rps_wifi=1
	fi

	for vif in $vifs; do
		local start_hostapd=
		config_get mode "$vif" mode
		config_get enc "$vif" encryption "none"

		case "$enc" in
			mixed*|psk*|wpa*|8021x)
				start_hostapd=1
				config_get key "$vif" key
			;;
		esac

		case "$mode" in
			ap|wrap)
				if [ -n "$start_hostapd" ] && [ $count -lt 2 ] && eval "type hostapd_config_multi_cred" 2>/dev/null >/dev/null; then
					hostapd_config_multi_cred "$vif"
					count=$(($count + 1))
				fi
	  			;;
                esac
	done

	for vif in $vifs; do
		local start_hostapd= vif_txpower= nosbeacon= wlanaddr=""
		local wlanmode
		config_get ifname "$vif" ifname
		config_get enc "$vif" encryption "none"
		config_get eap_type "$vif" eap_type
		config_get mode "$vif" mode
		wlanmode=$mode

		if [ -f /sys/class/net/$device/ciphercaps ]
		then
			case "$enc" in
				*gcmp*)
					echo "enc:GCMP" >&2
					cat /sys/class/net/$device/ciphercaps | grep -i "gcmp"
					if [ $? -ne 0 ]
					then
						echo "enc:GCMP is Not Supported on Radio" >&2
						continue
					fi
					;;
				*ccmp-256*)
					echo "enc:CCMP-256" >&2
					cat /sys/class/net/$device/ciphercaps | grep -i "ccmp-256"
					if [ $? -ne 0 ]
					then
						echo "enc:CCMP-256 is Not Supported on Radio" >&2
						continue
					fi
					;;
			esac
		fi

		[ "$wlanmode" = "ap_monitor" ] && wlanmode="specialvap"
		[ "$wlanmode" = "ap_smart_monitor" ] && wlanmode="smart_monitor"
		[ "$wlanmode" = "ap_lp_iot" ] && wlanmode="lp_iot_mode"

		case "$mode" in
			sta)
				config_get_bool nosbeacon "$device" nosbeacon
				config_get qwrap_enable "$device" qwrap_enable 0
				[ $qwrap_enable -gt 0 ] && wlanaddr="00:00:00:00:00:00"
				;;
			adhoc)
				config_get_bool nosbeacon "$vif" sw_merge 1
				;;
		esac

		[ "$nosbeacon" = 1 ] || nosbeacon=""
		[ -n "${DEBUG}" ] && echo wlanconfig "$ifname" create wlandev "$phy" wlanmode "$wlanmode" ${wlanaddr:+wlanaddr "$wlanaddr"} ${nosbeacon:+nosbeacon}
		ifname=$(/usr/sbin/wlanconfig "$ifname" create wlandev "$phy" wlanmode "$wlanmode" ${wlanaddr:+wlanaddr "$wlanaddr"} ${nosbeacon:+nosbeacon})
		[ $? -ne 0 ] && {
			echo "enable_qcawifi($device): Failed to set up $mode vif $ifname" >&2
			continue
		}
		config_set "$vif" ifname "$ifname"

		config_get hwmode "$device" hwmode auto
		config_get htmode "$device" htmode auto

		pureg=0
		case "$hwmode:$htmode" in
		# The parsing stops at the first match so we need to make sure
		# these are in the right orders (most generic at the end)
			*ng:HT20) hwmode=11NGHT20;;
			*ng:HT40-) hwmode=11NGHT40MINUS;;
			*ng:HT40+) hwmode=11NGHT40PLUS;;
			*ng:HT40) hwmode=11NGHT40;;
			*ng:*) hwmode=11NGHT20;;
			*na:HT20) hwmode=11NAHT20;;
			*na:HT40-) hwmode=11NAHT40MINUS;;
			*na:HT40+) hwmode=11NAHT40PLUS;;
			*na:HT40) hwmode=11NAHT40;;
			*na:*) hwmode=11NAHT40;;
			*ac:HT20) hwmode=11ACVHT20;;
			*ac:HT40+) hwmode=11ACVHT40PLUS;;
			*ac:HT40-) hwmode=11ACVHT40MINUS;;
			*ac:HT40) hwmode=11ACVHT40;;
			*ac:HT80) hwmode=11ACVHT80;;
			*ac:HT160) hwmode=11ACVHT160;;
			*ac:HT80_80) hwmode=11ACVHT80_80;;
                        *ac:*) hwmode=11ACVHT80
			       if [ -f /sys/class/net/$device/5g_maxchwidth ]; then
			           maxchwidth="$(cat /sys/class/net/$device/5g_maxchwidth)"
				   [ -n "$maxchwidth" ] && hwmode=11ACVHT$maxchwidth
			       fi
                               if [ "$mode" == "sta" ]; then
                                   cat /sys/class/net/$device/hwmodes | grep  "11AC_VHT80_80"
				   if [ $? -eq 0 ]; then
			               hwmode=11ACVHT80_80
				   fi
			       fi;;
			*b:*) hwmode=11B;;
			*bg:*) hwmode=11G;;
			*g:*) hwmode=11G; pureg=1;;
			*a:*) hwmode=11A;;
			*) hwmode=AUTO;;
		esac
		iwpriv "$ifname" mode "$hwmode"
		[ $pureg -gt 0 ] && iwpriv "$ifname" pureg "$pureg"

		config_get cfreq2 "$vif" cfreq2
		[ -n "$cfreq2" -a "$htmode" = "HT80_80" ] && iwpriv "$ifname" cfreq2 "$cfreq2"

		config_get puren "$vif" puren
		[ -n "$puren" ] && iwpriv "$ifname" puren "$puren"

		band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
		if [ -f /tmp/radardetect.pid ] && [ "$band_type" == "a" ]; then
			/usr/sbin/radardetect_cli -b "$phy"
		fi

		iwconfig "$ifname" channel "$channel" >/dev/null 2>/dev/null

		config_get_bool hidden "$vif" hidden 0
		iwpriv "$ifname" hide_ssid "$hidden"

                config_get_bool dynamicbeacon "$vif" dynamicbeacon 0
                [ $hidden = 1 ] && iwpriv "$ifname" dynamicbeacon "$dynamicbeacon"

                config_get db_rssi_thr "$vif" db_rssi_thr
                [ -n "$db_rssi_thr" ] && iwpriv "$ifname" db_rssi_thr "$db_rssi_thr"

                config_get db_timeout "$vif" db_timeout
                [ -n "$db_timeout" ] && iwpriv "$ifname" db_timeout "$db_timeout"

		config_get_bool shortgi "$vif" shortgi 1
		[ -n "$shortgi" ] && iwpriv "$ifname" shortgi "${shortgi}"

		config_get_bool disablecoext "$vif" disablecoext
		[ -n "$disablecoext" ] && iwpriv "$ifname" disablecoext "${disablecoext}"
		[ "$disablecoext" -eq "0" ] && iwpriv $ifname extbusythres 30
		[ "$disablecoext" -eq "1" ] && iwpriv $ifname extbusythres 100

		config_get chwidth "$vif" chwidth
		[ -n "$chwidth" ] && iwpriv "$ifname" chwidth "${chwidth}"

		config_get wds "$vif" wds
		case "$wds" in
			1|on|enabled) wds=1;;
			*) wds=0;;
		esac
		iwpriv "$ifname" wds "$wds"

		config_get ODM "$device" ODM
		config_get bridge "$vif" bridge
		hyd_enabled=$(uci -q get hyd.config.Enable)
		[ "$ODM" = "dni" -a "x$hyd_enabled" = "x0" ] && [ -n "$wds" ] && brctl stp "$bridge" on

		config_get vlan_pri "$vif" vlan_pri
		if [ "$vlan_pri" = "" ]; then
			iwpriv "$ifname" dni_vlan_pri -1
		else
			iwpriv "$ifname" dni_vlan_pri "$vlan_pri"
		fi

		config_get  backhaul "$vif" backhaul 0
                iwpriv "$ifname" backhaul "$backhaul" >/dev/null 2>&1

		config_get TxBFCTL "$vif" TxBFCTL
		[ -n "$TxBFCTL" ] && iwpriv "$ifname" TxBFCTL "$TxBFCTL"

		config_get bintval "$vif" bintval
		[ -n "$bintval" ] && iwpriv "$ifname" bintval "$bintval"

		config_get_bool countryie "$vif" countryie
		#countryie=1 means turn off country code function
		countryie=1
		[ -n "$countryie" ] && iwpriv "$ifname" countryie "$countryie"

		case "$enc" in
			none)
				# We start hostapd in open mode also
				start_hostapd=1
			;;
			wep*)
				case "$enc" in
					*mixed*)  iwpriv "$ifname" authmode 4;;
					*shared*) iwpriv "$ifname" authmode 2;;
					*)        iwpriv "$ifname" authmode 1;;
				esac
				for idx in 1 2 3 4; do
					config_get key "$vif" "key${idx}"
					config_get key_format "$vif" "key${idx}_format"
					if [ "$key_format" = "ASCII" ]; then
						iwconfig "$ifname" enc s:"${key:-off}" "[$idx]"
					else
						iwconfig "$ifname" enc "[$idx]" "${key:-off}"
					fi
				done
				config_get key "$vif" key
				key="${key:-1}"
				case "$key" in
					[1234]) iwconfig "$ifname" enc "[$key]";;
					*) iwconfig "$ifname" enc "$key";;
				esac
			;;
			mixed*|psk*|wpa*|8021x)
				start_hostapd=1
				config_get key "$vif" key
			;;
			wapi*)
				start_wapid=1
				config_get key "$vif" key
			;;
		esac

		case "$mode" in
			sta|adhoc)
				config_get addr "$vif" bssid
				[ -z "$addr" ] || {
					iwconfig "$ifname" ap "$addr"
				}
			;;
		esac

		config_get_bool uapsd "$vif" uapsd 1
		iwpriv "$ifname" uapsd "$uapsd"

		config_get mcast_rate "$vif" mcast_rate
		[ -n "$mcast_rate" ] && iwpriv "$ifname" mcast_rate "${mcast_rate%%.*}"

		config_get powersave "$vif" powersave
		[ -n "$powersave" ] && iwpriv "$ifname" powersave "${powersave}"

		config_get_bool ant_ps_on "$vif" ant_ps_on
		[ -n "$ant_ps_on" ] && iwpriv "$ifname" ant_ps_on "${ant_ps_on}"

		config_get ps_timeout "$vif" ps_timeout
		[ -n "$ps_timeout" ] && iwpriv "$ifname" ps_timeout "${ps_timeout}"

		config_get mcastenhance "$vif" mcastenhance
		[ -n "$mcastenhance" ] && iwpriv "$ifname" mcastenhance "${mcastenhance}"

		config_get disable11nmcs "$vif" disable11nmcs
		[ -n "$disable11nmcs" ] && iwpriv "$ifname" disable11nmcs "${disable11nmcs}"

		config_get conf_11acmcs "$vif" conf_11acmcs
		[ -n "$conf_11acmcs" ] && iwpriv "$ifname" conf_11acmcs "${conf_11acmcs}"

		config_get metimer "$vif" metimer
		[ -n "$metimer" ] && iwpriv "$ifname" metimer "${metimer}"

		config_get metimeout "$vif" metimeout
		[ -n "$metimeout" ] && iwpriv "$ifname" metimeout "${metimeout}"

		config_get_bool medropmcast "$vif" medropmcast
		[ -n "$medropmcast" ] && iwpriv "$ifname" medropmcast "${medropmcast}"

		config_get_bool dropmdns "$vif" dropmdns 1
		[ -n "$dropmdns" ] && iwpriv "$ifname" dropmdns "${dropmdns}"

		config_get me_adddeny "$vif" me_adddeny
		[ -n "$me_adddeny" ] && iwpriv "$ifname" me_adddeny ${me_adddeny}

		#support independent repeater mode
		config_get vap_ind "$vif" vap_ind
		[ -n "$vap_ind" ] && iwpriv "$ifname" vap_ind "${vap_ind}"

		#support extender ap & STA
		config_get extap "$vif" extap
		[ -n "$extap" ] && iwpriv "$ifname" extap "${extap}"

		config_get scanband "$vif" scanband
		[ -n "$scanband" ] && iwpriv "$ifname" scanband "${scanband}"

		config_get periodicScan "$vif" periodicScan
		[ -n "$periodicScan" ] && iwpriv "$ifname" periodicScan "${periodicScan}"

                config_get cb "$vif" cb
                if [ "$cb" = "qca" ]; then
                    iwpriv "$ifname" extap 1
                    iwpriv "$ifname" scanband 1
                    iwpriv "$ifname" periodicScan 180000
                elif [ "$cb" = "dni" ]; then
                    iwpriv "$ifname" dni_cb 1
                    iwpriv "$ifname" periodicScan 180000
                fi

		config_get_bool short_preamble "$vif" short_preamble
		[ -n "$short_preamble" ] && iwpriv "$ifname" shpreamble "${short_preamble}"

		config_get frag "$vif" frag
		[ -n "$frag" ] && iwconfig "$ifname" frag "${frag%%.*}"

		config_get rts "$vif" rts
		[ -n "$rts" ] && iwconfig "$ifname" rts "${rts%%.*}"

		config_get cwmin "$vif" cwmin
		[ -n "$cwmin" ] && iwpriv "$ifname" cwmin ${cwmin}

		config_get cwmax "$vif" cwmax
		[ -n "$cwmax" ] && iwpriv "$ifname" cwmax ${cwmax}

		config_get aifs "$vif" aifs
		[ -n "$aifs" ] && iwpriv "$ifname" aifs ${aifs}

		config_get txoplimit "$vif" txoplimit
		[ -n "$txoplimit" ] && iwpriv "$ifname" txoplimit ${txoplimit}

		config_get noackpolicy "$vif" noackpolicy
		[ -n "$noackpolicy" ] && iwpriv "$ifname" noackpolicy ${noackpolicy}

		config_get_bool wmm "$vif" wmm
		[ -n "$wmm" ] && iwpriv "$ifname" wmm "$wmm"

		band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
		if [ "$band_type" = "a" ]; then
			config_get_bool no_wradar "$vif" no_wradar 1
			[ -n "$no_wradar" ] && iwpriv "$ifname" no_wradar "$no_wradar"
		fi

		config_get_bool doth "$vif" doth
		[ -n "$doth" ] && iwpriv "$ifname" doth "$doth"

		config_get doth_chanswitch "$vif" doth_chanswitch
		[ -n "$doth_chanswitch" ] && iwpriv "$ifname" doth_chanswitch ${doth_chanswitch}

		config_get quiet "$vif" quiet
		[ -n "$quiet" ] && iwpriv "$ifname" quiet "$quiet"

		config_get mfptest "$vif" mfptest
		[ -n "$mfptest" ] && iwpriv "$ifname" mfptest "$mfptest"

		config_get dtim_period "$vif" dtim_period
		[ -n "$dtim_period" ] && iwpriv "$ifname" dtim_period "$dtim_period"

		config_get backhaul "$vif" backhaul
		[ -n "$backhaul" ] && iwpriv "$ifname" backhaul "$backhaul"

		config_get noedgech "$vif" noedgech
		[ -n "$noedgech" ] && iwpriv "$ifname" noedgech "$noedgech"

		config_get ps_on_time "$vif" ps_on_time
		[ -n "$ps_on_time" ] && iwpriv "$ifname" ps_on_time "$ps_on_time"

		config_get inact "$vif" inact
		[ -n "$inact" ] && iwpriv "$ifname" inact "$inact"

		config_get wnm "$vif" wnm
		[ -n "$wnm" ] && iwpriv "$ifname" wnm "$wnm"

		config_get mbo "$vif" mbo
		[ -n "$mbo" ] && iwpriv "$ifname" mbo "$mbo"

		config_get oce "$vif" oce
		[ -n "$oce" ] && iwpriv "$ifname" oce "$oce"

		config_get ampdu "$vif" ampdu
		[ -n "$ampdu" ] && iwpriv "$ifname" ampdu "$ampdu"

		config_get amsdu "$vif" amsdu
		[ -n "$amsdu" ] && iwpriv "$ifname" amsdu "$amsdu"

		config_get maxampdu "$vif" maxampdu
		[ -n "$maxampdu" ] && iwpriv "$ifname" maxampdu "$maxampdu"

		config_get vhtmaxampdu "$vif" vhtmaxampdu
		[ -n "$vhtmaxampdu" ] && iwpriv "$ifname" vhtmaxampdu "$vhtmaxampdu"

		config_get setaddbaoper "$vif" setaddbaoper
		[ -n "$setaddbaoper" ] && iwpriv "$ifname" setaddbaoper "$setaddbaoper"

		config_get addbaresp "$vif" addbaresp
		[ -n "$addbaresp" ] && iwpriv "$ifname" $addbaresp

		config_get addba "$vif" addba
		[ -n "$addba" ] && iwpriv "$ifname" addba $addba

		config_get delba "$vif" delba
		[ -n "$delba" ] && iwpriv "$ifname" delba $delba

		config_get_bool stafwd "$vif" stafwd 0
		[ -n "$stafwd" ] && iwpriv "$ifname" stafwd "$stafwd"

		config_get maclist "$vif" maclist
		[ -n "$maclist" ] && {
			# flush MAC list
			iwpriv "$ifname" maccmd 3
			for mac in $maclist; do
				iwpriv "$ifname" addmac "$mac"
			done
		}

		config_get macfilter "$vif" macfilter
		case "$macfilter" in
			allow)
				iwpriv "$ifname" maccmd 1
			;;
			deny)
				iwpriv "$ifname" maccmd 2
			;;
			*)
				# default deny policy if mac list exists
				[ -n "$maclist" ] && iwpriv "$ifname" maccmd 2
			;;
		esac

		config_get nss "$vif" nss
		[ -n "$nss" ] && iwpriv "$ifname" nss "$nss"

		config_get vht_mcsmap "$vif" vht_mcsmap
		[ -n "$vht_mcsmap" ] && iwpriv "$ifname" vht_mcsmap "$vht_mcsmap"

		config_get chwidth "$vif" chwidth
		[ -n "$chwidth" ] && iwpriv "$ifname" chwidth "$chwidth"

		config_get chbwmode "$vif" chbwmode
		[ -n "$chbwmode" ] && iwpriv "$ifname" chbwmode "$chbwmode"

		config_get ldpc "$vif" ldpc
		[ -n "$ldpc" ] && iwpriv "$ifname" ldpc "$ldpc"

		config_get rx_stbc "$vif" rx_stbc
		[ -n "$rx_stbc" ] && iwpriv "$ifname" rx_stbc "$rx_stbc"

		config_get tx_stbc "$vif" tx_stbc
		[ -n "$tx_stbc" ] && iwpriv "$ifname" tx_stbc "$tx_stbc"

		config_get cca_thresh "$vif" cca_thresh
		[ -n "$cca_thresh" ] && iwpriv "$ifname" cca_thresh "$cca_thresh"

		config_get set11NRetries "$vif" set11NRetries
		[ -n "$set11NRetries" ] && iwpriv "$ifname" set11NRetries "$set11NRetries"

		config_get chanbw "$vif" chanbw
		[ -n "$chanbw" ] && iwpriv "$ifname" chanbw "$chanbw"

		config_get maxsta "$vif" maxsta
		[ -n "$maxsta" ] && iwpriv "$ifname" maxsta "$maxsta"

		config_get sko_max_xretries "$vif" sko_max_xretries
		[ -n "$sko_max_xretries" ] && iwpriv "$ifname" sko "$sko_max_xretries"

		config_get extprotmode "$vif" extprotmode
		[ -n "$extprotmode" ] && iwpriv "$ifname" extprotmode "$extprotmode"

		config_get extprotspac "$vif" extprotspac
		[ -n "$extprotspac" ] && iwpriv "$ifname" extprotspac "$extprotspac"

		config_get_bool cwmenable "$vif" cwmenable
		[ -n "$cwmenable" ] && iwpriv "$ifname" cwmenable "$cwmenable"

		config_get_bool protmode "$vif" protmode
		[ -n "$protmode" ] && iwpriv "$ifname" protmode "$protmode"

		config_get enablertscts "$vif" enablertscts
		[ -n "$enablertscts" ] && iwpriv "$ifname" enablertscts "$enablertscts"

		config_get txcorrection "$vif" txcorrection
		[ -n "$txcorrection" ] && iwpriv "$ifname" txcorrection "$txcorrection"

		config_get rxcorrection "$vif" rxcorrection
		[ -n "$rxcorrection" ] && iwpriv "$ifname" rxcorrection "$rxcorrection"

                config_get vsp_enable "$vif" vsp_enable
                [ -n "$vsp_enable" ] && iwpriv "$ifname" vsp_enable "$vsp_enable"

		config_get ssid "$vif" ssid
                [ -n "$ssid" ] && {
                        iwconfig "$ifname" essid on
                        iwconfig "$ifname" essid ${ssid:+-- }"$ssid"
                }

		config_get txqueuelen "$vif" txqueuelen
		[ -n "$txqueuelen" ] && ifconfig "$ifname" txqueuelen "$txqueuelen"

                net_cfg="$(find_net_config "$vif")"

                config_get mtu $net_cfg mtu

                [ -n "$mtu" ] && {
                        config_set "$vif" mtu $mtu
                        ifconfig "$ifname" mtu $mtu
		}

		config_get tdls "$vif" tdls
		[ -n "$tdls" ] && iwpriv "$ifname" tdls "$tdls"

		config_get set_tdls_rmac "$vif" set_tdls_rmac
		[ -n "$set_tdls_rmac" ] && iwpriv "$ifname" set_tdls_rmac "$set_tdls_rmac"

		config_get tdls_qosnull "$vif" tdls_qosnull
		[ -n "$tdls_qosnull" ] && iwpriv "$ifname" tdls_qosnull "$tdls_qosnull"

		config_get tdls_uapsd "$vif" tdls_uapsd
		[ -n "$tdls_uapsd" ] && iwpriv "$ifname" tdls_uapsd "$tdls_uapsd"

		config_get tdls_set_rcpi "$vif" tdls_set_rcpi
		[ -n "$tdls_set_rcpi" ] && iwpriv "$ifname" set_rcpi "$tdls_set_rcpi"

		config_get tdls_set_rcpi_hi "$vif" tdls_set_rcpi_hi
		[ -n "$tdls_set_rcpi_hi" ] && iwpriv "$ifname" set_rcpihi "$tdls_set_rcpi_hi"

		config_get tdls_set_rcpi_lo "$vif" tdls_set_rcpi_lo
		[ -n "$tdls_set_rcpi_lo" ] && iwpriv "$ifname" set_rcpilo "$tdls_set_rcpi_lo"

		config_get tdls_set_rcpi_margin "$vif" tdls_set_rcpi_margin
		[ -n "$tdls_set_rcpi_margin" ] && iwpriv "$ifname" set_rcpimargin "$tdls_set_rcpi_margin"

		config_get tdls_dtoken "$vif" tdls_dtoken
		[ -n "$tdls_dtoken" ] && iwpriv "$ifname" tdls_dtoken "$tdls_dtoken"

		config_get do_tdls_dc_req "$vif" do_tdls_dc_req
		[ -n "$do_tdls_dc_req" ] && iwpriv "$ifname" do_tdls_dc_req "$do_tdls_dc_req"

		config_get tdls_auto "$vif" tdls_auto
		[ -n "$tdls_auto" ] && iwpriv "$ifname" tdls_auto "$tdls_auto"

		config_get tdls_off_timeout "$vif" tdls_off_timeout
		[ -n "$tdls_off_timeout" ] && iwpriv "$ifname" off_timeout "$tdls_off_timeout"

		config_get tdls_tdb_timeout "$vif" tdls_tdb_timeout
		[ -n "$tdls_tdb_timeout" ] && iwpriv "$ifname" tdb_timeout "$tdls_tdb_timeout"

		config_get tdls_weak_timeout "$vif" tdls_weak_timeout
		[ -n "$tdls_weak_timeout" ] && iwpriv "$ifname" weak_timeout "$tdls_weak_timeout"

		config_get tdls_margin "$vif" tdls_margin
		[ -n "$tdls_margin" ] && iwpriv "$ifname" tdls_margin "$tdls_margin"

		config_get tdls_rssi_ub "$vif" tdls_rssi_ub
		[ -n "$tdls_rssi_ub" ] && iwpriv "$ifname" tdls_rssi_ub "$tdls_rssi_ub"

		config_get tdls_rssi_lb "$vif" tdls_rssi_lb
		[ -n "$tdls_rssi_lb" ] && iwpriv "$ifname" tdls_rssi_lb "$tdls_rssi_lb"

		config_get tdls_path_sel "$vif" tdls_path_sel
		[ -n "$tdls_path_sel" ] && iwpriv "$ifname" tdls_pathSel "$tdls_path_sel"

		config_get tdls_rssi_offset "$vif" tdls_rssi_offset
		[ -n "$tdls_rssi_offset" ] && iwpriv "$ifname" tdls_rssi_o "$tdls_rssi_offset"

		config_get tdls_path_sel_period "$vif" tdls_path_sel_period
		[ -n "$tdls_path_sel_period" ] && iwpriv "$ifname" tdls_pathSel_p "$tdls_path_sel_period"

		config_get tdlsmacaddr1 "$vif" tdlsmacaddr1
		[ -n "$tdlsmacaddr1" ] && iwpriv "$ifname" tdlsmacaddr1 "$tdlsmacaddr1"

		config_get tdlsmacaddr2 "$vif" tdlsmacaddr2
		[ -n "$tdlsmacaddr2" ] && iwpriv "$ifname" tdlsmacaddr2 "$tdlsmacaddr2"

		config_get tdlsaction "$vif" tdlsaction
		[ -n "$tdlsaction" ] && iwpriv "$ifname" tdlsaction "$tdlsaction"

		config_get tdlsoffchan "$vif" tdlsoffchan
		[ -n "$tdlsoffchan" ] && iwpriv "$ifname" tdlsoffchan "$tdlsoffchan"

		config_get tdlsswitchtime "$vif" tdlsswitchtime
		[ -n "$tdlsswitchtime" ] && iwpriv "$ifname" tdlsswitchtime "$tdlsswitchtime"

		config_get tdlstimeout "$vif" tdlstimeout
		[ -n "$tdlstimeout" ] && iwpriv "$ifname" tdlstimeout "$tdlstimeout"

		config_get tdlsecchnoffst "$vif" tdlsecchnoffst
		[ -n "$tdlsecchnoffst" ] && iwpriv "$ifname" tdlsecchnoffst "$tdlsecchnoffst"

		config_get tdlsoffchnmode "$vif" tdlsoffchnmode
		[ -n "$tdlsoffchnmode" ] && iwpriv "$ifname" tdlsoffchnmode "$tdlsoffchnmode"

		config_get_bool blockdfschan "$vif" blockdfschan
		[ -n "$blockdfschan" ] && iwpriv "$ifname" blockdfschan "$blockdfschan"

		config_get dbgLVL "$vif" dbgLVL
		[ -n "$dbgLVL" ] && iwpriv "$ifname" dbgLVL "$dbgLVL"

		config_get acsmindwell "$vif" acsmindwell
		[ -n "$acsmindwell" ] && iwpriv "$ifname" acsmindwell "$acsmindwell"

		config_get acsmaxdwell "$vif" acsmaxdwell
		[ -n "$acsmaxdwell" ] && iwpriv "$ifname" acsmaxdwell "$acsmaxdwell"

		config_get acsreport "$vif" acsreport
		[ -n "$acsreport" ] && iwpriv "$ifname" acsreport "$acsreport"

		config_get ch_hop_en "$vif" ch_hop_en
		[ -n "$ch_hop_en" ] && iwpriv "$ifname" ch_hop_en "$ch_hop_en"

		config_get ch_long_dur "$vif" ch_long_dur
		[ -n "$ch_long_dur" ] && iwpriv "$ifname" ch_long_dur "$ch_long_dur"

		config_get ch_nhop_dur "$vif" ch_nhop_dur
		[ -n "$ch_nhop_dur" ] && iwpriv "$ifname" ch_nhop_dur "$ch_nhop_dur"

		config_get ch_cntwn_dur "$vif" ch_cntwn_dur
		[ -n "$ch_cntwn_dur" ] && iwpriv "$ifname" ch_cntwn_dur "$ch_cntwn_dur"

		config_get ch_noise_th "$vif" ch_noise_th
		[ -n "$ch_noise_th" ] && iwpriv "$ifname" ch_noise_th "$ch_noise_th"

		config_get ch_cnt_th "$vif" ch_cnt_th
		[ -n "$ch_cnt_th" ] && iwpriv "$ifname" ch_cnt_th "$ch_cnt_th"

		config_get_bool scanchevent "$vif" scanchevent
		[ -n "$scanchevent" ] && iwpriv "$ifname" scanchevent "$scanchevent"

		config_get_bool send_add_ies "$vif" send_add_ies
		[ -n "$send_add_ies" ] && iwpriv "$ifname" send_add_ies "$send_add_ies"

		config_get_bool ext_ifu_acs "$vif" ext_ifu_acs
		[ -n "$ext_ifu_acs" ] && iwpriv "$ifname" ext_ifu_acs "$ext_ifu_acs"

		config_get_bool enable_rtt "$vif" enable_rtt
		[ -n "$enable_rtt" ] && iwpriv "$ifname" enable_rtt "$enable_rtt"

		config_get_bool enable_lci "$vif" enable_lci
		[ -n "$enable_lci" ] && iwpriv "$ifname" enable_lci "$enable_lci"

		config_get_bool enable_lcr "$vif" enable_lcr
		[ -n "$enable_lcr" ] && iwpriv "$ifname" enable_lcr "$enable_lcr"

		config_get_bool rrm "$vif" rrm
		[ -n "$rrm" ] && iwpriv "$ifname" rrm "$rrm"

		config_get_bool rrmslwin "$vif" rrmslwin
		[ -n "$rrmslwin" ] && iwpriv "$ifname" rrmslwin "$rrmslwin"

		config_get_bool rrmstats "$vif" rrmsstats
		[ -n "$rrmstats" ] && iwpriv "$ifname" rrmstats "$rrmstats"

		config_get rrmdbg "$vif" rrmdbg
		[ -n "$rrmdbg" ] && iwpriv "$ifname" rrmdbg "$rrmdbg"

		config_get acparams "$vif" acparams
		[ -n "$acparams" ] && iwpriv "$ifname" acparams $acparams

		config_get setwmmparams "$vif" setwmmparams
		[ -n "$setwmmparams" ] && iwpriv "$ifname" setwmmparams $setwmmparams

		config_get_bool qbssload "$vif" qbssload
		[ -n "$qbssload" ] && iwpriv "$ifname" qbssload "$qbssload"

		config_get_bool proxyarp "$vif" proxyarp
		[ -n "$proxyarp" ] && iwpriv "$ifname" proxyarp "$proxyarp"

		config_get_bool dgaf_disable "$vif" dgaf_disable
		[ -n "$dgaf_disable" ] && iwpriv "$ifname" dgaf_disable "$dgaf_disable"

		config_get setibssdfsparam "$vif" setibssdfsparam
		[ -n "$setibssdfsparam" ] && iwpriv "$ifname" setibssdfsparam "$setibssdfsparam"

		config_get startibssrssimon "$vif" startibssrssimon
		[ -n "$startibssrssimon" ] && iwpriv "$ifname" startibssrssimon "$startibssrssimon"

		config_get setibssrssihyst "$vif" setibssrssihyst
		[ -n "$setibssrssihyst" ] && iwpriv "$ifname" setibssrssihyst "$setibssrssihyst"

		config_get noIBSSCreate "$vif" noIBSSCreate
		[ -n "$noIBSSCreate" ] && iwpriv "$ifname" noIBSSCreate "$noIBSSCreate"

		config_get setibssrssiclass "$vif" setibssrssiclass
		[ -n "$setibssrssiclass" ] && iwpriv "$ifname" setibssrssiclass $setibssrssiclass

		config_get offchan_tx_test "$vif" offchan_tx_test
		[ -n "$offchan_tx_test" ] && iwpriv "$ifname" offchan_tx_test $offchan_tx_test

		handle_vow_dbg_cfg() {
			local value="$1"
			[ -n "$value" ] && iwpriv "$ifname" vow_dbg_cfg $value
		}

		config_list_foreach "$vif" vow_dbg_cfg handle_vow_dbg_cfg

		config_get_bool vow_dbg "$vif" vow_dbg
		[ -n "$vow_dbg" ] && iwpriv "$ifname" vow_dbg "$vow_dbg"

		handle_set_max_rate() {
			local value="$1"
			[ -n "$value" ] && wlanconfig "$ifname" set_max_rate $value
		}
		config_list_foreach "$vif" set_max_rate handle_set_max_rate

		config_get_bool arlo "$vif" arlo
		if [ "x$arlo" = "x1" ]; then
			iwpriv "$ifname" dni_arlo 1
			# disable qca vendor ie
			iwpriv "$ifname" vie_ena 0
		else
			iwpriv "$ifname" dni_arlo 0
		fi

		# update vendorie for backhaul interface
		[ "x$backhaul" = "x1" ] && {
			[ -n "$vie_oui" -a -n "$vie_flag" ] && wlanconfig $ifname vendorie update len 11 oui $vie_oui pcap_data $vie_flag ftype_map ff
		}
		[ "x$backhaul" = "x1" ] || {
			[ -n "$vie_oui" -a -n "$vie_fg_flag" ] && wlanconfig $ifname vendorie update len 11 oui $vie_oui pcap_data $vie_fg_flag ftype_map ff
		}

		# "implicitbf" is set in "wifi-device" section
		config_get_bool implicitbf "$device" implicitbf
		[ -n "$implicitbf" ] && iwpriv "$ifname" implicitbf "${implicitbf}"

		#
		# "implicitbf" is set in "wifi-iface" section. If set, This will
		# overwrite "implicitbf" in "wifi-device" section.
		#
		config_get_bool implicitbf "$vif" implicitbf
		[ -n "$implicitbf" ] && iwpriv "$ifname" implicitbf "${implicitbf}"

		config_get_bool vhtsubfee "$vif" vhtsubfee
		[ -n "$vhtsubfee" ] && iwpriv "$ifname" vhtsubfee "${vhtsubfee}"

		config_get_bool vhtmubfee "$vif" vhtmubfee
		[ -n "$vhtmubfee" ] && iwpriv "$ifname" vhtmubfee "${vhtmubfee}"

		config_get_bool vhtsubfer "$vif" vhtsubfer
		[ -n "$vhtsubfer" ] && iwpriv "$ifname" vhtsubfer "${vhtsubfer}"

		config_get_bool vhtmubfer "$vif" vhtmubfer
		[ -n "$vhtmubfer" ] && iwpriv "$ifname" vhtmubfer "${vhtmubfer}"

		config_get bf "$device" bf
		if [ "$bf" -eq "0" ]; then
			iwpriv "$ifname" vhtsubfer 0
			iwpriv "$ifname" vhtsubfee 0
		else
			iwpriv "$ifname" vhtsubfer 1
			iwpriv "$ifname" vhtsubfee 1
		fi

		# Multi-user MIMO
		config_get_bool mu_mimo "$device" mu_mimo 1
		if [ "$bf" -eq "1" ] && [ "$mu_mimo" -eq "1" ]; then
			# Enable Multi-user MIMO
			iwpriv "$ifname" vhtmubfer 1
			iwpriv "$ifname" vhtmubfee 1
		else
			# Disable Multi-user MIMO
			iwpriv "$ifname" vhtmubfer 0
			iwpriv "$ifname" vhtmubfee 0
		fi

		# For Netgear Mars' request, when high band's backhaul is enabled,
		# let explicit BF on and implicit BF off.
		[ "x$backhaul" = "x1" ] && {
			iwpriv "$ifname" implicitbf 0
			iwpriv "$ifname" vhtsubfee 1
			iwpriv "$ifname" vhtsubfer 1
			iwpriv "$ifname" vhtmubfee 1
			iwpriv "$ifname" vhtmubfer 1
		}

		config_get vhtstscap "$vif" vhtstscap
		[ -n "$vhtstscap" ] && iwpriv "$ifname" vhtstscap "${vhtstscap}"

		config_get vhtsounddim "$vif" vhtsounddim
		[ -n "$vhtsounddim" ] && iwpriv "$ifname" vhtsounddim "${vhtsounddim}"

		config_get encap_type "$vif" encap_type
		[ -n "$encap_type" ] && iwpriv "$ifname" encap_type "${encap_type}"

		config_get decap_type "$vif" decap_type
		[ -n "$decap_type" ] && iwpriv "$ifname" decap_type "${decap_type}"

		config_get_bool rawsim_txagr "$vif" rawsim_txagr
		[ -n "$rawsim_txagr" ] && iwpriv "$ifname" rawsim_txagr "${rawsim_txagr}"

		config_get clr_rawsim_stats "$vif" clr_rawsim_stats
		[ -n "$clr_rawsim_stats" ] && iwpriv "$ifname" clr_rawsim_stats "${clr_rawsim_stats}"

		config_get_bool rawsim_debug "$vif" rawsim_debug
		[ -n "$rawsim_debug" ] && iwpriv "$ifname" rawsim_debug "${rawsim_debug}"

		config_get_bool vap_only "$vif" vap_only 0
		if [ "$vap_only" = "1" ]; then
			start_hostapd=
		elif [ "$start_hostapd" = "" ]; then
			ifconfig "$ifname" up
		fi

		# For Arlo feature
		config_get vid_len "$vif" vid_LENGTH 0
		config_get br_len "$vif" vid_br_LENGTH 0
		if [ $vid_len -gt 0 -a $vid_len -eq $br_len ]; then
			local c=1
			while [ $c -le $vid_len ]; do
				config_get vid "$vif" vid_ITEM$c
				config_get br "$vif" vid_br_ITEM$c
				vconfig add $ifname $vid
				brctl addif $br $ifname.$vid
				ifconfig $ifname.$vid up
				c=$(($c + 1))
			done
		fi

		brctl addif "$bridge" "$ifname"

		config_get set_monrxfilter "$vif" set_monrxfilter
		[ -n "$set_monrxfilter" ] && iwpriv "$ifname" set_monrxfilter "${set_monrxfilter}"

		config_get neighbourfilter "$vif" neighbourfilter
		[ -n "$neighbourfilter" ] && iwpriv "$ifname" neighbourfilter "${neighbourfilter}"

		config_get athnewind "$vif" athnewind
		[ -n "$athnewind" ] && iwpriv "$ifname" athnewind "$athnewind"

		config_get osen "$vif" osen
		[ -n "$osen" ] && iwpriv "$ifname" osen "$osen"

		config_get re_scalingfactor "$vif" re_scalingfactor
		[ -n "$re_scalingfactor" ] && iwpriv "$ifname" set_whc_sfactor "$re_scalingfactor"

		config_get root_distance "$vif" root_distance
		[ -n "$root_distance" ] && iwpriv "$ifname" set_whc_dist "$root_distance"

                config_get caprssi "$vif" caprssi
                [ -n "$caprssi" ] && iwpriv "$ifname" caprssi "${caprssi}"

		config_get_bool ap_isolation_enabled $device ap_isolation_enabled 0
		config_get_bool isolate "$vif" isolate 0

		if [ $ap_isolation_enabled -ne 0 ]; then
			[ "$mode" = "wrap" ] && isolate=1
		fi

                config_get_bool ctsprt_dtmbcn "$vif" ctsprt_dtmbcn
                [ -n "$ctsprt_dtmbcn" ] && iwpriv "$ifname" ctsprt_dtmbcn "${ctsprt_dtmbcn}"

		config_get assocwar160  "$vif" assocwar160
		[ -n "$assocwar160" ] && iwpriv "$ifname" assocwar160 "$assocwar160"

		# Force assocwar160 enabled when HT80_80 or HT160 is selected
		[ "$htmode" = "HT80_80" -o "$htmode" = "HT160" ] && iwpriv "$ifname" assocwar160 1

		config_get rawdwepind "$vif" rawdwepind
		[ -n "$rawdwepind" ] && iwpriv "$ifname" rawdwepind "$rawdwepind"

		config_get revsig160  "$vif" revsig160
		[ -n "$revsig160" ] && iwpriv "$ifname" revsig160 "$revsig160"

		config_get channel_block_list "$vif" channel_block_list
		[ -n "$channel_block_list" ] && wifitool "$ifname" block_acs_channel "$channel_block_list"

		config_get rept_spl  "$vif" rept_spl
		[ -n "$rept_spl" ] && iwpriv "$ifname" rept_spl "$rept_spl"

		config_get cactimeout  "$vif" cactimeout
		[ -n "$cactimeout" ] && iwpriv "$ifname" set_cactimeout "$cactimeout"

                config_get global_wds qcawifi global_wds

                if [ $global_wds -ne 0 ]; then
                     iwpriv "$ifname" athnewind 1
                fi

                config_get pref_uplink "$device" pref_uplink
                [ -n "$pref_uplink" ] && iwpriv "$phy" pref_uplink "${pref_uplink}"

                config_get fast_lane "$device" fast_lane
                [ -n "$fast_lane" ] && iwpriv "$phy" fast_lane "${fast_lane}"

                if [ $fast_lane -ne 0 ]; then
                        iwpriv "$ifname" athnewind 1
                fi

		if [ "$ODM" != "dni" ]; then
			local net_cfg bridge
			net_cfg="$(find_net_config "$vif")"
			[ -z "$net_cfg" -o "$isolate" = 1 -a "$mode" = "wrap" ] || {
				[ -f /sys/class/net/${ifname}/parent ] && { \
					bridge="$(bridge_interface "$net_cfg")"
					config_set "$vif" bridge "$bridge"
				}
			}
		fi

		case "$mode" in
			ap|wrap|ap_monitor|ap_smart_monitor|mesh|ap_lp_iot)


				iwpriv "$ifname" ap_bridge "$((isolate^1))"

				config_get_bool l2tif "$vif" l2tif
				[ -n "$l2tif" ] && iwpriv "$ifname" l2tif "$l2tif"

				if [ -n "$start_wapid" ]; then
					wapid_setup_vif "$vif" || {
						echo "enable_qcawifi($device): Failed to set up wapid for interface $ifname" >&2
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi

                if [ "x$ifname" = "x`/bin/config get wl2g_ARLO_AP`" ];then
                    start_hostapd=1
                    start_flag=1
                fi
				if [ -n "$start_hostapd" ] && eval "type hostapd_setup_vif" 2>/dev/null >/dev/null; then
					hostapd_setup_vif "$vif" atheros no_nconfig || {
						echo "enable_qcawifi($device): Failed to set up hostapd for interface $ifname" >&2
						# make sure this wifi interface won't accidentally stay open without encryption
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi
                if [ "x$start_flag" = "x1" ];then
                    start_flag=
                    start_hostapd=
                fi
			;;
			wds|sta)
				if eval "type wpa_supplicant_setup_vif" 2>/dev/null >/dev/null; then
					wpa_supplicant_setup_vif "$vif" athr || {
						echo "enable_qcawifi($device): Failed to set up wpa_supplicant for interface $ifname" >&2
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi
			;;
			adhoc)
				if eval "type wpa_supplicant_setup_vif" 2>/dev/null >/dev/null; then
					wpa_supplicant_setup_vif "$vif" athr || {
						echo "enable_qcawifi($device): Failed to set up wpa"
						ifconfig "$ifname" down
						wlanconfig "$ifname" destroy
						continue
					}
				fi
		esac

		[ -z "$bridge" -o "$isolate" = 1 -a "$mode" = "wrap" ] || {
                        [ -f /sys/class/net/${ifname}/parent ] && { \
				start_net "$ifname" "$net_cfg"
                        }
		}

		set_wifi_up "$vif" "$ifname"

		config_get set11NRates "$vif" set11NRates
		[ -n "$set11NRates" ] && iwpriv "$ifname" set11NRates "$set11NRates"

		# 256 QAM capability needs to be parsed first, since
		# vhtmcs enables/disable rate indices 8, 9 for 2G
		# only if vht_11ng is set or not
		config_get_bool vht_11ng "$vif" vht_11ng
		[ -n "$vht_11ng" ] && iwpriv "$ifname" vht_11ng "$vht_11ng"

		config_get vhtmcs "$vif" vhtmcs
		[ -n "$vhtmcs" ] && iwpriv "$ifname" vhtmcs "$vhtmcs"

		config_get dis_legacy "$vif" dis_legacy
		[ -n "$dis_legacy" ] && iwpriv "$ifname" dis_legacy "$dis_legacy"

		config_get set_bcn_rate "$vif" set_bcn_rate
		[ -n "$set_bcn_rate" ] && iwpriv "$ifname" set_bcn_rate "$set_bcn_rate"

		#support nawds
		config_get nawds_mode "$vif" nawds_mode
		[ -n "$nawds_mode" ] && wlanconfig "$ifname" nawds mode "${nawds_mode}"

		handle_nawds() {
			local value="$1"
			[ -n "$value" ] && wlanconfig "$ifname" nawds add-repeater $value
		}
		config_list_foreach "$vif" nawds_add_repeater handle_nawds

		handle_hmwds() {
			local value="$1"
			[ -n "$value" ] && wlanconfig "$ifname" hmwds add_addr $value
		}
		config_list_foreach "$vif" hmwds_add_addr handle_hmwds

		config_get nawds_override "$vif" nawds_override
		[ -n "$nawds_override" ] && wlanconfig "$ifname" nawds override "${nawds_override}"

		config_get nawds_defcaps "$vif" nawds_defcaps
		[ -n "$nawds_defcaps" ] && wlanconfig "$ifname" nawds defcaps "${nawds_defcaps}"

		handle_hmmc_add() {
			local value="$1"
			[ -n "$value" ] && wlanconfig "$ifname" hmmc add $value
		}
		config_list_foreach "$vif" hmmc_add handle_hmmc_add

		# TXPower settings only work if device is up already
		# while atheros hardware theoretically is capable of per-vif (even per-packet) txpower
		# adjustment it does not work with the current atheros hal/madwifi driver

		config_get vif_txpower "$vif" txpower
		# use vif_txpower (from wifi-iface) instead of txpower (from wifi-device) if
		# the latter doesn't exist
		txpower="${txpower:-$vif_txpower}"
		[ -z "$txpower" ] || iwconfig "$ifname" txpower "${txpower%%.*}"

		config_get rps "$vif" rps
		if [ $rps == 1 ]; then
			enable_rps_wifi=1
		elif [ $rps == 0 ]; then
			enable_rps_wifi=0
		fi

		if [ $enable_rps_wifi == 1 ] && [ -f "/lib/update_system_params.sh" ]; then
			. /lib/update_system_params.sh
			enable_rps $ifname
		fi

		config_get dyn_bw_rts "$vif" dyn_bw_rts
		[ -n "$dyn_bw_rts" ] && iwpriv "$ifname" dyn_bw_rts "$dyn_bw_rts"

		config_get macaddr "$device" macaddr
		[ -n "$macaddr" ] && iwpriv "$phy" setHwaddr "$macaddr"


	done

        config_get primaryradio "$device" primaryradio
        [ -n "$primaryradio" ] && iwpriv "$phy" primaryradio "${primaryradio}"

        config_get CSwOpts "$device" CSwOpts
        [ -n "$CSwOpts" ] && iwpriv "$phy" CSwOpts "${CSwOpts}"

	if [ $disable_qrfs_wifi == 1 ] && [ -f "/lib/update_system_params.sh" ]; then
		. /lib/update_system_params.sh
		disable_qrfs
	fi

	# reset vifs
	config_get vifs "$device" vifs
	# update wlan uptime file
	for vif in $vifs; do
		config_get backhaul "$vif" backhaul 0
		[ -n "$backhaul" -a "$backhaul" = 1 ] && continue
		backhaul_only=0
		config_get ifname "$vif" ifname
		isup=`ifconfig $ifname | grep UP`
		[ -n "$isup" ] && break
	done

	# don't count wifi status for backhaul vap only radio
	[ "$backhaul_only" = "0" ] && {
		band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
		if [ "$isup" != "" -a "$band_type" = "g" ]; then
			cat /proc/uptime | sed 's/ .*//' > /tmp/WLAN_uptime
			echo "ON" > /tmp/WLAN_2G_status
		elif [ "$isup" != "" -a "$band_type" = "a" ]; then
			cat /proc/uptime | sed 's/ .*//' > /tmp/WLAN_uptime_5G
			echo "ON" > /tmp/WLAN_5G_status
		fi
	}

	# workaround for guest network cannot up
	for vif in $vifs; do
		config_get ifname "$vif" ifname
		config_get mode "$vif" mode
		isup=`ifconfig $ifname | grep UP`
		no_assoc=`iwconfig $ifname | grep Not-Associated`
		if [ "$isup" != "" -a "$no_assoc" != "" -a "$mode" != "sta" ]; then
			ifconfig "$ifname" down
			ifconfig "$ifname" up
		fi
	done

	if [ "$DEVICE_TYPE" = "extender" -o "$DEVICE_TYPE" = "satellite" ]; then
		band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
		if [ -n "$wifi_topology_file" ]; then
			ifname=`awk -v input_opmode=STA -v input_wifidev=$phy -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
		else
			echo "enable_qcawifi ($device) cannot found wifi_topology_file"
                fi

		if [ "$band_type" = "g" ] && [ -n "$ifname" ]; then
			killall led-extender 2> /dev/null
			/sbin/led-extender -i ${ifname} &
			cat /sys/class/net/${ifname}/address > /tmp/mac_addr_${ifname}
		elif [ "$band_type" = "a" ] && [ -n "$ifname" ]; then
			killall led-extender-5G 2> /dev/null
			/sbin/led-extender-5G -i ${ifname} &
			cat /sys/class/net/${ifname}/address > /tmp/mac_addr_${ifname}
		fi
	else
		[ ! -f /tmp/link_status ] && echo 0 > /tmp/link_status
		[ ! -f /tmp/link_status_5g ] && echo 0 > /tmp/link_status_5g
	fi

	#
	# WARNING: "config_load wireless" may mess up variable "device".
	#
	# Please avoid adding code segments which use "device" after this
	# segment of code.
	#
	if [ -f "/lib/update_smp_affinity.sh" ]; then
		config_load wireless
		. /lib/update_smp_affinity.sh
		config_foreach enable_smp_affinity_wifi wifi-device
	fi

	lock -u /var/run/wifilock
}

setup_wps_enhc_device() {
	local device=$1
	local wps_enhc_cfg=

	append wps_enhc_cfg "RADIO" "$N"
	config_get_bool wps_pbc_try_sta_always "$device" wps_pbc_try_sta_always 0
	config_get_bool wps_pbc_skip_ap_if_sta_disconnected "$device" wps_pbc_skip_ap_if_sta_disconnected 0
	config_get_bool wps_pbc_overwrite_ap_settings "$device" wps_pbc_overwrite_ap_settings 0
	config_get wps_pbc_overwrite_ssid_band_suffix "$device" wps_pbc_overwrite_ssid_band_suffix
	[ $wps_pbc_try_sta_always -ne 0 ] && \
			append wps_enhc_cfg "$device:try_sta_always" "$N"
	[ $wps_pbc_skip_ap_if_sta_disconnected -ne 0 ] && \
			append wps_enhc_cfg "$device:skip_ap_if_sta_disconnected" "$N"
	[ $wps_pbc_overwrite_ap_settings -ne 0 ] && \
			append wps_enhc_cfg "$device:overwrite_ap_settings" "$N"
	[ -n "$wps_pbc_overwrite_ssid_band_suffix" ] && \
			append wps_enhc_cfg "$device:overwrite_ssid_band_suffix:$wps_pbc_overwrite_ssid_band_suffix" "$N"

	config_get vifs $device vifs

	for vif in $vifs; do
		config_get ifname "$vif" ifname

		append wps_enhc_cfg "VAP" "$N"
		config_get_bool wps_pbc_enable "$vif" wps_pbc_enable 0
		config_get wps_pbc_start_time "$vif" wps_pbc_start_time
		config_get wps_pbc_duration "$vif" wps_pbc_duration
		if [ $wps_pbc_enable -ne 0 ]; then
			[ -n "$wps_pbc_start_time" -a -n "$wps_pbc_duration" ] && \
					append wps_enhc_cfg "$ifname:$wps_pbc_start_time:$wps_pbc_duration:$device" "$N"
			[ -n "$wps_pbc_start_time" -a -n "$wps_pbc_duration" ] || \
					append wps_enhc_cfg "$ifname:-:-:$device" "$N"
		fi
	done

	cat >> /var/run/wifi-wps-enhc-extn.conf <<EOF
$wps_enhc_cfg
EOF
}

setup_wps_enhc() {
	local wps_enhc_cfg=

	append wps_enhc_cfg "GLOBAL" "$N"
	config_get_bool wps_pbc_overwrite_ap_settings_all qcawifi wps_pbc_overwrite_ap_settings_all 0
	[ $wps_pbc_overwrite_ap_settings_all -ne 0 ] && \
			append wps_enhc_cfg "-:overwrite_ap_settings_all" "$N"
	config_get wps_pbc_overwrite_ssid_suffix qcawifi wps_pbc_overwrite_ssid_suffix
	[ -n "$wps_pbc_overwrite_ssid_suffix" ] && \
			append wps_enhc_cfg "-:overwrite_ssid_suffix:$wps_pbc_overwrite_ssid_suffix" "$N"

	cat >> /var/run/wifi-wps-enhc-extn.conf <<EOF
$wps_enhc_cfg
EOF

	config_load wireless
	config_foreach setup_wps_enhc_device wifi-device
}

qcawifi_start_hostapd_cli() {
	local device=$1
	local ifidx=0
	local radioidx=${device#wifi}

	config_get vifs $device vifs

	for vif in $vifs; do
		local config_methods vifname

		config_get vifname "$vif" ifname

		if [ -n $vifname ]; then
			[ $ifidx -gt 0 ] && vifname="ath${radioidx}$ifidx" || vifname="ath${radioidx}"
		fi

		config_get_bool wps_pbc "$vif" wps_pbc 0
		config_get config_methods "$vif" wps_config
		[ "$wps_pbc" -gt 0 ] && append config_methods push_button

		if [ -n "$config_methods" ]; then
			pid=/var/run/hostapd_cli-$vifname.pid
			hostapd_cli -i $vifname -P $pid -a /lib/wifi/wps-hostapd-update-uci -p /var/run/hostapd-$device -B
		fi

		ifidx=$(($ifidx + 1))
	done
}

pre_qcawifi() {
	local action=${1}
	local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`

	config_load wireless

	lock /var/run/wifilock
	case "${action}" in
		disable)
			config_get_bool wps_vap_tie_dbdc qcawifi wps_vap_tie_dbdc 0

			if [ $wps_vap_tie_dbdc -ne 0 ]; then
				kill "$(cat "/var/run/hostapd.pid")"
				[ -f "/tmp/hostapd_conf_filename" ] &&
					rm /tmp/hostapd_conf_filename
			fi

			eval "type qwrap_teardown" >/dev/null 2>&1 && qwrap_teardown
			eval "type icm_teardown" >/dev/null 2>&1 && icm_teardown
			eval "type wpc_teardown" >/dev/null 2>&1 && wpc_teardown
			eval "type lowi_teardown" >/dev/null 2>&1 && lowi_teardown
			[ ! -f /etc/init.d/lbd ] || /etc/init.d/lbd stop
			[ ! -f /etc/init.d/hyd ] || /etc/init.d/hyd stop
			[ ! -f /etc/init.d/ssid_steering ] || /etc/init.d/ssid_steering stop
			[ ! -f /etc/init.d/mcsd ] || /etc/init.d/mcsd stop
			[ ! -f /etc/init.d/wifi-listener ] || /etc/init.d/wifi-listener stop

                       rm -f /var/run/wifi-wps-enhc-extn.conf
                       [ -r /var/run/wifi-wps-enhc-extn.pid ] && kill "$(cat "/var/run/wifi-wps-enhc-extn.pid")"

			rm -f /var/run/iface_mgr.conf
			[ -r /var/run/iface_mgr.pid ] && kill "$(cat "/var/run/iface_mgr.pid")"
                        rm -f /var/run/iface_mgr.pid
			killall -9 iface-mgr 2> /dev/null

			if [ -f	 "/var/run/son.conf" ]; then
				rm /var/run/son.conf
			fi

			if [ -n "$wifi_topology_file" ]; then
				local arlo_ifname=`awk -v input_optype=ARLO -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
			else
				echo "pre_qcawifi cannot found wifi_topology_file"
			fi

			if [ -n "$arlo_ifname" ];then
				vap="`/bin/config get wl2g_ARLO_AP`"
				for client in `wlanconfig $vap list |sed '1d'|awk -F' ' '{print $1}'`;do
					iwpriv $vap kickmac $client
				done
				{ sleep 3;ifconfig $vap down; } &
			fi
		;;
		enable)
			global_qca_hostapd_restart
			global_qca_wpa_supplicant_restart
			# For Arlo feature
			if [ -n "$wifi_topology_file" ]; then
				local arlo_ifname=`awk -v input_optype=ARLO -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
			else
				echo "pre_qcawifi cannot found wifi_topology_file"
			fi

			if [ -n "$arlo_ifname" ]; then
				brctl show | grep $arlo_br >/dev/null 2>&1
				if [ $? -ne 0 ]; then
					brctl addbr $arlo_br
				fi
				# Will be modified by someone who's resposilbe for DHCP
				arlo_vid=`/bin/config get wlg_ap_bh_vids`
				vconfig add eth1 $arlo_vid
				ifconfig eth1.$arlo_vid up
				brctl addif $arlo_br eth1.$arlo_vid
				[ -f "/tmp/orbi_type" ] && product_type=`/bin/cat /tmp/orbi_type`
				if [ "$product_type" = "Base" ]; then
					arlo_ip=`/bin/config get arlo_lan_ipaddr`
					arlo_netmask=`/bin/config get arlo_lan_netmask`
					ifconfig $arlo_br $arlo_ip netmask $arlo_netmask up
					$VLAN_DHCPD arlo $arlo_br
				else
					vconfig add eth0 $arlo_vid
					ifconfig eth0.$arlo_vid up
					brctl addif $arlo_br eth0.$arlo_vid
					ifconfig $arlo_br up
					udhcpc_process=`ps | grep udhcpc | grep arlo | grep -v grep`
					if [ "x$udhcpc_process" == "x" ]; then
						udhcpc -b -i brarlo -h /tmp/dhcp_name.conf -N 0.0.0.0 -s /usr/share/udhcpc/default-arlo.script-ext &
					fi
					echo 1 > /proc/sys/net/ipv4/conf/$arlo_br/proxy_arp
					echo 1 > /proc/sys/net/ipv4/conf/$arlo_br/proxy_arp_pvlan
				fi
			fi
		;;
	esac
    #sleep 1 to prevent unlock error
    sleep 1
	lock -u /var/run/wifilock
}

post_qcawifi() {
	local action=${1}

	lock /var/run/wifilock
	case "${action}" in
		enable)
			local icm_enable qwrap_enable lowi_enable

                        local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`
			if [ -n "$wifi_topology_file" ]; then
				local arlo_ifname=`awk -v input_optype=ARLO -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
			else
				echo "post_qcawifi cannot found wifi_topology_file"
			fi

			[ -n "$arlo_ifname" ] && /usr/sbin/brctl setageing brarlo 65535

			# Run a single hostapd instance for all the radio's
			# Enables WPS VAP TIE feature

			config_get_bool wps_vap_tie_dbdc qcawifi wps_vap_tie_dbdc 0

			if [ $wps_vap_tie_dbdc -ne 0 ]; then
				hostapd_conf_file=$(cat "/tmp/hostapd_conf_filename")
				hostapd -P /var/run/hostapd.pid $hostapd_conf_file -B
				config_foreach qcawifi_start_hostapd_cli wifi-device
			fi

			config_get_bool icm_enable icm enable 0
			[ ${icm_enable} -gt 0 ] && \
					eval "type icm_setup" >/dev/null 2>&1 && {
				icm_setup
			}

			config_get_bool wpc_enable wpc enable 0
			[ ${wpc_enable} -gt 0 ] && \
					eval "type wpc_setup" >/dev/null 2>&1 && {
				wpc_setup
			}

			config_get_bool lowi_enable lowi enable 0
			[ ${lowi_enable} -gt 0 ] && \
				eval "type lowi_setup" >/dev/null 2>&1 && {
				lowi_setup
			}

			eval "type qwrap_setup" >/dev/null 2>&1 && qwrap_setup && _disable_qcawifi

			# These init scripts are assumed to check whether the feature is
			# actually enabled and do nothing if it is not.
			[ ! -f /etc/init.d/lbd ] || /etc/init.d/lbd start
			[ ! -f /etc/init.d/ssid_steering ] || /etc/init.d/ssid_steering start

			config_get_bool wps_pbc_extender_enhance qcawifi wps_pbc_extender_enhance 0
			[ ${wps_pbc_extender_enhance} -ne 0 ] && { \
				rm -f /var/run/wifi-wps-enhc-extn.conf
				setup_wps_enhc
			}
			config_load wireless
			config_foreach son_get_config wifi-device

                        rm -f /etc/ath/iface_mgr.conf
                        rm -f /var/run/iface_mgr.pid
                        iface_mgr_setup

			shift
			for device in $@; do
				config_get sys_bridge $device sys_bridge
				[ -n "$sys_bridge" ] && {
					lan_ipaddr=$(ifconfig $sys_bridge | grep "inet addr" | awk '{print $2}'| awk -F ':' '{print $2}')
					netmask=$(ifconfig $sys_bridge | grep "inet addr" | awk '{print $4}'| awk -F ':' '{print $2}')
					wl_lan_restricted_access $lan_ipaddr $netmask $@
					if [ -n "$vpn_ifname" ] &&
					   [ -n "$(ifconfig "$vpn_ifname" 2>/dev/null)" ]; then
						wl_lan_restricted_access_vpn  $@
					fi
					break
				}
			done

			if [ "$DEVICE_TYPE" = "extender" -o "$DEVICE_TYPE" = "satellite" ] && [ -f /sbin/ap-led ]; then
				pidlist=`pidof ap-led`
				for pid in $pidlist; do
					kill -9 $pid
				done
				/sbin/ap-led &
			fi

			if [ "`/bin/config get restart_vzdaemon`" = "1" ];then
				kill -9 `ps|grep vzdaemon|grep -v grep|awk -F' ' '{print $1}'`
				/etc/init.d/vzdaemon start
				/bin/config set restart_vzdaemon=0
			fi
		;;
	esac
    #sleep 1 to prevent unlock error
    sleep 1
	lock -u /var/run/wifilock
}

wsplcd_restart_war()
{
    local devices="$1"
    local cur_chan
    local cur_freq
    local new_chan
    local new_freq

    /etc/init.d/wsplcd stop
    for device in ${devices}; do
        new_chan=$(uci get wireless.$device.channel)
        [ auto = "$new_chan" ] && new_chan=0

        [ -e /sys/class/net/$device ] || continue
        config_get vifs "$device" vifs
        for vif in $vifs; do
            # Skip backhaul and not AP mode VAPs.
            config_get ifname "$vif" ifname
            [ -e /sys/class/net/$ifname ] || continue
            config_get mode "$vif" mode
            [ "$mode" != "ap" ] && continue
            config_get backhaul "$vif" backhaul
            [ -n "$backhaul" -a "$backhaul" = 1 ] && continue

            cur_chan=`iwpriv $ifname get_deschan | awk -F\: '{gsub(/ /, "", $2); print $2}'`

            # Check if we need to set channel again.
            if [ $cur_chan != $new_chan ]; then
                local check_times=15
                local i=0
                local not_associated
                # Set channel to interface and wait for it done.
                echo "Current channel is $cur_chan, and is setting it to $new_chan" > /dev/console
                ifconfig $ifname down
                iwconfig $ifname channel $new_chan
                ifconfig $ifname up
                while [ $i -le $check_times ]; do
                    sleep 2
                    not_associated=`iwconfig $ifname | grep "Frequency:" | grep "Not-Associated"`
                    [ -z "$not_associated" ] && break
                    i=$(( $i + 1 ))
                done
                # Read channel and write it back to wireless configuration file.
                new_chan=`iwpriv $ifname get_deschan | awk -F\: '{gsub(/ /, "", $2); print $2}'`
                echo "Write new channel $new_chan to wireless configuration file" > /dev/console
                uci set wireless.$device.channel=$new_chan
            fi
        done
    done
    uci commit wireless
    echo "Restart wsplcd and wait for 20 seconds" > /dev/console
    /etc/init.d/wsplcd start
    sleep 20
}

post_updateconf_qcawifi()
{
    echo "QCA post_updateconf_qcawifi"
}

wifitoggle_qcawifi()
{
    local device="$1"
    local hw_btn_state="$2"
    local gui_radio_state="$3"

    find_qcawifi_phy "$device" || return 1

    band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c1`
    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get ifname "$vif" ifname
        if [ "$hw_btn_state" = "on" ]; then
	    if [ "$gui_radio_state" = "on" ] ||
		[ "$band_type" = "g" -a "$gui_radio_state" = "g_on" ] ||
		[ "$band_type" = "a" -a "$gui_radio_state" = "a_on" ]; then
                config_get mode "$vif" mode
                if [ "$mode" = "ap" ]; then
                    test -f /var/run/hostapd_cli-${ifname}.pid && kill $(cat /var/run/hostapd_cli-${ifname}.pid)
                fi
                ifconfig "$ifname" down
	    fi
        elif [ "$hw_btn_state" = "off" ]; then
	    if [ "$gui_radio_state" = "on" ] ||
		[ "$band_type" = "g" -a "$gui_radio_state" = "g_on" ] ||
		[ "$band_type" = "a" -a "$gui_radio_state" = "a_on" ]; then
                isup=`ifconfig $ifname | grep UP`
                [ -n "$isup" ] && continue
                ifconfig "$ifname" up
                config_get enc "$vif" encryption "none"
                case "$enc" in
                    none)
                        # If we're in open mode and want to use WPS, we
                        # must start hostapd_cli
                        config_get_bool wps_pbc "$vif" wps_pbc 0
                        config_get config_methods "$vif" wps_config
                        [ "$wps_pbc" -gt 0 ] && append config_methods push_button
                        if [ -n "$config_methods" ]; then 
                            hostapd_setup_vif "$vif" atheros no_nconfig
                        fi
                        ;;
                    mixed*|psk*|wpa*)
                        config_get mode "$vif" mode
                        if [ "$mode" = "ap" ]; then
                            hostapd_setup_vif "$vif" atheros no_nconfig
                        else
                            wpa_supplicant_setup_vif "$vif" athr
                        fi
                        ;;
                esac
	    fi
        fi
    done

    # update wlan uptime file
    config_get ifname "$vif" ifname
    isup=`ifconfig $ifname | grep UP`

    if [ "$isup" != "" -a "$band_type" = "g" ]; then
        cat /proc/uptime | sed 's/ .*//' > /tmp/WLAN_uptime
        echo "ON" > /tmp/WLAN_2G_status
    elif [ "$isup" != "" -a "$band_type" = "a" ]; then
        cat /proc/uptime | sed 's/ .*//' > /tmp/WLAN_uptime_5G
        echo "ON" > /tmp/WLAN_5G_status
    elif [ "$isup" = "" -a "$band_type" = "g" ]; then
        rm /tmp/WLAN_uptime
        echo "OFF" > /tmp/WLAN_2G_status
    elif [ "$isup" = "" -a "$band_type" = "a" ]; then
        rm /tmp/WLAN_uptime_5G
        echo "OFF" > /tmp/WLAN_5G_status
    fi
}

post_lock_qcawifi()
{
    echo "QCA post_lock_qcawifi" > /dev/console
    local wsplcd_enabled=$(uci get wsplcd.config.HyFiSecurity)
    local hyd_enabled=$(uci get hyd.config.Enable)

    if [ "x$wsplcd_enabled" = "x1" ]; then
        echo "Restart wsplcd after wlan up" > /dev/console
        /etc/init.d/wsplcd restart
    fi

    if [ "x$hyd_enabled" = "x1" ]; then
        echo "Restart hyd after wlan up" > /dev/console
        /sbin/wifison.sh updateconf lbd
        /etc/init.d/hyd restart
    fi
}

wifischedule_qcawifi()
{
    local device="$1"
    local hw_btn_state="$2"
    local band="$3"
    local newstate="$4"
    local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`
    local _optype _opmode

    # Does this "$device" contain only backhaul ifaces? 1 = yes, 0 = no
    local backhaul_only=1

    find_qcawifi_phy "$device" || return 1

    config_get hwmode "$device" hwmode
    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get ifname "$vif" ifname
        if [ -n "$wifi_topology_file" ]; then
            _optype=`awk -v input_ifname=$ifname -v output_rule=optype -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
            _opmode=`awk -v input_ifname=$ifname -v output_rule=opmode -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
        else
            echo "wifischedule_qcawifi ($device) cannot found wifi_topology_file"
        fi

        # We don't schedule backhaul nor station interfaces
        [ "$_optype" = "BACKHAUL" -o "$_opmode" = "STA" ] && continue
        if [ "$newstate" = "on" -a "$hw_btn_state" = "on" ]; then
            isup=`ifconfig $ifname | grep UP`
            [ -n "$isup" ] && continue
            ifconfig "$ifname" up
            config_get enc "$vif" encryption "none"
            case "$enc" in
                none)
                    # If we're in open mode and want to use WPS, we
                    # must start hostapd_cli
                    config_get_bool wps_pbc "$vif" wps_pbc 0
                    config_get config_methods "$vif" wps_config
                    [ "$wps_pbc" -gt 0 ] && append config_methods push_button
                    if [ -n "$config_methods" ]; then
                        hostapd_setup_vif "$vif" atheros no_nconfig
                    fi
                    ;;
                mixed*|psk*|wpa*)
                    hostapd_setup_vif "$vif" atheros no_nconfig
                    ;;
            esac
            if [ "`grep -c "^[ga].*_device" /etc/ath/wifi.conf`" = "1" ]; then
	        logger "[Wireless signal schedule] The wireless signal is ON,"
            else
                case "$hwmode" in
                    *b|*g|*ng) logger "[Wireless signal schedule] The wireless 2.4GHz signal is ON,";;
                    *a|*na|*ac) logger "[Wireless signal schedule] The wireless 5GHz signal is ON," ;;
                esac
            fi
        else
            test -f /var/run/hostapd_cli-${ifname}.pid && kill $(cat /var/run/hostapd_cli-${ifname}.pid)
            ifconfig "$ifname" down
            if [ "`grep -c "^[ga].*_device" /etc/ath/wifi.conf`" = "1" ]; then
                logger "[Wireless signal schedule] The wireless signal is OFF,"
            else
                case "$hwmode" in
                    *b|*g|*ng) logger "[Wireless signal schedule] The wireless 2.4GHz signal is OFF,";;
                    *a|*na|*ac) logger "[Wireless signal schedule] The wireless 5GHz signal is OFF," ;;
                esac
            fi
        fi
    done

    # reset vifs
    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get backhaul "$vif" backhaul 0
        [ -n "$backhaul" -a "$backhaul" = 1 ] && continue
        backhaul_only=0
        config_get ifname "$vif" ifname
        isup=`ifconfig $ifname | grep UP`
        [ -n "$isup" ] && break
    done

    # don't count wifi status for backhaul vap only radio
    [ "$backhaul_only" = "1" ] && return

    band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
    if [ "$isup" != "" -a "$band_type" = "g" ]; then
        cat /proc/uptime | sed 's/ .*//' > /tmp/WLAN_uptime
        echo "ON" > /tmp/WLAN_2G_status
    elif [ "$isup" != "" -a "$band_type" = "a" ]; then
        cat /proc/uptime | sed 's/ .*//' > /tmp/WLAN_uptime_5G
        echo "ON" > /tmp/WLAN_5G_status
    elif [ "$isup" = "" -a "$band_type" = "g" ]; then
        rm /tmp/WLAN_uptime
        echo "OFF" > /tmp/WLAN_2G_status
    elif [ "$isup" = "" -a "$band_type" = "a" ]; then
        rm /tmp/WLAN_uptime_5G
        echo "OFF" > /tmp/WLAN_5G_status
    fi
}

wifistainfo_qcawifi()
{
    local device="$1"
    local _optype
    local _opmode
    local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`

    find_qcawifi_phy "$device" || return 1

    tmpfile=/tmp/sta_info.$$

    config_get vifs "$device" vifs
    for vif in $vifs; do
        config_get ifname "$vif" ifname
        if [ -n "$wifi_topology_file" ]; then
            _optype=`awk -v input_ifname=$ifname -v output_rule=optype -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
            _opmode=`awk -v input_ifname=$ifname -v output_rule=opmode -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
        else
            echo "wifistainfo_qcawifi ($device) cannot found wifi_topology_file"
        fi

        if [ "$_optype" != "NORMAL" -a "$_optype" != "GUEST" ]; then
                continue
        elif [ "$_opmode" != "AP" ]; then
                continue
        fi

        wlanconfig "$ifname" list sta >> $tmpfile
        band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy  | cut -c 1`
        if [ "$band_type" = "g" ]; then
            if [ "$_optype" = "NORMAL" ]; then
                echo "###2.4G###"
            elif [ "$_optype" = "GUEST" ]; then
                echo "###2.4G Guest###"
            fi
        else
            if [ "$_optype" = "NORMAL" ]; then
                echo "###5G###"
            elif [ "$_optype" = "GUEST" ]; then
                echo "###5G Guest###"
            fi
        fi
        [ -f /usr/lib/stainfo.awk ] && awk -f /usr/lib/stainfo.awk $tmpfile
        rm -f $tmpfile
        echo ""
    done
}

wifiradio_qcawifi()
{
    local device=$1

    config_get vifs "$device" vifs

    shift
    while [ "$#" -gt "0" ]; do
        case $1 in
            -s|--status)
                for vif in $vifs; do
                    config_get ifname "$vif" ifname
                    isup=`ifconfig $ifname | grep UP`
                done
                [ -n "$isup" ] && echo "ON" || echo "OFF"
                shift
                ;;
            -c|--channel)
                for vif in $vifs; do
                    config_get ifname "$vif" ifname
                    isap=`iwconfig $ifname | grep Master`
                    [ -z "$isap" ] && continue
                    p_chan=`iwlist $ifname chan | grep Current | awk '{printf "%d\n", substr($5,1,length($5))}'`
                    cur_mode=`iwpriv $ifname g_dni_curmode | cut -d: -f2`
                    is_20=`echo $cur_mode | grep '20'`
                    is_plus=`echo $cur_mode | grep 'PLUS'`
                    is_minus=`echo $cur_mode | grep 'MINUS'`
                    is_80=`echo $cur_mode | grep '80'`

                    # when enable wla_ht160, need change mode to HT160 for EU and HT80_80 for NA.
                    # EU use channel "36+40+44+48+52+56+60+64" or "100+104+108+112+116+120+124+128"
                    # NA use channel "36+40+44+48+149+153+157+161"
                    is_80_80=`echo $cur_mode | grep '80_80'`
                    is_160=`echo $cur_mode | grep '160'`

                    if [ -n "$is_20" ]; then
                        chan=$p_chan
                    elif [ -n "$is_plus" ]; then
                        s_chan=$(($p_chan + 4));
                        chan="${p_chan}(P) + ${s_chan}(S)"
                    elif [ -n "$is_minus" ]; then
                        s_chan=$(($p_chan - 4));
                        chan="${p_chan}(P) + ${s_chan}(S)"
                    elif [ -z "$is_80_80" -a -n "$is_80" ]; then
                        case "${p_chan}" in
                            36) chan="36(P) + 40 + 44 + 48" ;;
                            40) chan="36 + 40(P) + 44 + 48" ;;
                            44) chan="36 + 40 + 44(P) + 48" ;;
                            48) chan="36 + 40 + 44 + 48(P)" ;;
                            52) chan="52(P) + 56 + 60 + 64" ;;
                            56) chan="52 + 56(P) + 60 + 64" ;;
                            60) chan="52 + 56 + 60(P) + 64" ;;
                            64) chan="52 + 56 + 60 + 64(P)" ;;
                            100) chan="100(P) + 104 + 108 + 112" ;;
                            104) chan="100 + 104(P) + 108 + 112" ;;
                            108) chan="100 + 104 + 108(P) + 112" ;;
                            112) chan="100 + 104 + 108 + 112(P)" ;;
                            116) chan="116(P) + 120 + 124 + 128" ;;
                            120) chan="116 + 120(P) + 124 + 128" ;;
                            124) chan="116 + 120 + 124(P) + 128" ;;
                            128) chan="116 + 120 + 124 + 128(P)" ;;
                            149) chan="149(P) + 153 + 157 + 161";;
                            153) chan="149 + 153(P) + 157 + 161";;
                            157) chan="149 + 153 + 157(P) + 161";;
                            161) chan="149 + 153 + 157 + 161(P)";;
                        esac
                    elif [ -n "$is_80_80" ]; then
                        case "${p_chan}" in
                            36) chan="36(P) + 40 + 44 + 48 + 149 + 153 + 157 + 161" ;;
                            40) chan="36 + 40(P) + 44 + 48 + 149 + 153 + 157 + 161" ;;
                            44) chan="36 + 40 + 44(P) + 48 + 149 + 153 + 157 + 161" ;;
                            48) chan="36 + 40 + 44 + 48(P) + 149 + 153 + 157 + 161" ;;
                            149) chan="36 + 40 + 44 + 48 + 149(P) + 153 + 157 + 161";;
                            153) chan="36 + 40 + 44 + 48 + 149 + 153(P) + 157 + 161";;
                            157) chan="36 + 40 + 44 + 48 + 149 + 153 + 157(P) + 161";;
                            161) chan="36 + 40 + 44 + 48 + 149 + 153 + 157 + 161(P)";;
                         esac
                    elif [ -n "$is_160" ]; then
                        case "${p_chan}" in
                            36) chan="36(P) + 40 + 44 + 48 + 52 + 56 + 60 + 64" ;;
                            40) chan="36 + 40(P) + 44 + 48 + 52 + 56 + 60 + 64" ;;
                            44) chan="36 + 40 + 44(P) + 48 + 52 + 56 + 60 + 64" ;;
                            48) chan="36 + 40 + 44 + 48(P) + 52 + 56 + 60 + 64" ;;
                            52) chan="36 + 40 + 44 + 48 + 52(P) + 56 + 60 + 64" ;;
                            56) chan="36 + 40 + 44 + 48 + 52 + 56(P) + 60 + 64" ;;
                            60) chan="36 + 40 + 44 + 48 + 52 + 56 + 60(P) + 64" ;;
                            64) chan="36 + 40 + 44 + 48 + 52 + 56 + 60 + 64(P)" ;;
                            100) chan="100(P) + 104 + 108 + 112 + 116 + 120 + 124 + 128" ;;
                            104) chan="100 + 104(P) + 108 + 112 + 116 + 120 + 124 + 128" ;;
                            108) chan="100 + 104 + 108(P) + 112 + 116 + 120 + 124 + 128" ;;
                            112) chan="100 + 104 + 108 + 112(P) + 116 + 120 + 124 + 128" ;;
                            116) chan="100 + 104 + 108 + 112 + 116(P) + 120 + 124 + 128" ;;
                            120) chan="100 + 104 + 108 + 112 + 116 + 120(P) + 124 + 128" ;;
                            124) chan="100 + 104 + 108 + 112 + 116 + 120 + 124(P) + 128" ;;
                            128) chan="100 + 104 + 108 + 112 + 116 + 120 + 124 + 128(P)" ;;
                        esac
                    else
                        chan=$p_chan
                    fi
                    echo "$chan"
                    break;
                done
                shift
                ;;
            --coext)
                for vif in $vifs; do
                    config_get ifname "$vif" ifname
                    isap=`iwconfig $ifname | grep Master`
                    [ -z "$isap" ] && continue
                    if [ "$2" = "on" ]; then
                        iwpriv $ifname disablecoext 0
                        iwpriv $ifname extbusythres 30
                    else
                        iwpriv $ifname disablecoext 1
                        iwpriv $ifname extbusythres 100
                    fi
                done
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
}

get_backhaul_sta_status_qcawifi()
{
    local wifi_topology_file=$2
    local ifname
    local bh_connected=0
    for ifname in `awk -v input_optype=BACKHAUL -v input_opmode=STA -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`; do
        local vap_connected=`cat /proc/sys/net/$ifname/status | head -n 3 | grep RUN`
        [ -n "$vap_connected" ] && {
            bh_connected=1
            break;
        }
    done
    if [ "$bh_connected" = "0" ]; then
        eval export -- "${1}=0"
    else
        eval export -- "${1}=1"
    fi
}

get_optype_opmode_qcawifi()
{
    # $1 -> optype
    # $2 -> opmode

    if [ -n "$wifi_topology_file" ]; then
        local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`
    else
        eval export -- "${1}=NORMAL"
        eval export -- "${2}=AP"
        return
    fi

    if [ -n "$wifi_topology_file" ]; then
        local backhaul_sta=`awk -v input_optype=BACKHAUL -v input_opmode=STA -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
        local arlo_ap=`awk -v input_optype=ARLO -v input_opmode=AP -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
    else
        echo "get_optype_opmode_qcawifi cannot found wifi_topology_file"
    fi

    if [ -z "$backhaul_sta" ]; then
        eval export -- "${2}=AP"
        if [ -n "$wifi_topology_file" ]; then
            local backhaul_ap=`awk -v input_optype=BACKHAUL -v input_opmode=AP -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
        else
            echo "get_optype_opmode_qcawifi cannot found wifi_topology_file"
        fi

        if [ -z "$backhaul_ap" ]; then
            if [ -z "arlo_ap" ]; then
                eval export -- "${1}=NORMAL"
            else
                eval export -- "${1}=\"NORMAL ARLO\""
            fi
        else
            if [ -z "arlo_ap" ]; then
                eval export -- "${1}=\"BACKHAUL NORMAL\""
            else
                eval export -- "${1}=\"BACKHAUL NORMAL ARLO\""
            fi
        fi
    else
        get_backhaul_sta_status_qcawifi _connected $wifi_topology_file
        if [ "$_connected" = "1" ]; then
            if [ -z "arlo_ap" ]; then
                eval export -- "${1}=\"BACKHAUL NORMAL\""
            else
                eval export -- "${1}=\"BACKHAUL NORMAL ARLO\""
            fi
            eval export -- "${2}=AP"
        else
            eval export -- "${1}=BACKHAUL"
            eval export -- "${2}=STA"
        fi
    fi
}

wps_qcawifi()
{
    local device=$1
    local hostapd_if=/var/run/hostapd-${device}
    local supplicant_if=var/run/wpa_supplicant-${device}
    local _opmode
    local _optype
    local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`

    get_optype_opmode_qcawifi _optype _opmode

    shift
    while [ "$#" -gt "0" ]; do
        case $1 in
            -c|--client_pin)
                for optype in $_optype; do
                    [ "$optype" = "NORMAL" ] || continue
                    for opmode in $_opmode; do
                        if [ "$opmode" = "AP" ]; then
                            if [ -n "$wifi_topology_file" ]; then
                                ifname=`awk input_optype=$optype -v input_opmode=$opmode -v input_wifidev=$device -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
                            else
                                echo "wps_qcawifi ($device) cannot found wifi_topology_file"
                            fi

                            ifname="$(echo -e $ifname | tr -d '[[:space:]]')"
                            [ -n "$ifname" ] || continue
                            dir=/var/run/hostapd-$device
                            [ -d $dir ] && {
                                hostapd_cli -i $ifname -p "$dir" wps_cancel
                                sleep 1
                                nopbn=`iwpriv $ifname get_nopbn | cut -d':' -f2`
                                if [ $nopbn != 1 ]; then
                                    hostapd_cli -i $ifname -p "$dir" wps_pin any $2
                                fi
                            }
                        fi
                    done
                done
                shift 2
                ;;
            -p|--pbc_start)
                local PIPE_NAME='/var/run/repacd.pipe'
                local repacd_notified=0
                local repacd_enable
                repacd_enable=`/sbin/uci -q get repacd.repacd.Enable`
                for optype in $_optype; do
                    for opmode in $_opmode; do
                        if [ -n "$wifi_topology_file" ]; then
                            ifname=`awk -v input_optype=$optype -v input_opmode=$opmode -v input_wifidev=$device -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
                        else
                            echo "wps_qcawifi ($device) cannot found wifi_topology_file"
                        fi
                        ifname=`echo -e $ifname | tr -d " "`
                        [ -n "$ifname" ] || continue
                        if [ "$opmode" = "AP" ]; then
                            dir=/var/run/hostapd-$device
                            [ -d $dir ] && {
                                nopbn=`iwpriv $ifname get_nopbn | cut -d':' -f2`
                                if [ $nopbn != 1 ]; then
                                    echo "Activate PBC for $optype:$opmode - $ifname" > /dev/console
                                    hostapd_cli -i $ifname -p "$dir" wps_cancel
                                    hostapd_cli -i $ifname -p "$dir" wps_pbc
                                fi
                            }
                        else
				disable_function=$(/bin/config get disable_supplicant_after_connect_to_base)
				if [ "x$disable_function" = "x1" ]; then
					Conn_Base=$(/bin/config get conn_base)
					if [ "x$Conn_Base" = "x1" ]; then
					echo "wps_fail" >/var/run/led_ctrl.pipie
					echo "wps_fail" >/var/run/repacd.pipe
					continue
					fi
				fi

                            dir=/var/run/wpa_supplicant-$ifname
                            [ -d $dir ] && {
                                pid=/var/run/wps-hotplug-$ifname.pid
                                echo "Activate PBC for $_optype:$_opmode - $ifname" > /dev/console
                                wpa_cli -p "$dir" wps_pbc
                                [ -f $pid ] || {
                                    wpa_cli -p"$dir" -a/lib/wifi/wps-supplicant-update-uci -P$pid -B
                                }
                                if [ -n "$repacd_enable" -a "$repacd_enable" -ne 0 -a -p $PIPE_NAME -a "$repacd_notified" -eq 0 ] ; then
                                    echo "wps_pbc" > $PIPE_NAME &
                                    repacd_notified=1
                                fi
                            }
                        fi
                    done
                done
                shift
                ;;
            --pbc_bh_start)
                for optype in $_optype; do
                    for opmode in $_opmode; do
                        if [ -n "$wifi_topology_file" ]; then
                            ifname=`awk -v input_optype=BACKHAUL -v input_opmode=$opmode -v input_wifidev=$device -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
                        else
                            echo "wps_qcawifi ($device) cannot found wifi_topology_file"
                        fi
                        ifname=`echo -e $ifname | tr -d " "`
                        [ -n "$ifname" ] || continue
                        if [ "$opmode" = "AP" ]; then
                            dir=/var/run/hostapd-$device
                            [ -d $dir ] && {
                                nopbn=`iwpriv $ifname get_nopbn | cut -d':' -f2`
                                if [ $nopbn != 1 ] && [ "$optype" = "BACKHAUL" ]; then
                                    echo "Activate PBC for $optype:$opmode - $ifname" > /dev/console
                                    hostapd_cli -i $ifname -p "$dir" wps_cancel
                                    hostapd_cli -i $ifname -p "$dir" wps_pbc
                                fi
                            }
                        fi
                    done
                done
                shift
                ;;
            -s|--wps_stop)
                for optype in $_optype; do
                    for opmode in $_opmode; do
                        if [ -n "$wifi_topology_file" ]; then
                            ifname=`awk input_optype=$optype -v input_opmode=$opmode -v input_wifidev=$device -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
                        else
                            echo "wps_qcawifi ($device) cannot found wifi_topology_file"
                        fi
                        ifname="$(echo -e $ifname | tr -d '[[:space:]]')"
                        [ -n "$ifname" ] || continue
                        if [ "$opmode" = "AP" ]; then
                            dir=/var/run/hostapd-$device
                            [ -d $dir ] && {
                                hostapd_cli -i $ifname -p "$dir" wps_cancel
                            }
                        else
                            dir=/var/run/wpa_supplicant-$ifname
                            [ -d $dir ] && {
                                pid=/var/run/wps-hotplug-$ifname.pid
                                wpa_cli -p "$dir" wps_cancel
                            }
                        fi
                    done
                done
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

statistic_qcawifi()
{
    local device=$1

    find_qcawifi_phy "$device" || return 1

    ifconfig $1 > /dev/null 2>&1
    if [ "$?" = "0" ]; then
        tx_packets=`athstats -i $1 | grep 'ast_tx_packets' | cut -f 2`
        rx_packets=`athstats -i $1 | grep 'ast_rx_packets' | cut -f 2`
        collisions=0
        tx_bytes=`athstats -i $1 | grep 'ast_tx_bytes' | cut -f 2`
        rx_bytes=`athstats -i $1 | grep 'ast_rx_bytes' | cut -f 2`

        band_type=`grep "^[ga].*_device" /etc/ath/wifi.conf | grep $phy | cut -c 1`
        if [ "$band_type" = "g" ]; then
            echo "###2.4G###"
        else
            echo "###5G###"
        fi
        echo "TX packets:$tx_packets"
        echo "RX packets:$rx_packets"
        echo "collisons:$collisions"
        echo "TX bytes:$tx_bytes"
        echo "RX bytes:$rx_bytes"
        echo ""
    fi
}

kickallclient_qcawifi()
{
    local devices="$1"
    for device in ${devices}; do
        config_get vifs "$device" vifs
        for vif in $vifs; do
            # Skip backhaul and not AP mode VAPs.
            config_get mode "$vif" mode
            [ "$mode" != "ap" ] && continue
            config_get backhaul "$vif" backhaul 0
            [ -n "$backhaul" -a "$backhaul" = 1 ] && continue

            config_get ifname "$vif" ifname
            for cli in `wlanconfig $ifname list sta | tail -n +2 | awk '{print $1}'`; do
                echo "Kick clien [$cli] from $ifname" > /dev/console
                iwpriv $ifname kickmac $cli
            done
        done
    done
}

connection_qcawifi()
{
    local devices="$1"
    local status="$2"

    for device in ${devices}; do
        config_get vifs "$device" vifs
        for vif in $vifs; do
            # Skip backhaul and not AP mode VAPs.
            config_get mode "$vif" mode
            [ "$mode" != "ap" ] && continue
            config_get backhaul "$vif" backhaul 0
            [ -n "$backhaul" -a "$backhaul" = 1 ] && continue

            config_get ifname "$vif" ifname
            if [ "$status" != "deny" ]; then
                config_get vap_only "$vif" vap_only 0
                if [ "$vap_only" != "1" ]; then
                    ifconfig $ifname up #iwpriv $ifname maccmd 0
                else
                    echo "radio $device is off,so shoule not enable $ifname interface" > /dev/console
                fi
            else
                ifconfig $ifname down #iwpriv $ifname maccmd 1
            fi
        done
    done
}

check_qcawifi_device() {
	[ ${1%[0-9]} = "wifi" ] && config_set "$1" phy "$1"
	config_get phy "$1" phy
	[ -z "$phy" ] && {
		find_qcawifi_phy "$1" >/dev/null || return 1
		config_get phy "$1" phy
	}
	[ "$phy" = "$dev" ] && found=1
}


detect_qcawifi() {
	local ODM=$1
	local noinsert=$2
	devidx=0
	olcfg_ng=0
	olcfg_ac=0
	nss_olcfg=0
	nss_ol_num=0
	reload=0
	[ "$ODM" = "dni" -a "$noinsert" = "1" ] || {
		sleep 3
		load_qcawifi
        }
	config_load wireless
	while :; do
		config_get type "wifi$devidx" type
		[ -n "$type" ] || break
		devidx=$(($devidx + 1))
	done
	cd /sys/class/net
	[ -d wifi0 ] || return
    [ -f /tmp/.wlan_updateconf_lockfile ] && exit 0
	for dev in $(ls -d wifi* 2>&-); do
		found=0
		config_foreach check_qcawifi_device wifi-device
		[ "$found" -gt 0 ] && continue

		hwcaps=$(cat ${dev}/hwcaps)
		case "${hwcaps}" in
			*11bgn) mode_11=ng;;
			*11abgn) mode_11=ng;;
			*11an) mode_11=na;;
			*11an/ac) mode_11=ac;;
			*11abgn/ac) mode_11=ac;;
		esac
		if [ -f /sys/class/net/${dev}/nssoffload ] && [ $(cat /sys/class/net/${dev}/nssoffload) == "capable" ]; then
			case "${mode_11}" in
				ng)
					if [ $olcfg_ng == 0 ]; then
						olcfg_ng=1
						nss_olcfg=$(($nss_olcfg|$((1<<$devidx))))
						nss_ol_num=$(($nss_ol_num + 1))
					fi
				;;
				na|ac)
					if [ $olcfg_ac == 0 ]; then
						olcfg_ac=1
						nss_olcfg=$(($nss_olcfg|$((1<<$devidx))))
						nss_ol_num=$(($nss_ol_num + 1))
					fi
				;;
			esac
		fi
		echo $nss_olcfg >/lib/wifi/wifi_nss_olcfg
		echo $nss_ol_num >/lib/wifi/wifi_nss_olnum
		reload=1
		cat <<EOF
config wifi-device  wifi$devidx
	option type	qcawifi
	option channel	auto
	option macaddr	$(cat /sys/class/net/${dev}/address)
	option hwmode	11${mode_11}
	# REMOVE THIS LINE TO ENABLE WIFI:
	option disabled 1

config wifi-iface
	option device	wifi$devidx
	option network	lan
	option mode	ap
	option ssid	OpenWrt
	option encryption none

EOF
	devidx=$(($devidx + 1))
	done

	if [ $reload == 1 ]; then
		unload_qcawifi > /dev/null
		load_qcawifi > /dev/null
	fi
}

# Handle traps here
trap_qcawifi() {
	# Release any locks taken
	lock -u /var/run/wifilock
}

calculate_subnet()
{
    local lan_ipaddr=$1
    local netmask=$2
    local mask=0
    local ip=0
    local CIDR=0

    if [ -z "$lan_ipaddr" ] || [ -z "$netmask" ] || [ -z "$3" ]; then
        echo "WARNING: calculate_subnet(): Not execute because empty argument is found!!"
        return
    fi

    for var in 1 2 3 4
    do
        cnt=$(echo $netmask | awk -F '.' '{print $'$var'}')
        ipt=$(echo $lan_ipaddr | awk -F '.' '{print $'$var'}')
        if [ "$cnt" -gt 255 -o "$cnt" -lt 0 -o "$ipt" -gt 255 -o "$ipt" -lt 0 ]; then
            return
        fi
        mask=$(( mask + (cnt << (4-var)*8) ))
        ip=$(( ip + (ipt << (4-var)*8) ))
    done

    for var in $(seq 31 -1 0)
    do
        cnt=$((mask & (1 << var) ))
        [ $cnt -eq 0 ] && break
        CIDR=$((CIDR + 1))
    done

    ip=$(( ip & (0xffffffff << (32 - CIDR))))
    ip1=$((ip >> 24 & 0xff))
    ip2=$((ip >> 16 & 0xff))
    ip3=$((ip >> 8 & 0xff))
    ip4=$((ip & 0xff))
    subnet=$ip1.$ip2.$ip3.$ip4/$CIDR

    eval export -- "${3}=$subnet"
}

base_lan_restricted_access()
{
    local devices=$@
    local inited=0
    local ETH_P_ARP=0x0806
    local ETH_P_RARP=0x8035
    local ETH_P_IP=0x0800
    local ETH_P_IPv6=0x86dd
    local IPPROTO_UDP=17
    local IPPROTO_ICMPv6=58
    local DHCPS_DHCPC=67:68
    local DHCP6S_DHCP6C=546:547
    local PORT_DNS=53
    IN_Chain="GUEST_IN"
    FWD_IN_Chain="GUEST_FWD_IN"
    FWD_OUT_Chain="GUEST_FWD_OUT"

    for device in ${devices}; do
        config_get vifs "$device" vifs
        for vif in $vifs; do
            config_get_bool lan_restricted "$vif" lan_restricted
            if [ "$lan_restricted" = "1" -a "$inited" = "0" ]; then
                add_lan_restricted_chain
                ebtables -P FORWARD ACCEPT
                ebtables -P INPUT ACCEPT
                ebtables -A INPUT -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_ICMPv6" --ip6-icmp-type ! echo-request -j ACCEPT
                inited=1
            fi

            if [ "$lan_restricted" = "1" ]; then
                config_get ifname "$vif" ifname
                config_get bridge "$vif" bridge
                config_get arlo "$vif" arlo
                lan_ipaddr=$(ifconfig $bridge | grep "inet addr" | awk '{print $2}'| awk -F ':' '{print $2}')
                if [ "$arlo" != 1 ]; then
                    ebtables -A INPUT -i $ifname -j "$IN_Chain"
                    ebtables -A FORWARD -i $ifname -j "$FWD_IN_Chain"
                    ebtables -A FORWARD -o $ifname -j "$FWD_OUT_Chain"
                fi
            fi
        done
    done
	
    	#wireless backhaul drop the stp packet
	if_2g=$(/bin/config get wl2g_BACKHAUL_AP)
	if_5g=$(/bin/config get wl5g_BACKHAUL_AP)

	ebtables -A FORWARD -i $if_2g -d BGA -j DROP
	ebtables -A FORWARD -o $if_2g -d BGA -j DROP
	ebtables -A FORWARD -i $if_5g -d BGA -j DROP
	ebtables -A FORWARD -o $if_5g -d BGA -j DROP

}

wl_lan_restricted_access()
{
    local product_type

    if ! eval "type ebtables" 2>>/dev/null >/dev/null; then
        echo "Please install tool ebtables first"
        return
    fi

    clear_wifi_ebtables

    [ -f "/tmp/orbi_type" ] && product_type=`/bin/cat /tmp/orbi_type`

    if [ "$product_type" = "Satellite" ]; then
        satellite_lan_restricted_access $@
    elif [ "$product_type" = "Base" ]; then
        shift 2
        base_lan_restricted_access $@
    else
        shift 2
        router_lan_restricted_access $@
    fi
}

wl_lan_restricted_access_vpn()
{
	local devices=$@
	local inited=0
	local ETH_P_IP=0x0800
	local tunsubnet
	clear_wifi_vpn_ebtables
	for device in ${devices}; do
		config_get vifs "$device" vifs
		for vif in $vifs; do
			config_get_bool lan_restricted "$vif" lan_restricted
			if [ "$lan_restricted" = "1" -a "$inited" = "0" ]; then
				if [ -n "$vpn_ifname" ] &&
				   [ -n "$(ifconfig "$vpn_ifname" 2>/dev/null)" ]; then
					tunlan_ipaddr=$(ifconfig $vpn_ifname | grep "inet addr" | awk '{print $2}'| awk -F ':' '{print $2}')
					tunnetmask=$(ifconfig $vpn_ifname | grep "inet addr" | awk '{print $4}'| awk -F ':' '{print $2}')
					calculate_subnet $tunlan_ipaddr $tunnetmask tunsubnet
				fi
				inited=1
			fi
			if [ "$lan_restricted" = "1" ]; then
				config_get ifname "$vif" ifname
				if [ -n "$tunsubnet" ]; then
					ebtables -A INPUT -i $ifname -j ALLOW_CHAIN
					ebtables -A INPUT -i $ifname -p "$ETH_P_IP" --ip-dst "$tunsubnet" -j DROP
				fi
			fi
		done
	done
	if [ -n "$tunsubnet" ]; then
		ebtables -L | grep  "$tunsubnet" > /tmp/vpn_rules
	fi
}

router_lan_restricted_access()
{
    local devices=$@
    local inited=0
    local ETH_P_ARP=0x0806
    local ETH_P_RARP=0x8035
    local ETH_P_IP=0x0800
    local ETH_P_IPv6=0x86dd
    local IPPROTO_UDP=17
    local IPPROTO_ICMPv6=58
    local DHCPS_DHCPC=67:68
    local DHCP6S_DHCP6C=546:547
    local PORT_DNS=53

    for device in ${devices}; do
        config_get vifs "$device" vifs
        for vif in $vifs; do
            config_get_bool lan_restricted "$vif" lan_restricted
            if [ "$lan_restricted" = "1" -a "$inited" = "0" ]; then
                ebtables -P FORWARD ACCEPT
                ebtables -A FORWARD -p "$ETH_P_ARP" -j ACCEPT
                ebtables -A FORWARD -p "$ETH_P_RARP" -j ACCEPT
                ebtables -A FORWARD -p "$ETH_P_IP" --ip-proto "$IPPROTO_UDP" --ip-dport "$DHCPS_DHCPC" -j ACCEPT
                ebtables -P INPUT ACCEPT
                ebtables -A INPUT -p "$ETH_P_IP" --ip-proto "$IPPROTO_UDP" --ip-dport "$DHCPS_DHCPC" -j ACCEPT
                ebtables -A INPUT -p "$ETH_P_IP" --ip-proto "$IPPROTO_UDP" --ip-dport "$PORT_DNS" -j ACCEPT
                ebtables -A INPUT -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_ICMPv6" --ip6-icmp-type ! echo-request -j ACCEPT
                ebtables -A INPUT -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_UDP" --ip6-dport "$DHCP6S_DHCP6C" -j ACCEPT
                ebtables -A INPUT -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_UDP" --ip6-dport "$PORT_DNS" -j ACCEPT

                inited=1
            fi

            if [ "$lan_restricted" = "1" ]; then
                config_get ifname "$vif" ifname
                config_get bridge "$vif" bridge
                lan_ipaddr=$(ifconfig $bridge | grep "inet addr" | awk '{print $2}'| awk -F ':' '{print $2}')
                lan_ipv6addr=$(ifconfig $bridge | grep Scope:Link | awk '{print $3}' | awk -F '/' '{print $1}')
                ebtables -A FORWARD -i $ifname -j DROP
                ebtables -A FORWARD -o $ifname -j DROP
                ebtables -A INPUT -i $ifname -p "$ETH_P_IP" --ip-dst "$lan_ipaddr" -j DROP
                ebtables -A INPUT -i $ifname -p "$ETH_P_IPv6" --ip6-dst "$lan_ipv6addr" -j DROP
            fi
        done
    done
}

clear_wifi_ebtables()
{
    local ETH_P_ARP=0x0806
    local ETH_P_RARP=0x8035
    local ETH_P_IP=0x0800
    local ETH_P_IPv6=0x86dd
    local IPPROTO_UDP=17
    local IPPROTO_ICMPv6=58
    local DHCPS_DHCPC=67:68
    local DHCP6S_DHCP6C=546:547
    local PORT_DNS=53

    if ! eval "type ebtables" 2>>/dev/null >/dev/null; then
        echo "Please install tool ebtables first"
        return
    fi
    ebtables -D INPUT -p "$ETH_P_IPv6" --ip6-proto "$IPPROTO_ICMPv6" --ip6-icmp-type ! echo-request -j ACCEPT 2>/dev/null >/dev/null
    ebtables -L | grep  "ath" > /tmp/wifi_rules
    while read loop
    do
        ebtables -D INPUT $loop 2>/dev/null >/dev/null
        ebtables -D FORWARD $loop 2>/dev/null >/dev/null
        ebtables -D OUTPUT $loop 2>/dev/null >/dev/null
    done < /tmp/wifi_rules
    rm  /tmp/wifi_rules
    del_lan_restricted_chain
}

clear_wifi_vpn_ebtables()
{
	if [ "x$(cat /tmp/vpn_rules)" != "x" ]; then
		while read loop
		do
			ebtables -D INPUT $loop 2>/dev/null >/dev/null
		done < /tmp/vpn_rules
		rm -rf /tmp/vpn_rules
	fi
}

lan_restricted_access_qcawifi()
{
    wl_lan_restricted_access $@
}

lan_restricted_access_vpn_qcawifi()
{
    wl_lan_restricted_access_vpn $@
}

satellite_lan_restricted_access()
{
    local lan_ipaddr=$1
    local netmask=$2
    shift 2
    local devices=$@
    local inited=0
    local ETH_P_IP=0x0800
    local ETH_P_IPv6=0x86dd
    local IPPROTO_UDP=17
    local DHCPS_DHCPC=67:68
    local DHCP6S_DHCP6C=546:547
    local PORT_DNS=53
    IN_Chain="GUEST_IN"
    FWD_IN_Chain="GUEST_FWD_IN"
    FWD_OUT_Chain="GUEST_FWD_OUT"

    for device in ${devices}; do
        config_get vifs "$device" vifs
        for vif in $vifs; do
            config_get_bool lan_restricted "$vif" lan_restricted
            if [ "$lan_restricted" = "1" -a "$inited" = "0" ]; then
                add_lan_restricted_chain
                ebtables -P FORWARD ACCEPT
                ebtables -P INPUT ACCEPT
                inited=1
            fi

            if [ "$lan_restricted" = "1" ]; then
                config_get ifname "$vif" ifname
                config_get bridge "$vif" bridge
                config_get arlo "$vif" arlo
                base_ip="`/bin/config get lan_gateway`"
                if [ "$arlo" != "1" ]; then
                    ebtables -A INPUT -i $ifname -j "$IN_Chain"
                    ebtables -A FORWARD -i $ifname -j "$FWD_IN_Chain"
                    ebtables -A FORWARD -o $ifname -j "$FWD_OUT_Chain"
                fi
            fi
        done
    done

    	#wireless backhaul drop the stp packet
	if_2g=$(/bin/config get wl2g_BACKHAUL_AP)
	if_5g=$(/bin/config get wl5g_BACKHAUL_AP)

	ebtables -A FORWARD -i $if_2g -d BGA -j DROP
	ebtables -A FORWARD -o $if_2g -d BGA -j DROP
	ebtables -A FORWARD -i $if_5g -d BGA -j DROP
	ebtables -A FORWARD -o $if_5g -d BGA -j DROP

}

clear_lan_restricted_access_qcawifi()
{
    clear_wifi_ebtables
}

clear_lan_restricted_access_vpn_qcawifi()
{
    clear_wifi_vpn_ebtables
}

son_get_config()
{
	config_load wireless
	local device="$1"
	config_get disabled $device disabled 0
	if [ $disabled -eq 0 ]; then
	config_get vifs $device vifs
	for vif in $vifs; do
		config_get_bool disabled "$vif" disabled 0
		[ $disabled = 0 ] || continue
		config_get backhaul "$vif" backhaul 0
		config_get mode $vif mode
		config_get ifname $vif ifname
		local macaddr="$(config_get "$device" macaddr)"
			if [ $backhaul -eq 1 ]; then
				echo " $mode $ifname $device $macaddr"  >> /var/run/son.conf
			else
				echo " nbh_$mode $ifname $device $macaddr"  >> /var/run/son.conf
			fi
	done
	fi
}
