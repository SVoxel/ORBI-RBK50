#!/bin/sh

mtd_oops="$(part_dev crashinfo)"

echo "Save the collect log into debug-log.zip and upload to user"

#Disblae wireless debug log
wl5g_NORMAL_AP=$(/bin/config get wl5g_NORMAL_AP)
wl2g_NORMAL_AP=$(/bin/config get wl2g_NORMAL_AP)
wl5g_BACKHAUL_AP=$(/bin/config get wl5g_BACKHAUL_AP)
wl2g_BACKHAUL_AP=$(/bin/config get wl2g_BACKHAUL_AP)
wl5g_BACKHAUL_STA=$(/bin/config get wl5g_BACKHAUL_STA)
wl2g_BACKHAUL_STA=$(/bin/config get wl2g_BACKHAUL_STA)

iwpriv $wl5g_NORMAL_AP dbgLVL 0x0
iwpriv $wl2g_NORMAL_AP dbgLVL 0x0
iwpriv $wl5g_BACKHAUL_AP dbgLVL 0x0
iwpriv $wl2g_BACKHAUL_AP dbgLVL 0x0
iwpriv $wl5g_BACKHAUL_STA dbgLVL 0x0
iwpriv $wl2g_BACKHAUL_STA dbgLVL 0x0
module_name=`cat /module_name`

# Save the router config file
/bin/config backup /tmp/NETGEAR_$module_name.cfg

#/sbin/debug_save_panic_log $mtd_oops

cd /tmp

# System will zipped all debug files into 1 zip file and save to client browser
# So a debug-log.zip file will includes
# (1) Console log
# (2) Basic debug information
# (3) router config file
# (4) LAN/WAN packet capture
# (5) thermal log
# (6) debug here log of hyt 

#Disable the capture
killall tcpdump
killall tcpdump
killall basic_log.sh 
killall console_log.sh 
killall wireless_log.sh  
killall thermal_log.sh  
killall debug_here_log.sh
killall logread_log.sh
killall logread
killall debug_circle.sh
killall arlo_log.sh  
killall wireless_client_statistic_log.sh
echo 0 > /sys/module/qca_ol/parameters/host_dbgshow
/bin/config set netscan_debug=0

#AS long as user click "Save logs" form debug page, the current HYCTL log should be generated and captured
if [ -f /tmp/wireless-log1.txt ]; then
	echo "AS long as user click "Save logs" form debug page, the current HYCTL log should be generated and captured" >>/tmp/wireless-log1.txt
	echo -n "gethatbl:" >>/tmp/wireless-log1.txt;	hyctl gethatbl br0 1000 >>/tmp/wireless-log1.txt	
	echo -n "gethdtbl:" >>/tmp/wireless-log1.txt;   hyctl gethdtbl br0 100 >>/tmp/wireless-log1.txt	
	echo -n "getfdb:" >>/tmp/wireless-log1.txt;   hyctl getfdb br0 100 >>/tmp/wireless-log1.txt
elif [ -f /tmp/wireless-log2.txt ]; then
	echo "AS long as user click "Save logs" form debug page, the current HYCTL log should be generated and captured" >> /tmp/wireless-log2.txt
	echo -n "gethatbl:" >>/tmp/wireless-log2.txt;	hyctl gethatbl br0 1000 >>/tmp/wireless-log2.txt	
	echo -n "gethdtbl:" >>/tmp/wireless-log2.txt;   hyctl gethdtbl br0 100 >>/tmp/wireless-log2.txt	
	echo -n "getfdb:" >>/tmp/wireless-log2.txt;   hyctl getfdb br0 100 >>/tmp/wireless-log2.txt
fi
	

echo close > /sys/devices/platform/serial8250/console

collect_log=`cat /tmp/collect_debug`

if [ "x$collect_log" = "x0" ];then
	/sbin/basic_log.sh &
	sleep 20
	killall basic_log.sh 
fi


[ -f /tmp/panic_log.txt ] || dd if=$mtd_oops of=/tmp/panic_log.txt bs=131072 count=2
[ -f /tmp/panic_log.txt ] && unix2dos /tmp/panic_log.txt
#[ -f /tmp/Panic-log.txt ] && unix2dos /tmp/Panic-log.txt
[ -f /tmp/Console-log1.txt ] && unix2dos /tmp/Console-log1.txt
[ -f /tmp/Console-log2.txt ] && unix2dos /tmp/Console-log2.txt 
[ -f /tmp/logread-log1.txt ] && unix2dos /tmp/logread-log1.txt
[ -f /tmp/logread-log2.txt ] && unix2dos /tmp/logread-log2.txt
[ -f /tmp/wireless-log1.txt ] && unix2dos /tmp/wireless-log1.txt 
[ -f /tmp/wireless-log2.txt ] && unix2dos /tmp/wireless-log2.txt 
[ -f /tmp/basic_debug_log.txt ] && unix2dos /tmp/basic_debug_log.txt
[ -d /tmp/soapclient ] && unix2dos /tmp/soapclient/*
[ -d /var/log/soapclient ] && unix2dos /var/log/soapclient/*
[ -f /var/log/soapapp ] && unix2dos /var/log/soapapp
[ -f /tmp/hyt_result ] && unix2dos /tmp/hyt_result
[ -f /tmp/satellite_status ] && unix2dos /tmp/satellite_status
[ -e /tmp/radardetect.log ] && RADARLOG=radardetect.log
[ -f /tmp/thermal-log1.txt ] && unix2dos /tmp/thermal-log1.txt
[ -f /tmp/thermal-log2.txt ] && unix2dos /tmp/thermal-log2.txt

[ -f /tmp/debug_here_log_1.txt ] && unix2dos /tmp/debug_here_log_1.txt
[ -f /tmp/debug_here_log_2.txt ] && unix2dos /tmp/debug_here_log_2.txt
[ -f /tmp/arlo-log1.txt ] && unix2dos /tmp/arlo-log1.txt 
[ -f /tmp/arlo-log2.txt ] && unix2dos /tmp/arlo-log2.txt 
[ -f /tmp/wireless-client-statistic1.txt ] && unix2dos /tmp/wireless-client-statistic1.txt
[ -f /tmp/wireless-client-statistic2.txt ] && unix2dos /tmp/wireless-client-statistic2.txt

if [ "`/bin/config get enable_arlo_function`" = "1" ];then
    if [ "`cat /tmp/orbi_type`" = "Base" ];then
    cp /tmp/xagent.log /tmp/xagent.log1
    cp /tmp/system-log /tmp/system-log1
    cp /tmp/system-log.0 /tmp/system-log2
    xagent_log=/tmp/xagent.log1
    system_log=/tmp/system-log1
    system_log2=/tmp/system-log2
    cp /tmp/arlo/arlo_list /tmp/arlo_list
    arlo_list=/tmp/arlo_list
    fi
    arlo_log1=/tmp/arlo-log1.txt
    arlo_log2=/tmp/arlo-log2.txt
fi

if [ "`/bin/config get dgc_func_have_armor`" = "1" ];then
    if [ "`cat /tmp/orbi_type`" = "Base" ];then
		cd /tmp/
		tar -zcvf armor.tar.gz /tmp/upagent.log /tmp/UpAgent.log /tmp/ash.log /tmp/bitdefender_logs.tar.gz
		armor_log="/tmp/armor.tar.gz"
	fi
fi

if [ "x$collect_log" = "x1" ];then
	zip debug-log.zip  NETGEAR_$module_name.cfg panic_log.txt /firmware_version Console-log1.txt Console-log2.txt logread-log1.txt logread-log2.txt thermal-log1.txt thermal-log2.txt basic_debug_log.txt wireless-log1.txt wireless-log2.txt wireless-client-statistic1.txt wireless-client-statistic2.txt lan.pcap wan.pcap arlo.pcap soapclient/* /var/log/soapclient/* /var/log/soapapp hyt_result satellite_status hyd-restart.log wsplcd-restart.log debug_here_log_1.txt debug_here_log_2.txt dhcpd_hostlist /var/log/netscan/* device_tables/local_device_table $RADARLOG /tmp/auto_fw_upgrade_log* /tmp/soap_check_fw_log* /tmp/wifi0.caldata /tmp/wifi1.caldata /tmp/wifi2.caldata /tmp/debug_circle.zip $xagent_log $system_log $system_log2 $arlo_log1 $arlo_log2 $arlo_list $armor_log /tmp/ookla_speedtest_result /tmp/dal/d2d/* /tmp/dal_ash.log /tmp/dalh.log /tmp/upagent.log /tmp/dil.log /tmp/bst.log
else
	zip debug-log.zip NETGEAR_$module_name.cfg  panic_log.txt /firmware_version Console-log1.txt Console-log2.txt logread-log1.txt logread-log2.txt thermal-log1.txt thermal-log2.txt wireless-log1.txt wireless-log2.txt wireless-client-statistic1.txt wireless-client-statistic2.txt basic_debug_log.txt lan.pcap wan.pcap arlo.pcap soapclient /var/log/soapclient/* /var/log/soapapp hyt_result satellite_status hyd-restart.log wsplcd-restart.log debug_here_log_1.txt debug_here_log_2.txt dhcpd_hostlist /var/log/netscan/* device_tables/local_device_table $RADARLOG /tmp/auto_fw_upgrade_log* /tmp/soap_check_fw_log* /tmp/wifi0.caldata /tmp/wifi1.caldata /tmp/wifi2.caldata /tmp/debug_circle.zip $xagent_log $system_log $system_log2 $arlo_log1 $arlo_log2 $arlo_list $armor_log /tmp/ookla_speedtest_result /tmp/dal/d2d/* /tmp/dal_ash.log /tmp/dalh.log /tmp/upagent.log /tmp/dil.log /tmp/bst.log
fi

cd /tmp
rm -rf debug-usb debug_cpu debug_flash debug_mem debug_mirror_on debug_session NETGEAR_$module_name.cfg panic_log.txt Console-log1.txt Console-log2.txt logread-log1.txt logread-log2.txt thermal-log1.txt thermal-log2.txt basic_debug_log.txt lan.pcap wan.pcap arlo.pcap wireless-log1.txt wireless-log2.txt wireless-client-statistic1.txt wireless-client-statistic2.txt /var/log/soapapp debug_here_log_1.txt debug_here_log_2.txt debug_circle* $xagent_log $system_log $system_log2 $arlo_log1 $arlo_log2 $arlo_list $armor_log


echo 0 > /tmp/collect_debug
