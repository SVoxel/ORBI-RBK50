#!/bin/sh
POLLING_SEC=10
ALIVE_CHECK_TIMES=10 
ALIVE_CHECK_SEC=1

hyd_enable=
wsplcd_enable=

hyd_alive=
wsplcd_alive=

log_size="100k"

wlan_lockfile=/tmp/.wlan_updown_lockfile
hyd_restart_log=/tmp/hyd-restart.log
wsplcd_restart_log=/tmp/wsplcd-restart.log
wlan_updateconf_lockfile=/tmp/.wlan_updateconf_lockfile

hyd_restart_cnt=0
wsplcd_restart_cnt=0
lock_flag=0
flag=0
wifi_nowork=0
wifi_basic_setting_not_match_count=0

t=0

restart_hyd() {
alive_cnt=0


while [ $alive_cnt -lt $ALIVE_CHECK_TIMES ]; do 
    hyd_enable=`uci get hyd.config.Enable`
    hyd_alive=`ps | grep hyd | grep -v grep`

    if [ -n "$hyd_alive" ] || [ -f $wlan_lockfile ]; then
        return
    else
        alive_cnt=$(( $alive_cnt+1 ))
    fi
    sleep $ALIVE_CHECK_SEC
done

echo "======= hyd stoped - restart hyd" > /dev/console
hyd_restart_cnt=$(( $hyd_restart_cnt+1 ))
record=`tail -c $log_size $hyd_restart_log`
timestamp=`date`
wifi_status=`iwconfig`
echo "$record" > $hyd_restart_log
echo "" >> $hyd_restart_log
echo "[hyd restart $hyd_restart_cnt times]" >> $hyd_restart_log
echo "=====  $timestamp" >> $hyd_restart_log
echo "$wifi_status" >> $hyd_restart_log

hyctl flushatbl br0
hyctl flushdtbl br0
/etc/init.d/hyd restart
}

#to fix wifi interface down or disappeared problem.this just a workaround
wlan_updown_lock=/tmp/.wlan_updown_lockfile
wlan_updown_time=/tmp/.wlan_updown_time
wifi_restart_event_time=/tmp/.wifi_restart_event_time
wifi_restart_event(){
    if [ ! -f $wifi_restart_event_time ];then
        date +%s > $wifi_restart_event_time
        echo "[$0]time:`date +%s` first time find wifi abnormal,wait and check it again.reason:$2" > /dev/console
        return
    fi
    if [ `cat $wifi_restart_event_time` -lt $((`date +%s`-30))  ];then
        date +%s > $wifi_restart_event_time
        echo "[$0]time:`date +%s` first time find wifi abnormal,wait and check it again.reason:$2" > /dev/console
        return
    fi

    #if we use this function to restart wifi and it still has problem,we restart hostapd
    if [ -f $wlan_updown_time ]&&[ "`cat $wlan_updown_time`" -gt $((`date +%s`-180))  ];then
        echo "================[$0]wlan down/up can not fixed problem,request hostapd restart=============" >/dev/console
        echo "==========[$0]$1:wlan down/up call by $2" >/dev/console
        rm -f $wlan_updown_time
        rm -f $wifi_restart_event_time
        killall hostapd
        #sleep because kill hostapd is unblock . hostapd need time to unlink from vaps 
        #and finnally remove hostapd.pid , that is the problem . the new hostapd below
        #created a new hostapd.pid but it has been delete by the dead one .so this 
        #new hostapd would be a ghost,and finnally wlan up would start second hostapd
        sleep 2
        hostapd -g /var/run/hostapd/global -B -P /var/run/hostapd-global.pid
        ifname_hostapd=${ifname_fronthaul_ap}" "${ifname_backhaul_ap}" "${ifname_guestnetwork_ap}
        for ifname in $ifname_hostapd
        do
            wpa_cli -g /var/run/hostapd/global raw ADD bss_config=$ifname:/var/run/hostapd-$ifname.conf
        done
        wlan updateconf
        wlan down
        wlan up
        return 0
    fi
    echo "==========[$0]$1:wlan down/up call by $2" >/dev/console
    echo "===============ifconfig===================" >/dev/console
    ifconfig > /dev/console
    echo "===============iwconfig===================" >/dev/console
    iwconfig > /dev/console
    echo "===============ps=========================" >/dev/console
    ps >/dev/console
    date +%s >$wlan_updown_time
    rm -f $wifi_restart_event_time
    wlan updateconf
    wlan down
    wlan up
}

restart_wsplcd() {
alive_cnt=0

while [ $alive_cnt -lt $ALIVE_CHECK_TIMES ]; do 
    wsplcd_enable=`uci get wsplcd.config.HyFiSecurity`
    wsplcd_alive=`ps | grep wsplcd | grep -v grep`

    if [ -n "$wsplcd_alive" ] || [ -f $wlan_lockfile ] ; then
        return
    else
        alive_cnt=$(( $alive_cnt+1 ))
    fi
    sleep $ALIVE_CHECK_SEC
done
timestamp=`/bin/config get config_timestamp`
if [ "$timestamp" = "0" ];then
    flag=1
    echo "=====no need start wsplcd before soap sync=========" > /dev/console
    return
fi
# when default mode, no need restart wsplcd immediately
if [ "$flag" = "1" ]; then
    sleep 20
    flag=0
fi

echo "======= wsplcd stoped - restart wsplcd" > /dev/console
wsplcd_restart_cnt=$(( $wsplcd_restart_cnt+1 ))
record=`tail -c $log_size $wsplcd_restart_log`
timestamp=`date`
wifi_status=`iwconfig`
echo "$record" > $wsplcd_restart_log
echo "" >> $wsplcd_restart_log
echo "[wsplcd restart $wsplcd_restart_cnt times]" >> $wsplcd_restart_log
echo "=====  $timestamp" >> $wsplcd_restart_log
echo "$wifi_status" >> $wsplcd_restart_log
/etc/init.d/wsplcd restart
}

#
# Turn off fronthaul interfaces but do not destroy them.
#
# Ideas of this function originate from:
#     - /usr/sbin/port_detect.sh of "detcable"
#     - /usr/sbin/bring_fronthaul_down of "led-extender"
#
down_fronthaul() {
    wlan kickallclient
    wlan connection deny
}

# check whether wireless basic setting 2G/5G not match
# if not match, 5G will follow 2G
match_wireless_basic_setting(){
orbi_project=`/bin/cat /tmp/orbi_project`
if [ "x$orbi_project" = "xDesktop" -o "x$orbi_project" = "xOrbipro" ];then
    ssid_2g=`/bin/config get wl_ssid`
    ssid_5g=`/bin/config get wla_ssid`
    passwd_2g_wpa2=`/bin/config get wl_wpa2_psk`
    passwd_5g_wpa2=`/bin/config get wla_wpa2_psk`
    passwd_2g_wpas=`/bin/config get wl_wpas_psk`
    passwd_5g_wpas=`/bin/config get wla_wpas_psk`
    sectype_2g=`/bin/config get wl_sectype`
    sectype_5g=`/bin/config get wla_sectype`
elif [ "x$orbi_project" = "xOrbimini" ]; then
    ssid_2g=`/bin/config get wl_ssid`
    ssid_5g=`/bin/config get wla_2nd_ssid`
    passwd_2g_wpa2=`/bin/config get wl_wpa2_psk`
    passwd_5g_wpa2=`/bin/config get wla_2nd_wpa2_psk`
    passwd_2g_wpas=`/bin/config get wl_wpas_psk`
    passwd_5g_wpas=`/bin/config get wla_2nd_wpas_psk`
    sectype_2g=`/bin/config get wl_sectype`
    sectype_5g=`/bin/config get wla_2nd_sectype`
fi
if [ "x$ssid_2g" != "x$ssid_5g" -o "x$passwd_2g_wpa2" != "x$passwd_5g_wpa2" \
    -o "x$passwd_2g_wpas" != "x$passwd_5g_wpas" -o "x$sectype_2g" != "x$sectype_5g"  ]; then
    if [ $wifi_basic_setting_not_match_count -gt 6 ]; then
        echo "[wifison-monitor] make wireless basic setting equal for both 2G/5G" >/dev/console
        wifi_basic_setting_not_match_count=0
        if [ "x$orbi_project" = "xDesktop" -o "x$orbi_project" = "xOrbipro" ];then
            /bin/config set wla_ssid=`/bin/config get wl_ssid`
            /bin/config set wla_wpa2_psk=`/bin/config get wl_wpa2_psk`
            /bin/config set wla_wpas_psk=`/bin/config get wl_wpas_psk`
            /bin/config set wla_sectype=`/bin/config get wl_sectype`
        elif [ "x$orbi_project" = "xOrbimini" ];then
            /bin/config set wla_2nd_ssid=`/bin/config get wl_ssid`
            /bin/config set wla_2nd_wpa2_psk=`/bin/config get wl_wpa2_psk`
            /bin/config set wla_2nd_wpas_psk=`/bin/config get wl_wpas_psk`
            /bin/config set wla_2nd_sectype=`/bin/config get wl_sectype`
        fi
        config commit
        wlan updateconf
        wlan down fronthaul
        wlan up
    else
        wifi_basic_setting_not_match_count=$(($wifi_basic_setting_not_match_count+1))
    fi
else
    wifi_basic_setting_not_match_count=0
fi
}

if [ ! -f $hyd_restart_log ] ; then
    touch $hyd_restart_log
fi

if [ ! -f $wsplcd_restart_log ] ; then
    touch $wsplcd_restart_log
fi

sleep 180

while [ 1 ] ; do

hyd_enable=`uci get hyd.config.Enable`
wsplcd_enable=`uci get wsplcd.config.HyFiSecurity`

hyd_alive=`ps | grep hyd | grep -v grep`
wsplcd_alive=`ps | grep wsplcd | grep -v grep`

wl2g_fronthaul=`config get wl2g_NORMAL_AP`
wl5g_fronthaul=`config get wl5g_NORMAL_AP`
wl5g_2nd_fronthaul=`config get wl5g_2nd_NORMAL_AP`
if [ "x$(/usr/sbin/ebtables -t filter -L |grep -w $wl2g_fronthaul)" = "x" -a "`cat /tmp/orbi_type`" = "Satellite" ];then
    /usr/sbin/ebtables -t filter -A INPUT -p 0x893A -i $wl2g_fronthaul -j DROP
    /usr/sbin/ebtables -t filter -A INPUT -p 0x893A -i $wl5g_fronthaul -j DROP
fi

factory_mode=`/bin/config get factory_mode`
wifison_monitor_stop=`/bin/config get wifison-monitor_stop`

if [ "$factory_mode" = "1" ] || [ "$wifison_monitor_stop" = "1" ]; then
    while [ 1 ]; do
	sleep 65535
    done
fi

if [ "$hyd_enable" = "1" ] && [ -z "$hyd_alive" ] && [ ! -f $wlan_lockfile ] ; then
    restart_hyd &
fi

if [ "$wsplcd_enable" = "1" ] && [ -z "$wsplcd_alive" ] && [ ! -f $wlan_lockfile ]; then
    restart_wsplcd &
fi

#monitor wifi-listener
if [ "`/bin/config get enable_arlo_function`" = "1" -a "`ps|grep wifi-listener|grep -v grep`" = "" ];then
    /etc/init.d/wifi-listener start &
fi

#temply handle lock issue in wifi restart
#Warning! this code need to be removed once get reply from QCA
lock_pid="`cat /var/run/wifilock`"
if [ -f $wlan_lockfile -a -n "$lock_pid" -a -n "`ps|grep $lock_pid |grep -v grep`" 2>/dev/null ];then
    if [ "`cat /var/run/wifilock`" = "$lock_pid" ];then
        if [ $t -gt 6 ];then
            lock -u /var/run/wifilock
            t=0
            echo "[$0]wifi unlock workaround working!" >/dev/console
        else
            let t++
        fi
    else
        t=0
    fi
fi
#if wlan_updateconf_lockfile exists for more than 60s, delete this lock file.
time_of_updateconf_lock=`stat -c %Y $wlan_updateconf_lockfile 2>/dev/null`
if [ -n "$time_of_updateconf_lock" ]&&[ $time_of_updateconf_lock -lt $((`date +%s`-60))  ];then
      echo "[$0]Create wlan_updateconf_lockfile time:$time_of_updateconf_lock, Current time:`date +%s`,timeout 60s!" > /dev/console
      rm $wlan_updateconf_lockfile -f 2>/dev/null
fi
# if wlan_updown_lockfile exists for more than 300s,delete this lock file.
time_of_updown_lock=`stat -c %Y $wlan_lockfile 2>/dev/null`
if [ -n "$time_of_updown_lock" ]&&[ $time_of_updown_lock -lt $((`date +%s`-300))  ];then
      echo "[$0]Create wlan_updown_lockfile time:$time_of_updown_lock, Current time:`date +%s`,timeout 300s!" > /dev/console
      rm $wlan_lockfile -f 2>/dev/null
fi



sleep $POLLING_SEC

hyctl flushatbl br0

if [ -f $wlan_lockfile ]; then
    lock_flag=1
    continue
fi

if [ $lock_flag = "1" ]; then
    lock_flag=0
    sleep 30
    continue
fi

if [ `cat /tmp/orbi_type` = "Base" ];then
	wl2g_backhaul=`config get wl2g_BACKHAUL_AP`
	wl5g_backhaul=`config get wl5g_BACKHAUL_AP`
else
	wl2g_backhaul=`config get wl2g_BACKHAUL_STA`
	wl5g_backhaul=`config get wl5g_BACKHAUL_STA`
fi

orbi_project=`cat /tmp/orbi_project`
if [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbipro" -o "$orbi_project" = "OrbiOutdoor" -o "$orbi_project" = "Ceiling" -o "$orbi_project" = "ProOutdoor" ]; then
    hyd_unmanaged_guest_2g=wlg_guest_hyd_unmanaged
    hyd_unmanaged_guest_5g=wla_guest_hyd_unmanaged
    hyd_unmanaged_guest_hband5g=wla_2nd_guest_hyd_unmanaged
    hyd_unmanaged_byod_2g=wlg_byod_hyd_unmanaged
    hyd_unmanaged_byod_5g=wla_byod_hyd_unmanaged
    hyd_unmanaged_byod_hband5g=wla_2nd_byod_hyd_unmanaged
    hyd_unmanaged_ap_hband5g=wla_2nd_hyd_unmanaged
elif [ "$orbi_project" = "Orbimini" ]; then
    hyd_unmanaged_guest_2g=wlg_guest_hyd_unmanaged
    hyd_unmanaged_guest_5g=wla_2nd_guest_hyd_unmanaged
    hyd_unmanaged_guest_hband5g=wla_guest_hyd_unmanaged
    hyd_unmanaged_ap_hband5g=wla_hyd_unmanaged
fi

wl2g_backhaul_not_connected=`iwconfig $wl2g_backhaul 2>/dev/null | grep "Not-Associated"`
wl5g_backhaul_not_connected=`iwconfig $wl5g_backhaul 2>/dev/null | grep "Not-Associated"`
cap_mode=`uci get repacd.repacd.Role`

soap_auth_block=0

if [ -f /tmp/last_auth_block ] && \
   [ "$(cat /tmp/last_auth_block)" = "1" ]; then
    soap_auth_block=1
fi

if [ "${wl2g_backhaul_not_connected}" -a "${wl5g_backhaul_not_connected}" -a "x$cap_mode" != "xCAP" ]; then
    #
    # Page 6 of Orbi Additional Miscellaneous V1.10:
    #
    #     - Satellite/Wall Plug will disable fronthaul when the uplink
    #       connection is lost.
    #
    #     - This is to avoid user client connecting to the un-useful
    #       satellite.
    #
    echo "backhaul not connected"
    down_fronthaul
elif [ "$soap_auth_block" = "1" ] && \
     [ "$(cat /tmp/orbi_type 2>/dev/null)" = "Satellite" ] && \
     [ "$cap_mode" = "CAP" ]; then
    #
    # Originate from /usr/sbin/port_detect.sh of "detcable".
    #
    # If retail/SMB Orbi satellite is connected to SMB/retail Orbi base via
    # Ethernet backhaul, because of reasons below, the Orbi satellite can be
    # judged as not connected to Orbi base:
    #
    #     - For now, QCA Wi-Fi SON does not support two Orbi bases in Ethernet
    #       connection of the same subnet, and thus we can suppose there is at
    #       most one Orbi base in the same Ethernet subnet.
    #
    #     - If restriction above is considered, only connecting Orbi base and
    #       Orbi satellite with conflicting model type (retail and SMB)
    #       through Ethernet can make Orbi satellite receive SOAP packet
    #       containing conflicting model type from Orbi base.
    #
    # and thus we can follow specification below in page 6 of Orbi Additional
    # Miscellaneous V1.10 to disable fronthaul of Orbi satellite:
    #
    #     - Satellite/Wall Plug will disable fronthaul when the uplink
    #       connection is lost.
    #
    #     - This is to avoid user client connecting to the un-useful
    #       satellite.
    #
    down_fronthaul
else
    enable_24G=`config get endis_wl_radio`
    enable_5G=`config get endis_wla_radio`
    wifischedule_24G=`config get wladv_schedule_enable`
    wifischedule_5G=`config get wladv_schedule_enable_a`
    enable_24G_guestnetwork=`config get wlg1_endis_guestNet`
    enable_5G_guestnetwork=`config get wla1_endis_guestNet`
    enable_arlo=`config get wlg_arlo_endis_arloNet`
    enable_arlo_function=`config get enable_arlo_function`
    enable_24G_byodnetwork=`config get wlg2_endis_byodNet`
    enable_5G_byodnetwork=`config get wla2_endis_byodNet`

    ifname_fronthaul_ap_2g=`config get wl2g_NORMAL_AP`
    ifname_fronthaul_ap_5g=`config get wl5g_NORMAL_AP`
    ifname_guestnetwork_ap_2g=`config get wl2g_GUEST_AP`
    ifname_guestnetwork_ap_5g=`config get wl5g_GUEST_AP`
    ifname_byodnetwork_ap_2g=`config get wl2g_BYOD_AP`
    ifname_byodnetwork_ap_5g=`config get wl5g_BYOD_AP`
    ifname_arlo_ap=`config get wl2g_ARLO_AP`
    #Tri-band 5G high band interfaces
    ifname_5Ghigh_fronthaul_ap=`config get wl5g_2nd_NORMAL_AP`
    ifname_5Ghigh_guest_ap=`config get wl5g_2nd_GUEST_AP`
    ifname_5Ghigh_byod_ap=`config get wl5g_2nd_BYOD_AP`
    enable_triband=`config get triband_enable`
    triband_mode=`config get triband_mode`


    fronthaul_5g_not_connected=
    fronthaul_2g_not_connected=
    guest_5g_not_connected=
    guest_2g_not_connected=
    if [ "x`/bin/config get wlg_setup_endis_setupNet`" != "x1" ];then
        if [ "$enable_5G" -eq '1' ]; then
            fronthaul_5g_not_connected=`iwconfig $ifname_fronthaul_ap_5g 2>/dev/null | grep "Not-Associated"`
            if [ -n "$fronthaul_5g_not_connected" ]; then
                echo "[$0]Bring fronthaul 5G interface up" > /dev/console
                ifconfig $ifname_fronthaul_ap_5g down
                ifconfig $ifname_fronthaul_ap_5g up
            fi
        fi
        if [ "$enable_24G" -eq '1' ]; then
            fronthaul_2g_not_connected=`iwconfig $ifname_fronthaul_ap_2g 2>/dev/null  | grep "Not-Associated"`
            if [ -n "$fronthaul_2g_not_connected" ]; then
                echo "[$0]Bring fronthaul 2.4G interface up" > /dev/console
                ifconfig $ifname_fronthaul_ap_2g down
                ifconfig $ifname_fronthaul_ap_2g up
            fi
        fi
    fi
    if [ "$enable_5G_guestnetwork" -eq '1' -a  "$enable_5G" -eq '1' 2>/dev/null ]; then
        guest_5g_not_connected=`iwconfig $ifname_guestnetwork_ap_5g 2>/dev/null  | grep "Not-Associated"`
        if [ -n "$guest_5g_not_connected" ]; then
            echo "[$0]Bring guest 5G interface up" > /dev/console
            ifconfig $ifname_guestnetwork_ap_5g down
            ifconfig $ifname_guestnetwork_ap_5g up
        fi
    fi

    if [ "x$enable_5G_guestnetwork" = 'x1' ]; then
        if [ "`config get $hyd_unmanaged_guest_5g`" != '0' ]; then
            /bin/config set "$hyd_unmanaged_guest_5g"=0
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    elif [ "x$enable_5G_guestnetwork" = 'x0' ]; then
        if [ "`config get $hyd_unmanaged_guest_5g`" != '1' ]; then
            /bin/config set "$hyd_unmanaged_guest_5g"=1
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    fi

    #for arlo on/off
    if [ "$enable_arlo_function" = "1" ];then
        if [ "$enable_arlo" -eq '1' -a  "$enable_24G" -eq '1' 2>/dev/null  ]; then
            arlo_not_connected=`iwconfig $ifname_arlo_ap 2>/dev/null  | grep "Not-Associated"`
            arlo_up=`ifconfig $ifname_arlo_ap 2>/dev/null  | grep "UP"`
            if [ -n "$arlo_not_connected" -o -z "$arlo_up" ]; then
                echo "[$0]Bring arlo interface up" > /dev/console
                ifconfig $ifname_arlo_ap down
                ifconfig $ifname_arlo_ap up
            fi
        fi
        if [ "$enable_arlo" -eq '0' -a  "$enable_24G" -eq '1' 2>/dev/null  ]; then
            arlo_not_connected=`iwconfig $ifname_arlo_ap 2>/dev/null  | grep "Not-Associated"`
            if [ -z "$arlo_not_connected" ]; then
                echo "[$0]Bring arlo interface down" > /dev/console
                ifconfig $ifname_arlo_ap down
            fi
        fi

        #temply workaround because see arlo dhcpd disappear on netgear SQA
        if [ "`cat /tmp/orbi_type`" = "Base" -a "`ps |grep dhcpd_arlo|grep -v grep`" = "" ];then
            /sbin/udhcpd /tmp/udhcpd_arlo.conf &
        fi
    fi

    if [ "$enable_24G_guestnetwork" -eq '1' -a  "$enable_24G" -eq '1' 2>/dev/null  ]; then
        guest_2g_not_connected=`iwconfig $ifname_guestnetwork_ap_2g 2>/dev/null  | grep "Not-Associated"`
        if [ -n "$guest_2g_not_connected" ]; then
            echo "[$0]Bring guest 2.4G interface up" > /dev/console
            ifconfig $ifname_guestnetwork_ap_2g down
            ifconfig $ifname_guestnetwork_ap_2g up
        fi
    fi

    if [ "x$enable_24G_guestnetwork" = 'x1' ]; then
        if [ "`config get $hyd_unmanaged_guest_2g`" != '0' ]; then
            /bin/config set "$hyd_unmanaged_guest_2g"=0
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    elif [ "x$enable_24G_guestnetwork" = 'x0' ]; then
        if [ "`config get $hyd_unmanaged_guest_2g`" != '1' ]; then
            /bin/config set "$hyd_unmanaged_guest_2g"=1
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    fi

    if [ "x$enable_5G_byodnetwork" = 'x1' -a  "$enable_5G" -eq '1' 2>/dev/null ]; then
        byod_5g_not_connected=`iwconfig $ifname_byodnetwork_ap_5g 2>/dev/null  | grep "Not-Associated"`
        if [ -n "$byod_5g_not_connected" ]; then
            echo "[$0]Bring byod 5G interface up" > /dev/console
            ifconfig $ifname_byodnetwork_ap_5g down
            ifconfig $ifname_byodnetwork_ap_5g up
        fi
    elif [ "x$enable_5G_byodnetwork" = 'x0' ]; then
        byod_5g_not_connected=`iwconfig $ifname_byodnetwork_ap_5g 2>/dev/null  | grep "Not-Associated"`
        if [ -z "$byod_5g_not_connected" ]; then
            echo "[$0]Bring byod 5G interface down" > /dev/console
            ifconfig $ifname_byodnetwork_ap_5g down
        fi
    fi

    if [ "x$enable_5G_byodnetwork" = 'x1' ]; then
        if [ "`config get $hyd_unmanaged_byod_5g`" != '0' ]; then
            /bin/config set "$hyd_unmanaged_byod_5g"=0
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    elif [ "x$enable_5G_byodnetwork" = 'x0' ]; then
        if [ "`config get $hyd_unmanaged_byod_5g`" != '1' ]; then
            /bin/config set "$hyd_unmanaged_byod_5g"=1
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    fi

    if [ "x$enable_24G_byodnetwork" = 'x1' -a  "$enable_24G" -eq '1' 2>/dev/null ]; then
        byod_2g_not_connected=`iwconfig $ifname_byodnetwork_ap_2g 2>/dev/null  | grep "Not-Associated"`
        if [ -n "$byod_2g_not_connected" ]; then
            echo "[$0]Bring byod 2G interface up" > /dev/console
            ifconfig $ifname_byodnetwork_ap_2g down
            ifconfig $ifname_byodnetwork_ap_2g up
        fi
    elif [ "x$enable_2G_byodnetwork" = 'x0' ]; then
        byod_2g_not_connected=`iwconfig $ifname_byodnetwork_ap_2g 2>/dev/null  | grep "Not-Associated"`
        if [ -z "$byod_2g_not_connected" ]; then
            echo "[$0]Bring byod 2G interface down" > /dev/console
            ifconfig $ifname_byodnetwork_ap_2g down
        fi
    fi

    if [ "x$enable_24G_byodnetwork" = 'x1' ]; then
        if [ "`config get $hyd_unmanaged_byod_2g`" != '0' ]; then
            /bin/config set "$hyd_unmanaged_byod_2g"=0
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    elif [ "x$enable_24G_byodnetwork" = 'x0' ]; then
        if [ "`config get $hyd_unmanaged_byod_2g`" != '1' ]; then
            /bin/config set "$hyd_unmanaged_byod_2g"=1
            wlan updateconf
            /etc/init.d/hyd restart
        fi
    fi

    if [ "$enable_triband" -eq '1' 2>/dev/null  ]; then

        hband5g_ap_not_connected=`iwconfig $ifname_5Ghigh_fronthaul_ap 2>/dev/null  | grep "Not-Associated"`
        hband5g_guest_not_connected=`iwconfig $ifname_5Ghigh_guest_ap 2>/dev/null  | grep "Not-Associated"`
        hband5g_byod_not_connected=`iwconfig $ifname_5Ghigh_byod_ap 2>/dev/null  | grep "Not-Associated"`

        if [ "$triband_mode"  -eq '1' ]; then
            if [ -n "$hband5g_ap_not_connected" ]; then
                echo "[$0]Bring 5G high band AP interface up" > /dev/console
                ifconfig $ifname_5Ghigh_fronthaul_ap down
                ifconfig $ifname_5Ghigh_fronthaul_ap up
                echo "hyd_unmanaged_ap_hband5g $hyd_unmanaged_ap_hband5g" >/dev/console
                /bin/config set "$hyd_unmanaged_ap_hband5g"=0
                wlan updateconf
                /etc/init.d/hyd restart
            fi

            if [ -n "$hband5g_guest_not_connected" -a "$enable_5G_guestnetwork" -eq '1' ]; then
                echo "[$0]Bring 5G high band GUEST interface up" > /dev/console
                ifconfig $ifname_5Ghigh_guest_ap down
                ifconfig $ifname_5Ghigh_guest_ap up
                /bin/config set "$hyd_unmanaged_guest_hband5g"=0
                wlan updateconf
                /etc/init.d/hyd restart
            elif [ -z "$hband5g_guest_not_connected" -a "$enable_5G_guestnetwork" != '1' ]; then
                ifconfig $ifname_5Ghigh_guest_ap down
                /bin/config set "$hyd_unmanaged_guest_hband5g"=1
                wlan updateconf
                /etc/init.d/hyd restart
            fi

            if [ -n "$hband5g_byod_not_connected" -a "$enable_5G_byodnetwork" -eq '1' ]; then
                echo "[$0]Bring 5G high band BYOD interface up" > /dev/console
                ifconfig $ifname_5Ghigh_byod_ap down
                ifconfig $ifname_5Ghigh_byod_ap up
                /bin/config set "$hyd_unmanaged_byod_hband5g"=0
                wlan updateconf
                /etc/init.d/hyd restart
            elif [ -z "$hband5g_byod_not_connected" -a "x$enable_5G_byodnetwork" = 'x0' ]; then
                ifconfig $ifname_5Ghigh_byod_ap down
                /bin/config set "$hyd_unmanaged_byod_hband5g"=1
                wlan updateconf
                /etc/init.d/hyd restart
            fi

        elif [ "$triband_mode" -eq '0' ]; then
            if [ -z "$hband5g_ap_not_connected" ]; then
                echo "[$0]Bring 5G high band AP interface down" > /dev/console
                ifconfig $ifname_5Ghigh_fronthaul_ap down
                /bin/config set "$hyd_unmanaged_ap_hband5g"=1
                wlan updateconf
                /etc/init.d/hyd restart
            fi

            if [ -z "$hband5g_guest_not_connected" ]; then
                echo "[$0]Bring 5G high band GUEST interface down" > /dev/console
                ifconfig $ifname_5Ghigh_guest_ap down
                /bin/config set "$hyd_unmanaged_guest_hband5g"=1
                wlan updateconf
                /etc/init.d/hyd restart
            fi

            if [ -z "$hband5g_byod_not_connected" ]; then
                echo "[$0]Bring 5G high band BYOD interface donw" > /dev/console
                ifconfig $ifname_5Ghigh_byod_ap down
                /bin/config set "$hyd_unmanaged_byod_hband5g"=1
                wlan updateconf
                /etc/init.d/hyd restart
            fi
        fi
    fi

fi

if [ "`cat /tmp/orbi_type`" = "Satellite" -a  "x`ps|grep "wpa_supplicant "|grep -v grep`" = "x" ];then
	wl2g_backhaul_sta=`config get wl2g_BACKHAUL_STA`
	wl5g_backhaul_sta=`config get wl5g_BACKHAUL_STA`
    echo "[$0]wpa_supplicant disappear ,restart it" >/dev/console
    killall wpa_cli
    rm -f /var/run/wpa_supplicant-global.pid
    wpa_supplicant -g /var/run/wpa_supplicantglobal -B -P /var/run/wpa_supplicant-global.pid
    ifconfig $wl5g_backhaul_sta up
    ifconfig $wl2g_backhaul_sta up
    wpa_cli -g /var/run/wpa_supplicantglobal interface_add  $wl5g_backhaul_sta /var/run/wpa_supplicant-${wl5g_backhaul_sta}.conf athr /var/run/wpa_supplicant-$wl5g_backhaul_sta "" br0
    wpa_cli -g /var/run/wpa_supplicantglobal interface_add  $wl2g_backhaul_sta /var/run/wpa_supplicant-${wl2g_backhaul_sta}.conf athr /var/run/wpa_supplicant-$wl2g_backhaul_sta "" br0
fi


if [ ! -f "$wlan_updown_lock" ];then
    sleep 10
    [ -f $wlan_updown_lock ] && continue
    #get backhaul interface
    ifname_backhaul_ap=`config get wl5g_BACKHAUL_AP`" "`config get wl2g_BACKHAUL_AP`
    if [ "x`uci get repacd.repacd.Role`" = "xCAP" ];then
        ifname_backhaul_sta=
    else
        ifname_backhaul_sta=`config get wl5g_BACKHAUL_STA`" "`config get wl2g_BACKHAUL_STA`
    fi

    #get fronthaul interface
    enable_24G=`config get endis_wl_radio`
    enable_5G=`config get endis_wla_2nd_radio`
    wifischedule_24G=`config get wladv_schedule_enable`
    wifischedule_5G=`config get wladv_schedule_enable_a`
    ifname_fronthaul_ap=
    ifname_guestnetwork_ap=
    if [ "$enable_24G" -eq '1'  ]; then
        ifname_fronthaul_ap=$ifname_fronthaul_ap" "`config get wl2g_NORMAL_AP`
        ifname_guestnetwork_ap=$ifname_guestnetwork_ap" "`config get wl2g_GUEST_AP`
    fi
    if [ "$enable_5G" -eq '1'   ]; then
        ifname_fronthaul_ap=$ifname_fronthaul_ap" "`config get wl5g_NORMAL_AP`
        ifname_guestnetwork_ap=$ifname_guestnetwork_ap" "`config get wl5g_GUEST_AP`
    fi


    if [  "x`ps|grep "hostapd "|grep -v grep`" = "x"  ];then
        wifi_restart_event athx "hostapd disappear!!!!"
        wifi_nowork=1
    fi
    if [ "x$wifi_nowork" = "x1" ];then
        wifi_nowork=0
        continue
    fi
    ifnamelist=$ifname_fronthaul_ap" "$ifname_backhaul_sta" "$ifname_backhaul_ap" "$ifname_guestnetwork_ap
    for ifname in $ifnamelist
    do
        if [ "x`iwconfig $ifname 2>/dev/null |grep ESSID`" = "x" ];then
            wifi_restart_event $ifname "interface diappeared!!!!"
            wifi_nowork=1
            break
        fi
    done
    if [ "x$wifi_nowork" = "x1" ];then
        wifi_nowork=0
        continue
    fi
    ifnamelist=$ifname_backhaul_sta" "$ifname_backhaul_ap
    for ifname in $ifnamelist
    do
        if [ "x`ifconfig $ifname 2>/dev/null |grep UP`" = "x" ];then
            wifi_restart_event $ifname "backhaul interface not up!!!!"
            wifi_nowork=1
            break
        fi
    done
    if [ "x$wifi_nowork" = "x1" ];then
        wifi_nowork=0
        continue
    fi
    ifnamelist=$ifname_backhaul_ap
    for ifname in $ifnamelist
    do
        if [ "x`iwconfig $ifname 2>/dev/null|grep 'Not-Associated'`" != "x" ];then
            wifi_restart_event $ifname "backhaul ap interface Not-Associated!!!!"
            wifi_nowork=1
            break
        fi
    done
    if [ "x$wifi_nowork" = "x1" ];then
        wifi_nowork=0
        continue
    fi

fi
# check whether wireless basic setting 2G/5G not match
match_wireless_basic_setting

if [ "x`/bin/config get wlg_setup_endis_setupNet`" != "x1" ];then

    backhaul_ap_2g=`config get wl2g_BACKHAUL_AP`
    backhaul_ap_5g=`config get wl5g_BACKHAUL_AP`
    normal_2g_ap_managed=`cat /tmp/hyd-0.conf | grep -e 'ManagedInterfacesList' | grep -e "$wl2g_fronthaul:WLAN"`
    normal_5g_ap_managed=`cat /tmp/hyd-0.conf | grep -e 'ManagedInterfacesList' | grep -e "$wl5g_fronthaul:WLAN"`
    backhaul_2g_ap_managed=`cat /tmp/hyd-0.conf | grep -e 'ManagedInterfacesList' | grep -e "$backhaul_ap_2g:WLAN"`
    backhaul_5g_ap_managed=`cat /tmp/hyd-0.conf | grep -e 'ManagedInterfacesList' | grep -e "$backhaul_ap_5g:WLAN"`

    if [ -z "$normal_2g_ap_managed" ] || [ -z "$normal_5g_ap_managed" ] || [ -z "$backhaul_2g_ap_managed" ] || [ -z "$backhaul_5g_ap_managed" ]; then
        echo "######## restart hyd due to hyd-0.conf lost data of ManagedInterfacesList #######" > /dev/console
        /etc/init.d/hyd restart
    fi

    normal_2g_ap_Wlan=`cat /tmp/hyd-0.conf | grep -e 'WlanInterfaces' | grep -e "$wl2g_fronthaul"`
    normal_5g_ap_Wlan=`cat /tmp/hyd-0.conf | grep -e 'WlanInterfaces' | grep -e "$wl5g_fronthaul"`

    if [ -z "$normal_2g_ap_Wlan" ] || [ -z "$normal_5g_ap_Wlan" ]; then
        echo "####### restart hyd due to hyd-0.conf lost data of WlanInterfaces #######" > /dev/console
        /etc/init.d/hyd restart
    fi

    if [ "$triband_mode"  -eq '1' ]; then
        normal_5g_2nd_ap_managed=`cat /tmp/hyd-0.conf | grep -e 'ManagedInterfacesList' | grep -e "$wl5g_2nd_fronthaul:WLAN"`
        normal_5g_2nd_ap_Wlan=`cat /tmp/hyd-0.conf | grep -e 'WlanInterfaces' | grep -e "$wl5g_2nd_fronthaul"`
        if [ -z "$normal_5g_2nd_ap_managed" ]; then
            echo "######## restart hyd due to hyd-0.conf lost data of ManagedInterfacesList #######" > /dev/console
            /etc/init.d/hyd restart
        elif [ -z "$normal_5g_2nd_ap_Wlan" ]; then
            echo "####### restart hyd due to hyd-0.conf lost data of WlanInterfaces #######" > /dev/console
            /etc/init.d/hyd restart
        fi
    fi
fi

done
