#!/bin/sh
# function scan_wifi() was copied from uci2cfg.sh released by QCA.

. /lib/functions.sh

[ -f /etc/ath/wifi.conf ] && . /etc/ath/wifi.conf

APPLY_SECURITYONLY=0
WSPLCD_SYNC=0
topology_file=$WIFI_TOPOLOGY_FILE
debug_cmd=""
while getopts ":d" opt;do
    case $opt in
        d)
            debug_cmd="echo"
        ;;
    esac
done

scan_wifi() {
    local cfgfile="$1"
    DEVICES=
    config_load "${cfgfile:-wireless}"

    # Create a virtual interface list field for each wifi-device
    #
    # input: $1 section: section name of each wifi-device
    create_vifs_list() {
        local section="$1"
        append DEVICES "$section"
        config_set "$section" vifs ""
    }
    config_foreach create_vifs_list wifi-device

    # Append each wifi-iface to the virtual interface list of its associated wifi-device
    #
    # input: $1 section: section name of each wifi-iface
    append_vif() {
        local section="$1"
        config_get device "$section" device
        config_get vifs "$device" vifs
        append vifs "$section"
        config_set "$device" vifs "$vifs"
        # For wifi-iface (VAP), record its index and section name in variable
        # vifname_#. This will be used later when generating wsplcd config file
        # to match the VAP with correct index.
        eval "vifname_${TOTAL_NUM_VIFS}=$section"
        TOTAL_NUM_VIFS=$(($TOTAL_NUM_VIFS + 1))
    }
    config_foreach append_vif wifi-iface
}

get_radio_prefix()
{
    local _prefix

    eval _prefix=\$${2}_prefix
    eval export -- "${1}=${_prefix}_"
}

get_vap_prefix()
{
    local ifname=$2
    local _prefix=`awk -v input_ifname=$ifname -v output_rule=prefix -f /etc/search-wifi-interfaces.awk $topology_file`
    eval export -- "${1}=${_prefix}_"
}

dni_config_set()
{
    local item=$1
    local value="$2"

    [ -n "$value" ] && {
        eval ${debug_cmd} /bin/config set \"$item\"=\"\$value\"
    } || {
        echo "No value provided for item $item"
    }
}

set_channel()
{
    local device=$1
    local prefix=$2

    config_get channel $device channel
    dni_config_set ${prefix}hidden_channel $channel
}

set_country()
{
    local device=$1
    local prefix=$2
    local country
    local country_code

    config_get country $device country

    [ -n "$country" ] && {
        case $country in
            710) country_code=0 ;;
            764) country_code=1 ;;
            5000) country_code=2 ;;
            5001) country_code=3 ;;
            276) country_code=4 ;;
            376) country_code=5 ;;
            4015) country_code=6 ;;
            412) country_code=7 ;;
            484) country_code=8 ;;
            76) country_code=9 ;;
            843) country_code=10 ;;
            156) country_code=11 ;;
            356) country_code=12 ;;
            458) country_code=13 ;;
            12) country_code=14 ;;
            364) country_code=15 ;;
            792) country_code=16 ;;
            682) country_code=17 ;;
            784) country_code=18 ;;
            643) country_code=19 ;;
            702) country_code=20 ;;
            158) country_code=21 ;;            
        esac
        [ -n "$country_code" ] && {
            # All radio read from same country setting.
            dni_config_set wl_country $country_code
        } || {
            echo "Unknonw country $country"
        }
    }
}

set_chmode()
{
    local device=$1
    local prefix=$2
    local htmode
    local hwmode
    local chmode

    config_get hwmode $device hwmode
    config_get htmode $device htmode

    case "$hwmode:$htmode" in
        11bg:*) chmode=1 ;;
        11ng:HT20) chmode=2 ;;
        11ng:HT40+) chmode=3 ;;
        11b:*) chmode=4 ;;
        11ng:HT40-) chmode=5 ;;
        11ng:HT40) chmode=6 ;;
        11ng:*) chmode=2 ;;
        11a:*) chmode=1 ;;
        11na:HT*) chmode=3 ;;
        11ac:HT20) chmode=7 ;;
        11ac:HT40*) chmode=8 ;;
        11ac:HT80*|11ac:HT160*) chmode=9 ;;
    esac

    [ -n "$chmode" ] && {
        dni_config_set ${prefix}simple_mode $chmode
    } || {
        echo "Unable to parse channel mode from hwmode=$hwmode, htmode=$htmode"
    }
}

set_implicitbf()
{
    local device=$1
    local prefix=$2
    local implicitbf
    config_get implicitbf $device implicitbf
    [ -n "$implicitbf" ] && {
        dni_config_set ${prefix}implicit_bf $implicitbf
    }
}

set_vap_ssid()
{
    local _vif=$1
    local _prefix="$2"
    local ssid
    config_get ssid $_vif ssid

    echo "$ssid" > /tmp/tmp_ssid
    sed -i 's/\\/\\\\\\\\/g' /tmp/tmp_ssid
    sed -i 's/"/\\\"/g' /tmp/tmp_ssid
    sed -i 's/`/\\\\\\\`/g' /tmp/tmp_ssid


    [ -n "$ssid" ] && {
        dni_config_set ${_prefix}ssid "`cat /tmp/tmp_ssid`" 
    }
    rm -f /tmp/tmp_ssid
}

set_vap_security()
{
    local _vif=$1
    local _prefix=$2
    local encryption key auth_type key_format prev_key_fmt key_len
    config_get encryption $_vif encryption
    case "$encryption" in
        none)
            dni_config_set ${_prefix}sectype 1
            ;;
        wep*)
            dni_config_set ${_prefix}sectype 2
            auth_type=`echo $encryption | awk -F\- '{print $2}'`
            [ -z "$auth_type" ] && auth_type=0
            prev_key_fmt="HEX"
            for idx in 1 2 3 4; do
                config_get key $_vif key${idx}
                [ -n "$key" ] || {
                    dni_config_set ${_prefix}key${idx} $key
                }
                config_get key_format $_vif key{$idx}_format $prev_key_fmt
                key_len=${#key}
                if [ "$key_format" != "HEX"  ]; then
                    key_len=$(( $key_len / 2 ))
                fi
                prev_key_fmt=$key_format
            done
            dni_config_set ${_prefix}key_length $key_len
            ;;
        psk2*)
            dni_config_set ${_prefix}sectype 4
            config_get key $_vif key
            echo "$key" > /tmp/tmp_key
            sed -i 's/\\/\\\\/g' /tmp/tmp_key
            sed -i 's/"/\\\"/g' /tmp/tmp_key
            sed -i 's/`/\\\`/g' /tmp/tmp_key
            dni_config_set ${_prefix}wpa2_psk "`cat /tmp/tmp_key`" 
            rm -f /tmp/tmp_key
            ;;
        *mixed*)
            dni_config_set ${_prefix}sectype 5
            config_get key $_vif key
            echo "$key" > /tmp/tmp_key
            sed -i 's/\\/\\\\/g' /tmp/tmp_key
            sed -i 's/"/\\\"/g' /tmp/tmp_key
            sed -i 's/`/\\\`/g' /tmp/tmp_key
            dni_config_set ${_prefix}wpas_psk "`cat /tmp/tmp_key`" 
            rm -f /tmp/tmp_key
            ;;
        psk*)
            dni_config_set ${_prefix}sectype 3
            config_get key $_vif key
            echo "$key" > /tmp/tmp_key
            sed -i 's/\\/\\\\/g' /tmp/tmp_key
            sed -i 's/"/\\\"/g' /tmp/tmp_key
            sed -i 's/`/\\\`/g' /tmp/tmp_key
            dni_config_set ${_prefix}wpa1_psk "`cat /tmp/tmp_key`"
            rm -f /tmp/tmp_key
            ;;
    esac
}

set_vap_wps()
{
    local _vif=$1
    local _prefix=$2
    local wps wps_state wps_config setup_lock opmode ifname

    config_get ifname $_vif ifname
    opmode=`awk -v input_ifname=$ifname -v output_rule=opmode -f /etc/search-wifi-interfaces.awk $topology_file`

    [ -z "$opmode" -o "$opmode" = "STA" ] && return
    config_get wps_state $_vif wps_state 0

    case $wps_state in
        0)
            dni_config_set endis_${_prefix}wps 0
            ;;
        1)
            dni_config_set endis_${_prefix}wps 1
            ;;
        2)
            dni_config_set endis_${_prefix}wps 2
            if [ "$_prefix" = "wl_" ]; then
                # Special case for wlg, really not good
                dni_config_set wps_status 5
            else
                dni_config_set ${_prefix}wps_status 5
            fi
            ;;
    esac
    config_get setup_lock $_vif ap_setup_locked 0
    if [ "$_prefix" = "wl_" ]; then
        dni_config_set endis_pin $setup_lock
    else
        dni_config_set ${_prefix}endis_pin $setup_lock
    fi
}

set_vap_hiddenssid()
{
    local _vif=$1
    local _prefix=$2
    local _hidden
    config_get _hidden $_vif hidden 0
    [ -n "$_hidden" ] && {
        [ "${_prefix}" = "wl_" ] && _prefix=""
        if [ $_hidden -eq 0 ]; then
            dni_config_set ${_prefix}endis_ssid_broadcast 1
        else
            dni_config_set ${_prefix}endis_ssid_broadcast 0
        fi
    }
}

set_vap_disablecoext()
{
    local _vif=$1
    local _prefix=$2
    local _disablecoext
    config_get _disablecoext $_vif disablecoext 0
    [ -n "$_disablecoext" ] && {
        dni_config_set ${_prefix}disablecoext $_disablecoext
    }
}


set_vap_rrm()
{
    local _vif=$1
    local _prefix=$2
    local _rrm
    config_get _rrm $_vif rrm 0
    [ -n "$_rrm" ] && {
        dni_config_set ${_prefix}rrm $_rrm
    }
}

set_vap_mcastenhance()
{
    local _vif=$1
    local _prefix=$2
    local _mcastenhance
    config_get _mcastenhance $_vif mcastenhance
    [ -n "$_mcastenhance" ] && {
        dni_config_set ${_prefix}mcastenhance $_mcastenhance
    }
}

get_set_wifi()
{
    local vifidx=0
    local radio_prefix
    local vap_prefix

    scan_wifi
    for device in ${1:-$DEVICES}; do
        get_radio_prefix radio_prefix $device
        [ -n "$radio_prefix" ] || {
            echo "Unable to get radio prefix for wifi device [$device]"
            continue
        }
        if [ $APPLY_SECURITYONLY -eq 0 ]; then
            set_country $device $radio_prefix
            set_channel $device $radio_prefix
            set_chmode $device $radio_prefix
            set_implicitbf $device $radio_prefix
        fi
        if [ $WSPLCD_SYNC -eq 1 ]; then
            set_channel $device $radio_prefix
        fi
        config_get vifs "$device" vifs
        for vif in $vifs; do
            config_get ifname "$vif" ifname
            config_get wsplcd_unmanaged "$vif" wsplcd_unmanaged

            get_vap_prefix vap_prefix $ifname
            [ -n "$vap_prefix" ] || {
                echo "Unable to get vap prefix for interface [$ifname]"
                continue
            }

            if [ $WSPLCD_SYNC -eq 1 ] && [ $wsplcd_unmanaged -eq 1 ]; then
                echo "[uci2dni] Skip $ifname by wsplcd" > /dev/console
                continue
            fi

            set_vap_ssid $vif $vap_prefix
            set_vap_security $vif $vap_prefix
            if [ $APPLY_SECURITYONLY -eq 0 ]; then
                set_vap_wps $vif $vap_prefix
                set_vap_hiddenssid $vif $vap_prefix
                set_vap_disablecoext $vif $vap_prefix
                set_vap_rrm $vif $vap_prefix
                set_vap_mcastenhance $vif $vap_prefix
            fi
        done
    done
}

[ -f "/tmp/orbi_type" -a $(cat /tmp/orbi_type) = "Satellite" ] || exit
case "$1" in
    wps)
        APPLY_SECURITYONLY=1
        get_set_wifi
        ;;
    wsplcd)
        APPLY_SECURITYONLY=1
        WSPLCD_SYNC=1
        get_set_wifi
        ;;
    *)
        get_set_wifi
        ;;
esac

/bin/config commit
