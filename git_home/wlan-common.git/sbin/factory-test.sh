# script of examine the Tput for factory mode

orbi_project=`cat /tmp/orbi_project`
[ -z "$orbi_project" ] && exit 0

DEVICES=`cat /etc/ath/wifi.conf | grep "_device=" | awk -F\" '{print $2}' | grep wifi`
nmrp=`/bin/config get nmrp`
. /etc/dni-wifi-config

# wireless interface simple setting for Tput test in factory mode
if [ $1 = "boot"  ]; then 			# implement following function when boot

    #startup nmrp client
    if [ "x$nmrp" = "x1" ]; then
        cp /usr/sbin/wireless_nmrp /etc/config/wireless
    else
        cp /usr/sbin/wireless_factory_config /etc/config/wireless
    fi

    for device in $DEVICES; do
        if [ "$device" = "wifi0" ];then
            uci set wireless.${device}.macaddr=`artmtd -r mac|grep 2g|awk -F \  '{print $4}'`
            uci set wireless.${device}.country=$country_code
            uci set wireless.${device}.channel=`/bin/config get wl_hidden_channel`
            uci set wireless.${device}.disablecoext='1'
        elif [ "$device" = "wifi1" ];then
            uci set wireless.${device}.macaddr=`artmtd -r mac|grep wlan5g|awk -F \  '{print $3}'`
            uci set wireless.${device}.country=$country_code
            uci set wireless.${device}.channel=`/bin/config get wla_hidden_channel`
        elif [ "$device" = "wifi2" ];then
            uci set wireless.${device}.macaddr=`artmtd -r mac|grep wlan2nd5g|awk -F \  '{print $3}'`
            uci set wireless.${device}.country=$country_code
            uci set wireless.${device}.channel=`/bin/config get wla_2nd_hidden_channel`
        fi
    done
fi

# radartool setting for DFS in factory mode
if [ $1 = "post_wlan_up"  ]; then 			# implement following function when wlan up
    if [ "$orbi_project" = "Orbimini"  ]; then
        radartool -i wifi1 usenol 0
    elif [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbipro" -o "$orbi_project" = "OrbiOutdoor" -o "$orbi_project" = "Ceiling" -o "$orbi_project" = "ProOutdoor" ]; then
        radartool -i wifi2 usenol 0
    fi

    killall udhcpc

    # disable wifi interface when boot in factory mode
    # and set power to amber to tell now the dut boot is finish
    wifi_iface=`uci show wireless | grep "\.device=" | awk -F. '{print $2}'`
    for wi in $wifi_iface; do
        wl_athx=`uci -q get wireless.${wi}.ifname`
        ifconfig $wl_athx down
    done

    ebtables_alive=`lsmod |grep ebtable`
    if [ -n "$ebtables_alive" ]; then
        rmmod ebtable_broute
        ebtables -F
        rmmod ebtable_filter
        rmmod ebtable_nat
        rmmod ebtables
        rm /usr/sbin/ebtables
    fi

    if [ "x$nmrp" = "x1" ]; then
        killall nmrp_led 2> /dev/null
        /sbin/nmrp_led &
    fi
    
    exit 1
fi


#auto calibration
cal=`/bin/config get cal`
ota=`/bin/config get ota`
if [ $1 = "mode"  ]; then
    . /lib/functions.sh
    . /lib/wifi/qcawifi.sh
    set_boarddata $country_code

    if [ "x$cal" == "x0" ]; then
        echo "===============ipq cal mode============" > /dev/console
        mv /lib/firmware/IPQ4019/hw.1/otp.bin /lib/firmware/IPQ4019/hw.1/otp_org.bin
        sync
    fi
    if [ "x$cal" == "x0" ]; then
        echo "===============qca cal mode============" > /dev/console
        if [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbipro" -o "$orbi_project" = "OrbiOutdoor" -o "$orbi_project" = "Ceiling"  ];then
            mv /lib/firmware/QCA9984/hw.1/otp.bin /lib/firmware/QCA9984/hw.1/otp_org.bin
        else
            mv /lib/firmware/QCA9888/hw.2/otp.bin /lib/firmware/QCA9888/hw.2/otp_org.bin
        fi
        sync
    fi
    if [ "x$ota" == "x0" ]; then
        echo "===============otp mode============" > /dev/console
        /etc/init.d/qcmbr stop
        /etc/init.d/qcmbr start
    fi
    /sbin/ledcontrol -n power -c amber -s on
    echo "DUT_boot_up_done1111111111" > /dev/console
    exit 1
fi

uci commit wireless
if [ "$orbi_project" = "OrbiOutdoor" -o "$orbi_project" = "ProOutdoor" ]; then
    ifconfig br0 down
    ifconfig br0 up
fi
