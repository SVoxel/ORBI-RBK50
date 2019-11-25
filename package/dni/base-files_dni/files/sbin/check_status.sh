#! /bin/sh
#Check config var streamboost_enable every hour
update_count=0
while :; do
	sleep 60
	update_count=$(($update_count + 1))
	if [ $update_count = 3 ]; then
		update_count=0
		if [ "x`/bin/config get enable_circle_plc`" = "x1" -a "x`/bin/config get ap_mode`" = "x0" ]; then
			/bin/config set "save_circle_info=1"
			killall -SIGUSR1 net-scan
		fi
	fi
	streamboost_enable=`/bin/config get streamboost_enable`
	if [ "x$streamboost_enable" = "x1" ];then
		streamboost status > /tmp/streamboost_status
		downnum=`cat /tmp/streamboost_status |grep DOWN |wc -l`
		if [ "$downnum" != "0" ] && [ "$downnum" -lt "10" ]; then
			/etc/init.d/streamboost restart
			time=`date '+%Y-%m-%dT%H:%M:%SZ'`
			echo "Restart streamboost:$time" >> /tmp/restart_process_list
		fi
	fi

	if [ "$update_count" = "1" ]; then
		new_whatchdog_value=`cat /tmp/soapclient/watchdog_time`
		if [ "$(cat /tmp/orbi_type)" = "Base" ] && [ "$new_whatchdog_value" = "$old_whatchdog_value" ]; then
			echo "********soap_agent watchdog restarting*********" 
			killall -9 soap_agent
			time=`date '+%Y-%m-%dT%H:%M:%SZ'`
			echo "Watchdog Restart soap_agent:$time" >> /var/log/soapclient/soap_agent_restart
			/usr/sbin/soap_agent &
		fi
		old_whatchdog_value=$new_whatchdog_value
	fi
	
	detcable_status=`ps | grep detcable | grep -v grep`
	if [ -z "$detcable_status" ] && [ "$(cat /tmp/orbi_type)" = "Base" ];then
		killall detcable
		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
		echo "Restart detcable:$time" >> /tmp/restart_process_list
		/usr/bin/detcable 2 Base &
	fi
	
	dnsmasq_status=`ps | grep dnsmasq | grep -v grep`
	if [ -z "$dnsmasq_status" ] && [ "$(cat /tmp/orbi_type)" = "Base" ];then
		killall dnsmasq
		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
		echo "Restart dnsmasq:$time" >> /tmp/restart_process_list
		/etc/init.d/dnsmasq start&
	fi

	netscan_status=`ps | grep net-scan | grep -v grep | grep -v killall`
	if [ -z "$netscan_status" ];then
		killall -9 net-scan
		time=`date '+%Y-%m-%dT%H:%M:%SZ'`
		echo "Restart net-scan:$time" >> /tmp/restart_process_list
		/usr/sbin/net-scan
	fi
	log_size=`wc -c /tmp/dnsmasq.log |awk '{print $1}'`
	if [ $log_size -gt 1048576 ]; then
		echo -n > /tmp/dnsmasq.log
	fi
	if [ "x`/bin/config get disable_ping_protect`" != "x1" ] && [ "$(cat /tmp/orbi_type)" = "Base" ];then
		ping_status=`ps | grep ping-netgear | grep -v grep`
		if [ -z "$ping_status" ]; then
			ping_count=$(($ping_count+1))
			if [ $ping_count = 5 ];then
				echo "****************Start ping-netgear By chekc_status********************" > /dev/console
				/sbin/ping-netgear &
				time=`date '+%Y-%m-%dT%H:%M:%SZ'`
				echo "Restart ping-netgear:$time" >> /tmp/restart_process_list
				ping_count=0
			fi
		else
			ping_count=0
		fi
	fi
	if [ "x`/bin/config get wan_proto`" != "xmulpppoe1" ];then
		pppdv4_ps_count=`ps  |grep "pppd call dial-provider updetach" | grep -v grep |wc -l`
		pppdv6_ps_count=`ps  |grep "pppd call pppoe-ipv6 updetach" | grep -v grep |wc -l`
		if [ $pppdv4_ps_count -gt "1" -o $pppdv6_ps_count -gt "1" ] ;then
			killall pppd
			if [ $pppdv4_ps_count -gt "0" ];then
				pppd call dial-provider updetach
			fi
			if [ $pppdv6_ps_count -gt "0" ];then
                                /usr/sbin/pppd call pppoe-ipv6 updetach
                        fi
		fi
	fi

done

