. /lib/dni_platform/dni_global.config

flash_type=`cat /flash_type`

dni_find_mtd_index() {
        local PART="$(grep "\"$1\"" /proc/mtd | awk -F: '{print $1}')"
        local INDEX="${PART##mtd}"

        echo ${INDEX}
}

dni_find_mtd_part() {
        local INDEX=$(dni_find_mtd_index "$1")
        local PREFIX=/dev/mtdblock

        [ -d /dev/mtdblock ] && PREFIX=/dev/mtdblock/
        echo "${INDEX:+$PREFIX$INDEX}"
}

dni_find_mmc_part() {
        local DEVNAME PARTNAME

        if grep -q "$1" /proc/mtd; then
                echo "" && return 0
        fi

        for DEVNAME in /sys/block/mmcblk0/mmcblk*p*; do
                PARTNAME=$(grep PARTNAME ${DEVNAME}/uevent | cut -f2 -d'=')
                [ "$PARTNAME" = "$1" ] && echo "/dev/$(basename $DEVNAME)" && return 0
        done
}

dni_artmtd_mtd_detect() {
	local mtdblock=$(dni_find_mtd_part ARTMTD)
	
	if [ -z "$mtdblock" ]; then
		# read from mmc
		mtdblock=$(dni_find_mmc_part ARTMTD)
	fi

	if [ -n "$mtdblock" ]; then
		echo -n "$mtdblock" > /tmp/artmtd_dev_id
	fi
}


dni_language_mtd_detect() {
	local mtdblock=$(dni_find_mtd_part language)
	
	if [ -z "$mtdblock" ]; then
		# read from mmc
		mtdblock=$(dni_find_mmc_part language)
	fi

	if [ -n "$mtdblock" ]; then
		echo -n "$mtdblock" > /tmp/language_dev_id
	fi
}

dni_board_data_init() {
	#read model id from flash to /tmp/board_model_id
	/sbin/artmtd -r board_model_id | cut -f 2 -d ":" > /tmp/board_model_id

	#read Orbi serial board_data
	/sbin/artmtd -r board_data | awk '{print $3}' > /tmp/board_data

	#read region from flash to /tmp/firmware_region
	/sbin/artmtd -r region
	
	#read wpspin from flash to /tmp/wpspin
	/sbin/artmtd -r wpspin

	#read serial number from flash to /tmp/Seria_Number
	/sbin/artmtd -r sn

	#read wan mac from flash to /tmp/wan_mac
	/sbin/artmtd -r mac

	#read hw_revision from flash to /tmp/hw_revision
	/sbin/artmtd -r hw_revision
}

dni_board_data_detect() {
	#Create /tmp/orbi_type to indicate that It is Orbi Base or Satellites.
	model_prefix=`cat /tmp/board_model_id |cut -b3`
	[ "$model_prefix" = "R" ] && echo "Base" > /tmp/orbi_type
	[ "$model_prefix" = "S" ] && echo "Satellite" > /tmp/orbi_type

	#read Orbi serial board_data and show its type to /tmp/orbi_project
	dev_type=`cat /tmp/board_data |cut -b3-4`
	if [ "$dev_type" = "01" ] || [ "$dev_type" = "02" ]; then
		echo "Desktop" > /tmp/orbi_project
	elif [ "$dev_type" = "04" ] || [ "$dev_type" = "05" ]; then
		echo "Orbimini" > /tmp/orbi_project
	elif [ "$dev_type" = "06" ] || [ "$dev_type" = "07" ]; then
		echo "Orbipro" > /tmp/orbi_project
	fi

	#Since early Mini had wrong board_data, correct the project by model_name
	model_name=`cat /tmp/board_model_id`
	if [ "x$model_name" = "xRBR30" -o "x$model_name" = "xRBS30" -o "x$model_name" = "xRBR40" -o "x$model_name" = "xRBS40"  ];then
		echo "Orbimini" > /tmp/orbi_project
	fi
}

dni_iqos_defconfig() {
	# Load Default QoS rules if needed.
	qos_dft="$(/bin/config get qos_list_default)"
	if [ "$qos_dft" = "1" ]; then
		count=1
		while :
		do
			qos_rule="$(/bin/config get qos_dft_list$count)"
			if [ "x$qos_rule" = "x" ]; then
				break;
			fi
			/bin/config set qos_list$count="$qos_rule"

			count=`expr $count + 1`
		done

		count=`expr $count - 1`
		echo "$count QoS default rules are Loaded!"

		/bin/config set qos_list_default="0"
		/bin/config commit
	fi
}

dni_preset_key_defconfig() {
        # Wireless security pre-set
        id_dft="$(/bin/config get default_ssphrase)"
        if [ "$id_dft" = "1" ]; then
                /sbin/artmtd -r fronthaul_ssid
                /sbin/artmtd -r fronthaul_passphrase
                if [ -s /tmp/ssid-setted ] && [ -s /tmp/passphrase-setted ]; then
                        id_set=$(awk '{print $1}' /tmp/ssid-setted)
                        ps_set=$(awk '{print $1}' /tmp/passphrase-setted)

                        /bin/config set wl_ssid="$id_set"
                        /bin/config set wl_wpa2_psk="$ps_set"
                        /bin/config set wl_sectype="4"
                        /bin/config set wps_status="5"
			/bin/config set wla_ssid="$id_set"
			/bin/config set wla_wpa2_psk="$ps_set"
			/bin/config set wla_sectype="4"
			/bin/config set wla_wps_status="5"

                        # set SSID of guest netwroks according to Home Router GUI Redesign Specification Rev10 section 6.3
			if [ "$(cat /tmp/orbi_project)" = "Orbpro" ]; then
			/bin/config set wlg2_ssid="$id_set-2"
			/bin/config set wla2_ssid="$id_set-2"
			/bin/config set wlg1_ssid="$id_set-GUEST"
			/bin/config set wla1_ssid="$id_set-GUEST"
			else
                        /bin/config set wlg1_ssid="NETGEAR-Guest"
                        /bin/config set wla1_ssid="NETGEAR-Guest"
			fi
                fi
                /bin/rm /tmp/ssid-setted
                /bin/rm /tmp/passphrase-setted
                /sbin/artmtd -r backhaul_ssid
                /sbin/artmtd -r backhaul_passphrase
                if [ -s /tmp/ssid-setted ] && [ -s /tmp/passphrase-setted ]; then
                        id_set=$(awk '{print $1}' /tmp/ssid-setted)
                        ps_set=$(awk '{print $1}' /tmp/passphrase-setted)

                        /bin/config set wlg_ap_bh_ssid="$id_set"
                        /bin/config set wlg_sta_ssid="$id_set"
                        /bin/config set wla_2nd_sta_ssid="$id_set"
                        /bin/config set wla_2nd_ap_bh_ssid="$id_set"
                        /bin/config set wlg_ap_bh_wpa2_psk="$ps_set"
                        /bin/config set wlg_sta_wpa2_psk="$ps_set"
                        /bin/config set wla_2nd_sta_wpa2_psk="$ps_set"
                        /bin/config set wla_2nd_ap_bh_wpa2_psk="$ps_set"
                        /bin/config set wlg_ap_bh_sectype="4"
                        /bin/config set wlg_sta_sectype="4"
                        /bin/config set wla_2nd_sta_sectype="4"
                        /bin/config set wla_2nd_ap_bh_sectype="4"
                fi
                /bin/config set default_ssphrase="0"
		/bin/config commit
        fi
}

dni_wifi_defconfig() {
	dni_preset_key_defconfig

        if [ "$(/bin/config get overwrite_14010)" = "0" ]; then
                echo "not need do overwrite lbd"
        else
                /bin/config set lbd_PHYBasedPrioritization="1"
                /bin/config set lbd_RSSIMeasureSamples_W2="2"
                /bin/config set lbd_RSSIMeasureSamples_W5="2"
                /bin/config set lbd_BcnrptPassiveDuration="110"
                /bin/config set lbd_PhyRateScalingForAirtime="90"
                /bin/config set lbd_BTMAssociationTime="5"
                /bin/config set lbd_MinTxRateIncreaseThreshold="20"
                /bin/config set lbd_AuthRejMax="2"
                /bin/config set lbd_TSteering="15"
                /bin/config set lbd_LowRSSIAPSteerThreshold_CAP_W2="35"
                /bin/config set lbd_LowRSSIAPSteerThreshold_CAP_W5="20"
                /bin/config set lbd_LowRSSIAPSteerThreshold_RE_W2="35"
                /bin/config set lbd_LowRSSIAPSteerThreshold_RE_W5="20"
                /bin/config set lbd_TxRateXingThreshold_UG="20000"
                /bin/config set lbd_MUReportPeriod="15"
                /bin/config set lbd_LoadBalancingAllowedMaxPeriod="10"
                /bin/config set lbd_NormalInactTimeout="5"
                /bin/config set lbd_OverloadInactTimeout="5"
                /bin/config set lbd_MaxBTMUnfriendly="120"
                /bin/config set lbd_MaxBTMActiveUnfriendly="120"
                /bin/config set lbd_MaxSteeringUnfriendly="86400"
		/bin/config set lbd_11kProhibitTimeShort="15"
		/bin/config set lbd_11kProhibitTimeLong="60"
                /bin/config set lbd_BTMSteeringProhibitShortTime="15"
                /bin/config set lbd_BTMUnfriendlyTime="30"
                /bin/config set lbd_SteeringProhibitTime="120"
                /bin/config set lbd_RSSISteeringPoint_UG="15"
                /bin/config set lbd_RateRSSIXingThreshold_UG="20"
                /bin/config set lbd_MUOverloadThreshold_W2="80"
                /bin/config set lbd_MUOverloadThreshold_W5="99"
                /bin/config set lbd_MUSafetyThreshold_W2="50"
                /bin/config set lbd_MUSafetyThreshold_W5="90"
                /bin/config set lbd_APSteerToRootMinRSSIIncThreshold="10"
                /bin/config set lbd_DownlinkRSSIThreshold_W5="-70"
                /bin/config set overwrite_14010="0"
                /bin/config commit
        fi

        if [ "$(/bin/config get overwrite_20013)" = "0" ]; then
                echo "Also not need do overwrite lbd"
        else
                /bin/config set lbd_PHYBasedPrioritization="1"
                /bin/config set lbd_RSSIMeasureSamples_W2="2"
                /bin/config set lbd_RSSIMeasureSamples_W5="2"
                /bin/config set lbd_BcnrptPassiveDuration="110"
                /bin/config set lbd_PhyRateScalingForAirtime="90"
                /bin/config set lbd_BTMAssociationTime="5"
                /bin/config set lbd_MinTxRateIncreaseThreshold="20"
                /bin/config set lbd_AuthRejMax="2"
                /bin/config set lbd_TSteering="15"
                /bin/config set lbd_11kProhibitTimeLong="60"
                /bin/config set overwrite_20013="0"
                /bin/config commit
        fi
}

dni_region_defconfig() {
                region="$(/sbin/artmtd -r region | grep REGION | awk '{print $2}')"

                #when region setting on flash's board data area is RU
                if [ "$region" = "RU" ];then
                        /bin/config set wla_country="19"
                        /bin/config set wl_country="19"
                        /bin/config set ntp_server="GMT-4"
                        /bin/config set ntpserver_select="GMT-4"
                        /bin/config set ntp_hidden_select="27"
                        /bin/config set time_zone="GMT-4"
                        /bin/config set email_ntpserver="GMT-4"
                        /bin/config set region_flag="DISABLED"
                        /bin/config set wla_2nd_hidden_channel="157"
                fi

                #when region setting on flash's board data area is GR
                if [ "$region" = "GR" ];then
                        /bin/config set wla_country="4"
                        /bin/config set wl_country="4"
                        /bin/config set ntp_server="GMT-1"
                        /bin/config set ntpserver_select="GMT-1"
                        /bin/config set ntp_hidden_select="19"
                        /bin/config set time_zone="GMT-1"
                        /bin/config set email_ntpserver="GMT-1"
                fi

                #when region setting on flash's board data area is PR
                if [ "$region" = "PR" ];then
                        /bin/config set wla_country="11"
                        /bin/config set wl_country="11"
                        /bin/config set ntp_server="GMT-8"
                        /bin/config set ntpserver_select="GMT-8"
                        /bin/config set ntp_hidden_select="33"
                        /bin/config set time_zone="GMT-8"
                        /bin/config set email_ntpserver="GMT-8"
                        /bin/config set wla_2nd_hidden_channel="157"
                fi

                #when region setting on flash's board data area is BZ
                if [ "$region" = "BZ" ];then
                        /bin/config set wla_country="9"
                        /bin/config set wl_country="9"
                        /bin/config set ntp_server="GMT+3"
                        /bin/config set ntpserver_select="GMT+3"
                        /bin/config set ntp_hidden_select="14"
                        /bin/config set time_zone="GMT+3"
                        /bin/config set email_ntpserver="GMT+3"
                fi

                #when region setting on flash's board data area is IN
                if [ "$region" = "IN" ];then
                        /bin/config set wla_country="12"
                        /bin/config set wl_country="12"
                        /bin/config set ntp_server="GMT-5:30"
                        /bin/config set ntpserver_select="GMT-5:30"
                        /bin/config set ntp_hidden_select="30"
                        /bin/config set time_zone="GMT-5:30"
                        /bin/config set email_ntpserver="GMT-5:30"
                        /bin/config set wla_2nd_hidden_channel="157"
                fi

                #when region setting on flash's board data area is KO
                if [ "$region" = "KO" ];then
                        /bin/config set wla_country="7"
                        /bin/config set wl_country="7"
                        /bin/config set ntp_server="GMT-9"
                        /bin/config set ntpserver_select="GMT-9"
                        /bin/config set ntp_hidden_select="35"
                        /bin/config set time_zone="GMT-9"
                        /bin/config set email_ntpserver="GMT-9"
                fi

                #when region setting on flash's board data area is JP
                if [ "$region" = "JP" ];then
                        /bin/config set wla_country="6"
                        /bin/config set wl_country="6"
                        /bin/config set ntp_server="GMT-9"
                        /bin/config set ntpserver_select="GMT-9"
                        /bin/config set ntp_hidden_select="35"
                        /bin/config set time_zone="GMT-9"
                        /bin/config set email_ntpserver="GMT-9"
                        /bin/config set region_flag="DISABLED"
                fi

                #when region setting on flash's board data area is NA
                if [ "$region" = "NA" -o "$region" = "US" ];then
                        /bin/config set wla_country="10"
                        /bin/config set wl_country="10"
                        /bin/config set wla_hidden_channel="48"
                        /bin/config set wla_2nd_hidden_channel="157"
                        /bin/config set region_flag="DISABLED"
                        /bin/config set ntp_server="GMT+8"
                        /bin/config set ntpserver_select="GMT+8"
                        /bin/config set ntp_hidden_select="4"
                        /bin/config set time_zone="GMT+8"
                        /bin/config set email_ntpserver="GMT+8"
                fi

                #when region setting on flash's board data area is AU
                if [ "$region" = "AU" ];then
                        /bin/config set wla_country="2"
                        /bin/config set wl_country="2"
                        /bin/config set ntp_server="GMT-10"
                        /bin/config set ntpserver_select="GMT-10"
                        /bin/config set ntp_hidden_select="37"
                        /bin/config set time_zone="GMT-10"
                        /bin/config set email_ntpserver="GMT-10"
                        /bin/config set wla_2nd_hidden_channel="157"
                fi
                #when region setting on flash's board data area is CA
                if [ "$region" = "CA" ];then
                        /bin/config set wla_country="3"
                        /bin/config set wl_country="3"
                        /bin/config set wla_hidden_channel="48"
                        /bin/config set wla_2nd_hidden_channel="157"
                        /bin/config set ntp_server="GMT+5"
                        /bin/config set ntpserver_select="GMT+5"
                        /bin/config set ntp_hidden_select="10"
                        /bin/config set time_zone="GMT+5"
                        /bin/config set email_ntpserver="GMT+5"
                fi
				#when region setting on flash's board data area is MX
				if [ "$region" = "MX" ];then
					/bin/config set wla_country="8"
					/bin/config set wl_country="8"
					/bin/config set wla_hidden_channel="48"
					/bin/config set wla_2nd_hidden_channel="157"
					/bin/config set ntp_server="GMT-6"
					/bin/config set ntpserver_select="GMT-6"
					/bin/config set ntp_hidden_select="8"
					/bin/config set time_zone="GMT-6"
					/bin/config set email_ntpserver="GMT-6"
				fi
}

dni_board_defconfig() {
	dni_iqos_defconfig

        #if restore the factory default read region from flash
        if [ "x$(/bin/config get board_region_default)" = "x1" ]; then
		dni_region_defconfig

                /bin/config set board_region_default="0"
                /bin/config commit
        fi

        # MTP need set dakota_2.4G channel 6, dakota_5G channel 44, casecade_5G channel 157.
        if [ "$(/bin/config get factory_mode)" = "1" ]; then
                /bin/config set wl_hidden_channel="6"
                /bin/config set wla_hidden_channel="44"
        fi

	dni_wifi_defconfig

	if [ "$(/bin/config get overwrite_20070615)" = "0" ]; then
		echo "Also not need do overwrite lbd"
	else
		/bin/config set rssi_prefer_2g_bh="-82"
		/bin/config set lbd_RSSISteeringPoint_UG="15"
		/bin/config set overwrite_20070615="0"
		/bin/config commit
	fi

	if [ "$(/bin/config get overwrite_20062)" = "0" ]; then
		echo "Also not need do overwrite lbd"
	else
		/bin/config set wl_super_wifi="1"
		/bin/config set wla_super_wifi="1"
		/bin/config set wla_2nd_super_wifi="1"
		/bin/config set repacd_MaxMeasuringStateAttempts="30"
		/bin/config set repacd_RateScalingFactor="85"
		/bin/config set 5GBackhaulEvalTimeLong="1800"
		/bin/config set 5GBackhaulEvalTimeShort="330"
		/bin/config set hyd_LoadBalancingSeamless="0"
		/bin/config set overwrite_20062="0"
		/bin/config commit
	fi
	if [ "$(/bin/config get overwrite_221100)" = "0" ]; then
		echo "Also not need do overwrite DFS"
	else
		/bin/config set wla_2nd_enhance_dfs=0
		/bin/config set overwrite_221100=0
		/bin/config commit
	fi

        #For debug page pre setting
        local wifi_debug_option=$(/bin/config get wifi_debug_option)
        local wifi_debug_max_log_size=$(/bin/config get wifi_debug_max_log_size)
        if [  "$wifi_debug_option" = "" ];then
                /bin/config set wifi_debug_option="0x00112233"
        else
                /bin/config set wifi_debug_option=$wifi_debug_option
        fi

        if [  "$wifi_debug_max_log_size" = "" ];then
                /bin/config set wifi_debug_max_log_size="5"
        else
                /bin/config set wifi_debug_max_log_size=$wifi_debug_max_log_size
        fi
}

dni_generate_board_conf() {

	local board_model_id="$(cat /tmp/board_model_id)"
	local orbi_project_id="$(cat /tmp/orbi_project)"

	echo "$board_model_id" > /module_name
	echo "$board_model_id" > /hardware_version
	if [ "x$($CONFIG get board_region_default)" = "x1" ]; then
		/bin/config set wan_hostname="$board_model_id"
		/bin/config set netbiosname="$board_model_id"
		/bin/config set upnp_serverName="ReadyDLNA: $board_model_id"

	fi
	/bin/config set bridge_netbiosname="$board_model_id"
	/bin/config set ap_netbiosname="$board_model_id"
	/bin/config set device_name="$board_model_id"

	#When board_model_id on HW board data is Base
	if [ "$(cat /tmp/orbi_type)" = "Base" ];then
		/bin/rm /sbin/udhcpd-ext
		/bin/rm /sbin/udhcpc-ext
		/bin/rm /usr/share/udhcpc/default.script-ext
		/bin/rm /usr/share/udhcpc/default.script.ap-ext
		/bin/rm /usr/sbin/net-scan-ext
		/bin/rm /usr/sbin/dev-scan-ext
		/bin/rm /usr/sbin/ntpclient-ext
		/bin/rm /etc/init.d/ntpclient-ext
		/bin/rm /etc/init.d/net-lan-ext
		/bin/rm /sbin/ap-led
		/bin/rm /usr/sbin/led-control.sh
	#When board_model_id on HW board data area is Satellite
	else
		echo 1 > /proc/sys/net/ipv4/is_satelite
		if [ "x$($CONFIG get repacd_Daisy_Chain_Enable)" = "x0" ]; then
			/bin/config set wlg_operation_mode=7
			/bin/config set wla_2nd_operation_mode=5
		else
			/bin/config set wlg_operation_mode=8
			/bin/config set wla_2nd_operation_mode=6
		fi
		/bin/mv /sbin/udhcpd-ext /sbin/udhcpd
		/bin/mv /sbin/udhcpc-ext /sbin/udhcpc
		/bin/mv /usr/share/udhcpc/default.script-ext /usr/share/udhcpc/default.script
		/bin/mv /usr/share/udhcpc/default.script.ap-ext /usr/share/udhcpc/default.script.ap
		/bin/mv /usr/sbin/net-scan-ext /usr/sbin/net-scan
		/bin/mv /usr/sbin/dev-scan-ext /usr/sbin/dev-scan
		/bin/mv /usr/sbin/ntpclient-ext /usr/sbin/ntpclient
		/bin/mv /etc/init.d/ntpclient-ext /etc/init.d/ntpclient
		/bin/mv /etc/init.d/net-lan-ext /etc/init.d/net-lan
		/bin/rm /etc/init.d/net-wan
		/bin/rm /etc/init.d/soap_agent
		/bin/rm /usr/sbin/soap_agent
		/bin/rm /etc/init.d/dnsmasq
		/bin/rm /usr/sbin/dnsmasq
		/bin/rm /sbin/ping-netgear
		/bin/rm /usr/sbin/net-wall
		/bin/rm /etc/init.d/openvpn
	fi
	# generate conf for miniupnp.
	/bin/config set miniupnp_devupc="606449084528"
	/bin/config set miniupnp_friendlyname="NETGEAR RBR50 Orbi Router"
	/bin/config set miniupnp_modelname="NETGEAR Orbi Desktop AC3000 Router"
	/bin/config set miniupnp_modelnumber=$board_model_id
	/bin/config set miniupnp_modelurl="http://www.netgear.com/orbi"
	/bin/config set miniupnp_modeldescription="http://www.netgear.com/home/products/wirelessrouters"
	/bin/config set miniupnp_pnpx_hwid="VEN_01f2&amp;DEV_002b&amp;REV_01 VEN_01f2&amp;DEV_8000&amp;SUBSYS_01&amp;REV_01 VEN_01f2&amp;DEV_8000&amp;REV_01 VEN_0033&amp;DEV_0008&amp;REV_01"
}

project_boot_stage0() {
	dni_artmtd_mtd_detect
	dni_language_mtd_detect

	if [ "x$flash_type" = "xEMMC" ];then 
		#check bootcmd partition, if dirty, erase it and reboot
		envpart="/dev/mmcblk0p8"
		firstline=`hexdump $envpart | head -1`
		byte1=`echo $firstline | awk '{print $6}'`
		byte2=`echo $firstline | awk '{print $7}'`
		byte3=`echo $firstline | awk '{print $8}'`
		byte4=`echo $firstline | awk '{print $9}'`

		echo "Checking env partition first ..."
		if [ "x$byte1" != "x0000" -o "x$byte2" != "x0000" -o "x$byte3" != "x0000" -o "x$byte4" != "x0000" ];then
			echo "Env partition is not clean, erase and reboot now ..."
			dd if=/dev/zero of=$envpart
		reboot
		fi
	else
		echo "Checking env partition first ..."
		envpart=$(part_dev uboot.env)
		# only checking two bytes should be enough
		nanddump -p -l 2 /dev/mtd8 2>/dev/null  | head -n 1 | grep -q ": ff ff"
		[ "$?" != "0" ]  && {
			echo "Env partition is not clean, erase and reboot now ..."
			flash_erase $envpart 0 0
			reboot
		}
	
		/sbin/artmtd -r board_model_id | cut -f 2 -d ":" > /tmp/board_model_id
		model_name=`cat /tmp/board_model_id`
	
		#check bootcmd partition, if dirty, erase it and reboot
		echo "Checking env partition first ..."
		if [ "x$model_name" = "xRBR50" -o "x$model_name" = "xRBS50" ]; then
			envpart=$(part_dev uboot.env)
			# only checking two bytes should be enough
			nanddump -p -l 2 /dev/mtd8 2>/dev/null  | head -n 1 | grep -q ": ff ff"
			[ "$?" != "0" ]  && {
				echo "Env partition is not clean, erase and reboot now ..."
				flash_erase $envpart 0 0
				reboot
			}
		elif [ "x$model_name" = "xRBR40" -o "x$model_name" = "xRBS40" ]; then
			envpart="/dev/mmcblk0p8"
			firstline=`hexdump $envpart | head -1`
			byte1=`echo $firstline | awk '{print $6}'`
			byte2=`echo $firstline | awk '{print $7}'`
			byte3=`echo $firstline | awk '{print $8}'`
			byte4=`echo $firstline | awk '{print $9}'`
	
			if [ "x$byte1" != "x0000" -o "x$byte2" != "x0000" -o "x$byte3" != "x0000" -o "x$byte4" != "x0000" ];then
				echo "Env partition is not clean, erase and reboot now ..."
				dd if=/dev/zero of=$envpart
				reboot
			fi
		fi
	fi

	/sbin/init-gpio
	touch /tmp/led_time
	echo 0 > /tmp/led_time && sleep 90 && echo 1 > /tmp/led_time &

	mkdir -p /tmp/etc
	mkdir -p /tmp/samba
	mkdir -p /tmp/mnt

	klogd
	ifconfig lo up

	dni_board_data_init
	dni_board_data_detect

	/bin/datalib $(cat /tmp/orbi_type)

	local temp_repacd_Daisy_Forced=$(/bin/config get repacd_Daisy_Chain_Enable_Forced)
	if [ "x$temp_repacd_Daisy_Forced" != "x1" ]; then
		/bin/config set repacd_Daisy_Chain_Enable=1
		/bin/config set repacd_Daisy_Chain_Enable_Forced=1
		/bin/config commit
	fi
	
	# generate conf for RBR50/RBS50
	dni_generate_board_conf

	echo "$(/bin/config get netbiosname)" > /proc/sys/kernel/hostname
	/sbin/printhosts

	# generate the firewall rule file after loading the configuration data.
	/usr/sbin/net-wall rule

	factory_mode=`/bin/config get factory_mode`
	tt3_mode=`/bin/config get factory_tt3`
	#Keep solid red in factory_tt3 mode
	if [ "x$factory_mode" = "x1" -a "x$tt3_mode" = "x1" ];then
		echo "Keep LED solid red in factory TT3 mode" >/dev/console
		/sbin/led_ring stop
		/sbin/ledcontrol -n all -c red -s on
	fi

	if [ ! -s /etc/config/nowan  -o ! -s /etc/config/lanwan ]; then
		cp /rom/etc/config/* /etc/config
	fi

	grep -q "dev\.nss\.general\.redirect=1" /etc/sysctl.d/qca-nss-ecm.conf || cp /rom/etc/sysctl.d/qca-nss-ecm.conf /etc/sysctl.d/qca-nss-ecm.conf

	/etc/init.d/watchdog start &

	/sbin/kmodloader

	/etc/init.d/switch.init boot

	# start SIP ALG module
	/sbin/cmd_sipalg

	insmod /lib/ufsd/ufsd.ko

	# indicate the system first boot for first log
	/bin/config set syslog_up_first=0
	
	if [ "$(/bin/config get dgc_flash_type)" != "EMMC" ];then
		if [ "x$(ubinfo -a | grep vol_rae)" != "x" ];then
			rae_size=$(ubinfo -a | grep -B5 vol_rae | grep Size | awk -F ' ' '{print $2}')
			[ $rae_size -eq 124 ] && {
				ubirsvol /dev/ubi0 -N vol_rae -s 2MiB
			}
		fi
	
		if [ "x$(cat /tmp/orbi_type)" = "xBase" ]; then
			if [ -z "$(ubinfo -a |grep vol_armor)" ]; then
				ubimkvol /dev/ubi0 -N vol_armor -s 40MiB
			fi
		fi

		# integrate ubi volumns for overlay and forceshield to vol_ntgr
		orbi_type=`cat /tmp/orbi_type`
		partition_type=`cat /flash_type`
		ubidev_name="vol_ntgr"
		mount_point="/mnt/ntgr"
		mkdir -p $mount_point

		# overlay part
		grep vol_overlay /proc/mtd && {
			ubidev=$(ubinfo -a | grep -B5 vol_overlay | sed -nr 's/Volume ID:.*\(on (ubi.*)\)/\1/p')
			ubirmvol /dev/$ubidev -N vol_overlay
		}

		if [ "x$orbi_type" = "xBase" ]; then
			# Expand NTGR partition to 45MiB
			if [ "x$(ubinfo -a | grep vol_ntgr)" != "x" ];then
				ntgr_size=$(ubinfo -a | grep -B5 vol_ntgr | grep Size | awk -F ' ' '{print $2}')
				[ $ntgr_size -eq 207 ] && {
					ubirsvol /dev/ubi0 -N vol_ntgr -s 45MiB
				}
			fi

			# forceshield part
			grep vol_forceshield /proc/mtd && {
				ubidev=$(ubinfo -a | grep -B5 vol_forceshield | sed -nr 's/Volume ID:.*\(on (ubi.*)\)/\1/p')
				ubirmvol /dev/$ubidev -N vol_forceshield
			}

			# Remove vol_foreshield because of the wrong name. This is for backward compatibility
			grep vol_foreshield /proc/mtd && {
				ubidev=$(ubinfo -a | grep -B5 vol_foreshield | sed -nr 's/Volume ID:.*\(on (ubi.*)\)/\1/p')
				ubirmvol /dev/$ubidev -N vol_foreshield
			}
	
			# create vol_ntgr
			ubidev=$(ubinfo -a | grep -B5 $ubidev_name | sed -nr 's/Volume ID:.*\(on (ubi.*)\)/\1/p')
			[ "x$ubidev" = "x" ] && {
				ubidev="ubi0"
				size=$(grep "\[$ubidev_name\]" /etc/ntgrdata.cfg -A5 | sed -nr 's/vol_size=(.*)/\1/p')
				ubimkvol /dev/$ubidev -N $ubidev_name -s $size
			}
	
			mount -t ubifs $ubidev:$ubidev_name $mount_point
			if [ "x$(mount |grep $mount_point)" = "x" ]; then
				mount_dev=`part_dev ntgr`
				flash_erase $mount_dev 0 0
				mount -t ubifs $ubidev:$ubidev_name $mount_point
			fi
		else
			# create vol_ntgr
			ubidev=$(ubinfo -a | grep -B5 $ubidev_name | sed -nr 's/Volume ID:.*\(on (ubi.*)\)/\1/p')
			[ "x$ubidev" = "x" ] && {
				ubidev="ubi0"
				size=$(grep "\[$ubidev_name\]" /etc/ntgrdata-rbs50.cfg -A5 | sed -nr 's/vol_size=(.*)/\1/p')
				ubimkvol /dev/$ubidev -N $ubidev_name -s $size
			}

			mount -t ubifs $ubidev:$ubidev_name $mount_point
			if [ "x$(mount |grep $mount_point)" = "x" ]; then
				mount_dev=`part_dev ntgr`
				flash_erase $mount_dev 0 0
				mount -t ubifs $ubidev:$ubidev_name $mount_point
			fi
		fi
	fi


}

project_boot_stage1() {
	dni_board_defconfig

	mtdn=`grep language /proc/mtd | awk -F ':' '{print $1}' | awk -F 'd' '{print $2}'`
	/usr/sbin/nanddump /dev/mtd$mtdn -f /tmp/lang_file &

	/sbin/disable_dhcp &

        /bin/config unset dni_hold_tds_update

	# Set backhaul RTS deault 2347
	project_and_type=`cat /tmp/orbi_project`_`cat /tmp/orbi_type`
	case $project_and_type in
		"Desktop_Base")
			/bin/config set wla_2nd_ap_bh_rts="2347"
			;;
		"Desktop_Satellite")
			/bin/config set wla_2nd_sta_rts="2347"
			;;
		"Orbimini_Base")
			/bin/config set wla_ap_bh_rts="2347"
			;;
		"Orbimini_Satellite")
			/bin/config set wla_sta_rts="2347"
			;;
		*)
			echo "exception condition"
			;;
	esac

        # need to update Streamboost database after upgrade firmwrare
        [ -f /tmp/new_firmware ] && /bin/config set new_firmware=1 && /bin/config commit

        /sbin/check_fwupgrade

        cloud checkversion

        [ -f /lib/read_caldata_to_fs.sh ] && {
                . /lib/functions.sh
                . /lib/read_caldata_to_fs.sh
                do_load_ipq4019_board_bin
        }

        local rssi_move_far2g=$(/bin/config get rssi_move_far2g)
        local rssi_move_far5g=$(/bin/config get rssi_move_far5g)
        local rssi_prefer_2g_bh=$(/bin/config get rssi_prefer_2g_bh)

		if [ "x$flash_type" = "xEMMC" ];then
	        local Product_Name=`cat /sys/bus/mmc/devices/mmc0:0001/cid | cut -c 7-18`
			# KSI EMMC is 4d3632373034, Samsung flash is 344650443352
			if [ "$Product_Name" = "4d3632373034" ]; then
                echo 0 > /tmp/cfg_allow_upgrade_fw
			elif [ "$Product_Name" = "344650443352" ]; then
                echo 1 > /tmp/cfg_allow_upgrade_fw
			fi
		fi

		local age_value=`/bin/config get ageing_time`
		if [ "$age_value" != "30" ]; then
			/bin/config set ageing_time="30"
			/bin/config commit
		fi



        local ageing_time=$(/bin/config get ageing_time)
        /usr/sbin/brctl setageing $BR_IF $ageing_time

	if [ "$model_prefix" = "S" ]; then
		/bin/config set wla_2nd_ap_bh_ssid=$(/bin/config get wla_2nd_sta_ssid)
		/bin/config set wlg_ap_bh_ssid=$(/bin/config get wlg_sta_ssid)

		/bin/config set wla_2nd_ap_bh_wpa2_psk=$(/bin/config get wla_2nd_sta_wpa2_psk)
		/bin/config set wlg_ap_bh_wpa2_psk=$(/bin/config get wlg_sta_wpa2_psk)

		/bin/config commit
	fi

	# As NTGR request, enable radio and disable wifi schedule and set TPC value to 100% when V1.10 and V2.0 firmware boot up.
	if [ "$model_prefix" = "R" ]; then
		local tmp_endis_wl_radio=$(/bin/config get endis_wl_radio)
		local tmp_endis_wla_radio=$(/bin/config get endis_wla_radio)
		local tmp_wladv_schedule_enable=$(/bin/config get wladv_schedule_enable)
		local tmp_wladv_schedule_enable_a=$(/bin/config get wladv_schedule_enable_a)

		if [ "$tmp_endis_wl_radio" = "0" -o "$tmp_endis_wla_radio" = "0" -o "$tmp_wladv_schedule_enable" = "1" -o "$tmp_wladv_schedule_enable_a" = "1" ]; then
			/bin/config set endis_wl_radio=1
			/bin/config set endis_wla_radio=1
			/bin/config set wladv_schedule_enable=0
			/bin/config set wladv_schedule_enable_a=0
			/bin/config set config_timestamp=$(date +%s)
			/bin/config commit
		fi
	fi

	# disable hyd, wsplcd, and repacd for simplification of factory mode.
	if [ "$(/bin/config get factory_mode)" = "1" ]; then
		/bin/config set hyd_enable=0
		/bin/config set wsplcd_enable=0
		/bin/config set repacd_enable=0
		/bin/config commit
	fi

	reset_satelliteconfigs_forced=$(/bin/config get reset_satelliteconfigs_forced)
	if [ "$reset_satelliteconfigs_forced" != "1" ]; then
		/bin/config set reset_satelliteconfigs_forced=1
		sate_num=256
		while [ "$sate_num" -gt "0" ]; do
			/bin/config unset satellite$sate_num
			sate_num=$(( $sate_num - 1 ))
		done
		/bin/config commit
	fi

	# wifison parameters setting
	model_id=`artmtd -r board_model_id | grep -o '..$'`    # judge project through the last two char of board_model_id. ex : RBR'50'
	case $model_id in
	    "20")
		/bin/config set rssi_prefer_2g_bh="-80"
		/bin/config set lbd_LowRSSIAPSteerThreshold_CAP_W2="40"
		/bin/config set lbd_LowRSSIAPSteerThreshold_CAP_W5="33"
		/bin/config set lbd_LowRSSIAPSteerThreshold_RE_W2="40"
		/bin/config set lbd_LowRSSIAPSteerThreshold_RE_W5="33"
		/bin/config set lbd_RSSISteeringPoint_UG="22"
		/bin/config set lbd_RateRSSIXingThreshold_UG="31"
		/bin/config set lbd_OffloadingMinRSSI="28"
		;;
	    "30")
		;;
	    "40")
		/bin/config set rssi_prefer_2g_bh="-80"
		/bin/config set lbd_BTMAssociationTime="6"
		;;
	    "50")
		/bin/config set lbd_BTMAssociationTime="6"
		/bin/config set lbd_BlacklistTime=60
		;;
	    *)
		echo "exception condition"
		;;
	esac       
}
