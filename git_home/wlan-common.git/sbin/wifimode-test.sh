#!/bin/sh

a_mode=-1
g_mode=-1
a2_mode=-1

usage(){
    echo "mode value:"
    echo "0 -> OFF"
    echo "1 -> normal AP"
    echo "2 -> ex_sta"
    echo "3 -> normal_ap+ex_sta"
    echo "4 -> backhaul_ap"
    echo "5 -> backhaul_sta"
    echo "6 -> backhaul_ap+backhaul_sta"
    echo "7 -> normal_ap+backhaul_sta"
    echo "8 -> normal_ap+backhaul_ap+backhaul_sta"
    echo "9 -> normal_ap+backhaul_ap"
}

min_opmode=0
max_opmode=9

check_error=0
a_mode_enable_only=0
g_mode_enable_only=0
a2_mode_enable_only=0

while getopts ":a:g:s:" opt;do
    case $opt in
        a)
            optlen=${#OPTARG}
            lastc=`echo $OPTARG | cut -c $optlen`
            if [ "$lastc" = "-" -o "$lastc" = "+" ]; then
                a_mode_enable_only=1
                value=`echo $OPTARG | sed 's/[-+]//g'`
            else
                value=${OPTARG}
            fi
            a_mode=$(( $value ))
            if [ $a_mode -lt $min_opmode -o $a_mode -gt $max_opmode ]; then
                echo "Operation mode for 1st A radio is out of range. (0<= mode <=9)"
                check_error=1
            fi
            ;;
        g)
            optlen=${#OPTARG}
            lastc=`echo $OPTARG | cut -c $optlen`
            if [ "$lastc" = "-" -o "$lastc" = "+" ]; then
                g_mode_enable_only=1
                value=`echo $OPTARG | sed 's/[-+]//g'`
            else
                value=${OPTARG}
            fi
            g_mode=$(( $value ))
            if [ $g_mode -lt $min_opmode -o $g_mode -gt $max_opmode ]; then
                echo "Operation mode for 2.4G radio is out of range. (0<= mode <=9)"
                check_error=1
            fi
            ;;
        s)
            optlen=${#OPTARG}
            lastc=`echo $OPTARG | cut -c $optlen`
            if [ "$lastc" = "-" -o "$lastc" = "+" ]; then
                a2_mode_enable_only=1
                value=`echo $OPTARG | sed 's/[-+]//g'`
            else
                value=${OPTARG}
            fi
            a2_mode=$(( $value ))
            if [ $a2_mode -lt $min_opmode -o $a2_mode -gt $max_opmode ]; then
                echo "Operation mode for 2nd A radio is out of range. (0<= mode <=9)"
                check_error=1
            fi
            ;;
        *)
            usage
            exit 1
    esac
done

# sed -i 's/^g_device=.*/g_device="wifi1"/' $(1)/etc/ath/wifi.conf;
# sed -i 's/^a_device=.*/a_device="wifi0"/' $(1)/etc/ath/wifi.conf;

[ $check_error -eq 0 ] || {
    usage
    exit 1
}

[ $g_mode -eq -1 ] && {
    echo "2.4G mode (-g) is not set."
    usage
    exit 1
}

[ $a_mode -eq -1 ] && {
    echo "First 5G mode (-a) is not set."
    usage
    exit 1
}

[ $a2_mode -eq -1 ] && {
    echo "Second 5G mode (-s) is not set."
    usage
    exit 1
}

config set wlg_operation_mode=$g_mode
config set wla_operation_mode=$a_mode
config set wla_2nd_operation_mode=$a2_mode
[ "$a2_mode" = "0" ] && config set endis_wla_2nd_radio=0 || config set endis_wla_2nd_radio=1
[ "$a_mode" = "0" ] && config set endis_wla_radio=0 || config set endis_wla_radio=1

# ====== 2.4G ======
if [ $g_mode_enable_only -eq 0 ]; then
    config set endis_wl_wps=1
    config set wps_status=5
    config set wl_ssid=2G_fronthaul_AP
    config set wl_sectype=4
    config set wl_auth=2
    config set wl_wpa2_psk=12345678
    config set wl_wpa1_psk=12345678
    config set wl_wpas_psk=12345678
    config set wl_disablecoext=0

    config set wlg_ap_bh_endis_wps=1
    config set wlg_ap_bh_wps_status=5
    config set wlg_ap_bh_ssid=backhaul_AP
    config set wlg_ap_bh_endis_ssid_broadcast=1
    config set wlg_ap_bh_disablecoext=0
    config set wlg_ap_bh_sectype=4
    config set wlg_ap_bh_auth=2
    config set wlg_ap_bh_wpa2_psk=12345678
    config set wlg_ap_bh_wpa1_psk=12345678
    config set wlg_ap_bh_wpas_psk=12345678
    config set wlg_ap_bh_endis_pin=1

    config set wlg_sta_endis_wps=1
    config set wlg_sta_wps_status=5
    config set wlg_sta_ssid=2G_backhaul_AP_sta
    config set wlg_sta_sectype=1
    config set wlg_sta_auth=2
    config set wlg_sta_wpa2_psk=12345678
    config set wlg_sta_wpa1_psk=12345678
    config set wlg_sta_wpas_psk=12345678
fi

#====== 1st 5G ========
if [ $a_mode_enable_only -eq 0 ]; then
    config set wla_hidden_channel=48
    config set wla_ht160=0
    config set wla_simple_mode=9

    config set endis_wla_wps=1
    config set wla_wps_status=5
    config set wla_ssid=5G_fronthaul_AP
    config set wla_endis_ssid_broadcast=1
    config set wla_sectype=1
    config set wla_auth=2
    config set wla_wpa2_psk=12345678
    config set wla_wpa1_psk=12345678
    config set wla_wpas_psk=12345678
    config set wla_disablecoext=0

    config set wla_ap_bh_endis_wps=1
    config set wla_ap_bh_wps_status=5
    config set wla_ap_bh_ssid=backhaul_AP
    config set wla_ap_bh_endis_ssid_broadcast=1
    config set wla_ap_bh_disablecoext=0
    config set wla_ap_bh_sectype=4
    config set wla_ap_bh_auth=2
    config set wla_ap_bh_wpa2_psk=12345678
    config set wla_ap_bh_wpa1_psk=12345678
    config set wla_ap_bh_wpas_psk=12345678
    config set wla_ap_bh_endis_pin=1

    config set wla_sta_endis_wps=1
    config set wla_sta_wps_status=5
    config set wla_sta_ssid=5G_backhaul_AP_sta
    config set wla_sta_sectype=1
    config set wla_sta_auth=2
    config set wla_sta_wpa2_psk=12345678
    config set wla_sta_wpa1_psk=12345678
    config set wla_sta_wpas_psk=12345678
fi
#====== 2nd 5G ========

if [ $a2_mode_enable_only -eq 0 ]; then
    config set wla_2nd_hidden_channel=157
    config set wla_2nd_ht160=0
    config set wla_2nd_simple_mode=9

    config set endis_wla_2nd_wps=1
    config set wla_2nd_wps_status=5
    config set wla_2nd_ssid=5G_2nd_fronthaul_AP
    config set wla_2nd_endis_ssid_broadcast=1
    config set wla_2nd_sectype=1
    config set wla_2nd_auth=2
    config set wla_2nd_wpa2_psk=12345678
    config set wla_2nd_wpa1_psk=12345678
    config set wla_2nd_wpas_psk=12345678
    config set endis_wla_2nd_wmm=1
    # config set wla_2nd_endis_country_ie=
    config set wla_2nd_tpscale=100
    config set wla_2nd_endis_pin=0
    config set wla_2nd_bf=0
    config set wla_2nd_implicit_bf=1
    config set wla_2nd_mu_mimo=0

    config set endis_wla_2nd_ap_bh_wps=1
    config set wla_2nd_ap_bh_wps_status=5
    config set wla_2nd_ap_bh_ssid=backhaul_AP
    config set wla_2nd_ap_bh_endis_ssid_broadcast=1
    config set wla_2nd_ap_bh_disablecoext=0
    config set wla_2nd_ap_bh_sectype=4
    config set wla_2nd_ap_bh_auth=2
    config set wla_2nd_ap_bh_wpa2_psk=12345678
    config set wla_2nd_ap_bh_wpa1_psk=12345678
    config set wla_2nd_ap_bh_wpas_psk=12345678
    config set wla_2nd_ap_bh_endis_pin=1

    config set endis_wla_2nd_sta_wps=1
    config set wla_2nd_sta_wps_status=5
    config set wla_2nd_sta_ssid=5G_2nd_backhaul_AP
    config set wla_2nd_sta_sectype=1
    config set wla_2nd_sta_auth=2
    config set wla_2nd_sta_wpa2_psk=12345678
    config set wla_2nd_sta_wpa1_psk=12345678
    config set wla_2nd_sta_wpas_psk=12345678
fi

config commit
