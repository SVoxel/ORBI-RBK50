#!/bin/sh

# Collect basi debug information

#One time check
echo "-----------------------cpuinfo-----------------------" >> /tmp/basic_debug_log.txt
cat /proc/cpuinfo >> /tmp/basic_debug_log.txt
echo "-----------------------openwrt_release---------------" >> /tmp/basic_debug_log.txt
cat /etc/openwrt_release >> /tmp/basic_debug_log.txt
echo "-----------------------uci value---------------------" >> /tmp/basic_debug_log.txt
uci show >> /tmp/basic_debug_log.txt

while [ 1 ]
do
echo "======================Run time check======================" >> /tmp/basic_debug_log.txt
date=`date`
uptime=`uptime`
echo "-----------------------date:$date----------------------" >> /tmp/basic_debug_log.txt
echo "-----------------------uptime:$uptime----------------------" >> /tmp/basic_debug_log.txt
echo "-----------------------ifconfig----------------------" >> /tmp/basic_debug_log.txt
	ifconfig >> /tmp/basic_debug_log.txt 
echo "-----------------------meminfo-----------------------" >> /tmp/basic_debug_log.txt
	cat /proc/meminfo >> /tmp/basic_debug_log.txt
echo "-----------------------slabinfo----------------------" >> /tmp/basic_debug_log.txt
	cat /proc/slabinfo >> /tmp/basic_debug_log.txt		
echo "-----------------------interrupts--------------------" >> /tmp/basic_debug_log.txt
	cat /proc/interrupts >> /tmp/basic_debug_log.txt		
echo "-----------------------vmstat------------------------" >> /tmp/basic_debug_log.txt
	cat /proc/vmstat >> /tmp/basic_debug_log.txt		
echo "-----------------------sar 1 1-----------------------" >> /tmp/basic_debug_log.txt
	sar 1 1 >> /tmp/basic_debug_log.txt		
echo "-----------------------ps -l -ww------------------------" >> /tmp/basic_debug_log.txt
	ps -l -ww>> /tmp/basic_debug_log.txt
echo "-----------------------free--------------------------" >> /tmp/basic_debug_log.txt
	free >> /tmp/basic_debug_log.txt
echo "-----------------------resolve.conf------------------" >> /tmp/basic_debug_log.txt
	cat /tmp/resolv.conf >> /tmp/basic_debug_log.txt
echo "-----------------------route-------------------------" >> /tmp/basic_debug_log.txt
	route >> /tmp/basic_debug_log.txt
echo "-----------------------arp---------------------------" >> /tmp/basic_debug_log.txt
	cat /proc/net/arp >> /tmp/basic_debug_log.txt
	echo -n "nf_conntrack_count=" >> /tmp/basic_debug_log.txt; cat /proc/sys/net/netfilter/nf_conntrack_count >> /tmp/basic_debug_log.txt
echo "--------------tc -s qdisc show dev ethX--------------" >> /tmp/basic_debug_log.txt
	tc -s qdisc show dev eth0 >> /tmp/basic_debug_log.txt
	tc -s qdisc show dev eth1 >> /tmp/basic_debug_log.txt

echo "-----------------------brctl showmacs br0--------------" >> /tmp/basic_debug_log.txt
	brctl showmacs br0 >> /tmp/basic_debug_log.txt
	killall -SIGUSR2 net-scan;

echo "-----------------------iwconfig----------------------" >> /tmp/basic_debug_log.txt
	iwconfig >> /tmp/basic_debug_log.txt 
echo "-------------(echo "td s2"; sleep 2)| hyt-------------" >> /tmp/basic_debug_log.txt
	(echo "td s2"; sleep 2)| hyt >> /tmp/basic_debug_log.txt 
echo "---------(echo "stadb s"; sleep 2) | hyt-------------" >> /tmp/basic_debug_log.txt
	(echo "stadb s"; sleep 2) | hyt >> /tmp/basic_debug_log.txt 
echo "---------(echo "stadb s bss"; sleep 2) | hyt-------------" >> /tmp/basic_debug_log.txt
	(echo "stadb s bss"; sleep 2) | hyt >> /tmp/basic_debug_log.txt 
echo "---------(echo "stadb s phy"; sleep 2) | hyt-------------" >> /tmp/basic_debug_log.txt
	(echo "stadb s phy"; sleep 2) | hyt >> /tmp/basic_debug_log.txt 
echo "---------(echo "stadb s rate"; sleep 2) | hyt------------" >> /tmp/basic_debug_log.txt
	(echo "stadb s rate"; sleep 2) | hyt >> /tmp/basic_debug_log.txt 
echo "---------(echo "steerexec s"; sleep 2) | hyt------------" >> /tmp/basic_debug_log.txt
	(echo "steerexec s"; sleep 2) | hyt >> /tmp/basic_debug_log.txt 

echo "-----------------------Attached devices--------------" >> /tmp/basic_debug_log.txt
	killall -SIGUSR1 net-scan;sleep 2;
	cat /tmp/netscan/attach_device >> /tmp/basic_debug_log.txt
	have_scan=`cat /tmp/log/netscan/* |grep "Send ARP"`
	[ "$have_scan" = "" ] && killall -SIGUSR2 net-scan

echo "---------(echo "dbg here"; sleep 5) | hyt------------" >> /tmp/basic_debug_log.txt
	(echo "dbg here"; sleep 5) | hyt >> /tmp/basic_debug_log.txt

	m_name=`cat /tmp/orbi_type`
	if [ "$m_name" = "Satellite" ]; then
		echo "-----------------------ping to see the uplink status-------------------" >> /tmp/basic_debug_log.txt
		echo "When gather log on Satellite, try to ping gateway 3 times to see the uplink status" >> /tmp/basic_debug_log.txt
		local RBR_IP=`/bin/config get lan_gateway`
		if [ "$RBR_IP" = "0.0.0.0" ]; then
			echo "Warning: Satellite find the value of lan_gateway is 0.0.0.0" >> /tmp/basic_debug_log.txt
		else
			for i in 1 2 3
			do
				ping $RBR_IP -c 3 >> /tmp/basic_debug_log.txt
			done
		fi
	fi
	
	echo "========================next loop==================================" >> /tmp/basic_debug_log.txt

	sleep 30

	filesize=`ls -l /tmp/basic_debug_log.txt | awk '{print $5}'`
	if [ $filesize -ge 5242880 ]; then
		echo "filesize if over, rm basic_debug_log.txt"
		rm -rf /tmp/basic_debug_log.txt
	fi
done

