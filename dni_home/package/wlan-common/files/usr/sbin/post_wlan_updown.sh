#!/bin/sh

#This script is for customize actions after wlan up/down per projects or platform


if [ "$1" = "enable" ]; then
    echo "[wlan]=========time:`date` wlan post up ==================" >/dev/console
    [ -f "/etc/init.d/netscan_if.init" ] && {
        echo "[wlan]========= reload netscan ==================" >/dev/console
        /etc/init.d/netscan reload
    }
    echo "`/bin/config get wl2g_ARLO_AP`" > /proc/sys/net/ipv4/arloifname
    
    #set brarlo's interface
    #base:ath2.2 ath01.2
    #satellite:ath2.2 ath21.2 ath01.2 ath02.2
    if [ "`/bin/config get enable_arlo_function`" = "1" ];then
        vid="`/bin/config get wlg_ap_bh_vids`"
        ifname_backhaul_sta_2g="`/bin/config get wl2g_BACKHAUL_STA`"
        ifname_backhaul_sta_5g="`/bin/config get wl5g_BACKHAUL_STA`"
        ifname_backhaul_ap_2g="`/bin/config get wl2g_BACKHAUL_AP`"
        ifname_backhaul_ap_5g="`/bin/config get wl5g_BACKHAUL_AP`"
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 0:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 1:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 2:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 3:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 4:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 5:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 6:5
        ip link set dev $ifname_backhaul_ap_5g.$vid type vlan egress-qos-map 7:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 0:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 1:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 2:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 3:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 4:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 5:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 6:5
        ip link set dev $ifname_backhaul_ap_2g.$vid type vlan egress-qos-map 7:5
        if [ "`cat /tmp/orbi_type`" = "Satellite" ];then
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 0:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 1:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 2:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 3:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 4:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 5:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 6:5
            ip link set dev $ifname_backhaul_sta_5g.$vid type vlan egress-qos-map 7:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 0:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 1:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 2:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 3:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 4:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 5:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 6:5
            ip link set dev $ifname_backhaul_sta_2g.$vid type vlan egress-qos-map 7:5
        fi
    fi

    if [ "x$(/bin/cat /tmp/hw_revision)" = "x02" ]; then
        /sbin/thermal.sh start 86 81 60 &
    fi
fi

if [ "$1" = "disable" ]; then
echo "[wlan]=========time:`date` wlan post down ==================" >/dev/console

    if [ "x$(/bin/cat /tmp/hw_revision)" = "x02" ]; then
        /sbin/thermal.sh stop
    fi


fi
