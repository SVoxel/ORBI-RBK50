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

wpa_supplicant_setup_vif() {
	local vif="$1"
	local driver="$2"
	local key="$key"
	local options="$3"
	local freq="" crypto=""
	[ -n "$4" ] && freq="frequency=$4"

	# make sure we have the encryption type and the psk
	[ -n "$enc" ] || {
		config_get enc "$vif" encryption
	}

	enc_list=`echo "$enc" | sed "s/+/ /g"`

	for enc_var in $enc_list; do
		case "$enc_var" in
			*tkip)
				crypto="TKIP $crypto"
				;;
			*aes)
				crypto="CCMP $crypto"
				;;
			*ccmp)
				crypto="CCMP $crypto"
				;;
			*ccmp-256)
				crypto="CCMP-256 $crypto"
				;;
			*gcmp)
				crypto="GCMP $crypto"
				;;
			*gcmp-256)
				crypto="GCMP-256 $crypto"
		esac
	done

	[ -n "$key" ] || {
		config_get key "$vif" key
	}

	local net_cfg bridge
	config_get bridge "$vif" bridge
	[ -z "$bridge" ] && {
		net_cfg="$(find_net_config "$vif")"
		[ -z "$net_cfg" ] || bridge="$(bridge_interface "$net_cfg")"
		config_set "$vif" bridge "$bridge"
	}

	local mode ifname wds modestr=""
	config_get mode "$vif" mode
	config_get ifname "$vif" ifname
	config_get_bool wds "$vif" wds 0
	config_get_bool extap "$vif" extap 0

	config_get device "$vif" device
	config_get_bool qwrap_enable "$device" qwrap_enable 0

	[ -z "$bridge" ] || [ "$mode" = ap ] || [ "$mode" = sta -a $wds -eq 1 ] || \
	[ "$mode" = sta -a $extap -eq 1 ] || [ $qwrap_enable -ne 0 ] || [ "$mode" = sta ] || {
		echo "wpa_supplicant_setup_vif($ifname): Refusing to bridge $mode mode interface"
		return 1
	}
	[ "$mode" = "adhoc" ] && modestr="mode=1"

	key_mgmt='NONE'
	case "$enc" in
		*none*) ;;
		*wep*)
			key_mgmt='WEP'
			config_get key "$vif" key
			key="${key:-1}"
			case "$key" in
				[1234])
					for idx in 1 2 3 4; do
						local zidx
						zidx=$(($idx - 1))
						config_get ckey "$vif" "key${idx}"
						[ -n "$ckey" ] && \
							append "wep_key${zidx}" "wep_key${zidx}=$(prepare_key_wep "$ckey")"
					done
					wep_tx_keyidx="wep_tx_keyidx=$((key - 1))"
				;;
				*)
					wep_key0="wep_key0=$(prepare_key_wep "$key")"
					wep_tx_keyidx="wep_tx_keyidx=0"
				;;
			esac
			case "$enc" in
				*mixed*)
					wep_auth_alg='auth_alg=OPEN SHARED'
				;;
				*shared*)
					wep_auth_alg='auth_alg=SHARED'
				;;
				*open*)
					wep_auth_alg='auth_alg=OPEN'
				;;
			esac
		;;
		*psk*)
			key_mgmt='WPA-PSK'
			# if you want to use PSK with a non-nl80211 driver you
			# have to use WPA-NONE and wext driver for wpa_s
			[ "$mode" = "adhoc" -a "$driver" != "nl80211" ] && {
				key_mgmt='WPA-NONE'
				driver='wext'
			}
			if [ ${#key} -eq 64 ]; then
				passphrase="psk=${key}"
			else
				passphrase="psk=\"${key}\""
			fi

			[ -n "$crypto" ] || crypto="CCMP"
			pairwise="pairwise=$crypto"

			case "$enc" in
				*mixed*)
					proto='proto=RSN WPA'
				;;
				*psk2*)
					proto='proto=RSN'
					config_get ieee80211w "$vif" ieee80211w
				;;
				*psk*)
					proto='proto=WPA'
				;;
			esac
		;;
		*wpa*|*8021x*)
			proto='proto=WPA2'
			key_mgmt='WPA-EAP'
			config_get ieee80211w "$vif" ieee80211w
			config_get ca_cert "$vif" ca_cert
			config_get eap_type "$vif" eap_type
			ca_cert=${ca_cert:+"ca_cert=\"$ca_cert\""}

			[ -n "$crypto" ] || crypto="CCMP"
			pairwise="pairwise=$crypto"

			case "$eap_type" in
				tls)
					config_get identity "$vif" identity
					config_get client_cert "$vif" client_cert
					config_get priv_key "$vif" priv_key
					config_get priv_key_pwd "$vif" priv_key_pwd
					identity="identity=\"$identity\""
					client_cert="client_cert=\"$client_cert\""
					priv_key="private_key=\"$priv_key\""
					priv_key_pwd="private_key_passwd=\"$priv_key_pwd\""
				;;
				peap|ttls)
					config_get auth "$vif" auth
					config_get identity "$vif" identity
					config_get password "$vif" password
					phase2="phase2=\"auth=${auth:-MSCHAPV2}\""
					identity="identity=\"$identity\""
					password="password=\"$password\""
				;;
			esac
			eap_type="eap=$(echo $eap_type | tr 'a-z' 'A-Z')"
		;;
	esac

	keymgmt='NONE'

	# Allow SHA256
	case "$enc" in
		*wpa*|*8021x*) keymgmt=EAP;;
		*psk*) keymgmt=PSK;;
	esac

	case "$ieee80211w" in
		0)
			key_mgmt="WPA-${keymgmt}"
		;;
		1)
			key_mgmt="WPA-${keymgmt} WPA-${keymgmt}-SHA256"
		;;
		2)
			key_mgmt="WPA-${keymgmt}-SHA256"
		;;
	esac

	[ -n "$ieee80211w" ] && ieee80211w="ieee80211w=$ieee80211w"
	case "$pairwise" in
		*CCMP-256*) group="group=CCMP-256 GCMP-256 GCMP CCMP TKIP";;
		*GCMP-256*) group="group=GCMP-256 GCMP CCMP TKIP";;
		*GCMP*) group="group=GCMP CCMP TKIP";;
		*CCMP*) group="group=CCMP TKIP";;
		*TKIP*) group="group=TKIP";;
	esac

	config_get ifname "$vif" ifname
	config_get bridge "$vif" bridge
	config_get ssid "$vif" ssid
	config_get bssid "$vif" bssid
	bssid=${bssid:+"bssid=$bssid"}
	config_get backhaul "$vif" backhaul
	[ -n "$backhaul" ] && backhaul_setting="backhaul_if=$backhaul"

	config_get_bool wps_pbc "$vif" wps_pbc 0

	config_get config_methods "$vif" wps_config
	[ "$wps_pbc" -gt 0 ] && append config_methods push_button

	[ -n "$config_methods" ] && {
		wps_cred="wps_cred_processing=2"
		wps_config_methods="config_methods=$config_methods"
		update_config="update_config=1"
		# fix the overlap session of WPS PBC for two STA vifs
		macaddr=$(cat /sys/class/net/${bridge}/address)
		uuid=$(echo "$macaddr" | sed 's/://g')
		[ -n "$uuid" ] && {
			uuid_config="uuid=87654321-9abc-def0-1234-$uuid"
		}
	}

	local ctrl_interface wait_for_wrap=""

	if [ $qwrap_enable -ne 0 ]; then
		ctrl_interface="/var/run/wpa_supplicant"
		if [ -f "/tmp/qwrap_conf_filename-$ifname.conf" ]; then
			rm -rf /tmp/qwrap_conf_filename-$ifname.conf
		fi
		echo -e "/var/run/wpa_supplicant-$ifname.conf \c\h" > /tmp/qwrap_conf_filename-$ifname.conf
		wait_for_wrap="-W"
	fi

	ctrl_interface="/var/run/wpa_supplicant-$ifname"

	rm -rf $ctrl_interface
	rm -f /var/run/wpa_supplicant-$ifname.conf
	cat > /var/run/wpa_supplicant-$ifname.conf <<EOF
ctrl_interface=$ctrl_interface
$wps_config_methods
$wps_cred
$update_config
$uuid_config
$backhaul_setting
network={
	$modestr
	scan_ssid=1
	ssid="$ssid"
	$bssid
	key_mgmt=$key_mgmt
	$proto
	$freq
	$ieee80211w
	$passphrase
	$pairwise
	$group
	$eap_type
	$ca_cert
	$client_cert
	$priv_key
	$priv_key_pwd
	$phase2
	$identity
	$password
	$wep_key0
	$wep_key1
	$wep_key2
	$wep_key3
	$wep_tx_keyidx
	$wep_auth_alg
}
EOF
	[ -z "$proto" -a "$key_mgmt" != "NONE" ] || {\
                # If there is a change in path of wpa_supplicant-$ifname.lock file, please make the path
                # change also in wrapd_api.c file.
		[ -f "/var/run/wpa_supplicant-$ifname.lock" ] &&
			rm /var/run/wpa_supplicant-$ifname.lock
		wpa_cli -g /var/run/wpa_supplicantglobal interface_add  $ifname /var/run/wpa_supplicant-$ifname.conf athr /var/run/wpa_supplicant-$ifname "" $bridge
		touch /var/run/wpa_supplicant-$ifname.lock
    }
}

#
# Decision-making function for whether wpa_supplicant global process should be
# restarted or not.
#
# Parameters:
#     $1: wpa_supplicant debug options
#
# Return value:
#     0: wpa_supplicant global process should be restarted
#     1: no need to restart wpa_supplicant global process
#
global_qca_wpa_supplicant_should_restart() {
	local wpa_supplicant_debug_opt="$1"

	local wpa_supplicant_pid
	local wpa_supplicant_global_pid=$( \
			cat /var/run/wpa_supplicant-global.pid 2> /dev/null)

	#
	# Is wpa_supplicant whose PID is in /var/run/wpa_supplicant-global.pid
	# still alive?
	#
	local wpa_supplicant_global_exist=""

	local num_of_wpa_supplicant_inst=0

	if [ "$wpa_supplicant_debug_opt" ]; then
		#
		# Always restart wpa_supplicant global process when we want to
		# switch to debug mode
		#
		return 0
	fi

	for wpa_supplicant_pid in $(pidof wpa_supplicant); do
		if [ "$wpa_supplicant_pid" = \
		     "$wpa_supplicant_global_pid" ]; then
			wpa_supplicant_global_exist=1
		fi

		num_of_wpa_supplicant_inst=$((num_of_wpa_supplicant_inst + 1))
		if [ "$num_of_wpa_supplicant_inst" -ge 2 ]; then
			#
			# Duplicated wpa_supplicant global processes are
			# found!
			#
			# Conflicts may happen in
			# /var/run/wpa_supplicantglobal, and thus
			# wpa_supplicant global process must be restarted to
			# recover from buggy status.
			#
			return 0;
		fi
	done

	if [ ! "$wpa_supplicant_global_exist" ]; then
		return 0
	fi

	return 1
}

#
# Restart wpa_supplicant global process only when there is no existing one in
# normal mode.
#
global_qca_wpa_supplicant_restart() {
	local wpa_supplicant_debug_level
	local wpa_supplicant_debug_opt

	local wpa_supplicant_pid

	config_get wpa_supplicant_debug_level qcawifi \
			wpa_supplicant_debug_level
	case "$wpa_supplicant_debug_level" in
		1)
			wpa_supplicant_debug_opt="-d"
			;;
		2)
			wpa_supplicant_debug_opt="-dd"
			;;
		3)
			wpa_supplicant_debug_opt="-ddd"
			;;
		4)
			wpa_supplicant_debug_opt="-dddd"
			;;
		*)
			wpa_supplicant_debug_opt=""
			;;
	esac

	## Modified from /etc/init.d/qca-wpa-supplicant

	if ! global_qca_wpa_supplicant_should_restart \
			$wpa_supplicant_debug_opt; then
		return
	fi

	#
	# wpa_supplicant without "-B" option can only be killed by this
	# method.
	#
	for wpa_supplicant_pid in $(pidof wpa_supplicant); do
		kill $wpa_supplicant_pid &> /dev/null
	done

	if [ -e "/var/run/wpa_supplicant-global.pid" ]; then
		rm /var/run/wpa_supplicant-global.pid &> /dev/null
	fi

	if [ -n "$wpa_supplicant_debug_opt" ]; then
		#
		# When "-B" is not passed, no PID file will be created even
		# when "-P <file>" is specified.
		#
		wpa_supplicant -g /var/run/wpa_supplicantglobal \
				$wpa_supplicant_debug_opt &
	else
		wpa_supplicant -g /var/run/wpa_supplicantglobal -B \
				-P /var/run/wpa_supplicant-global.pid
	fi
}
