#!/bin/sh

nvram="/bin/config"
netwall="/usr/sbin/net-wall"
fw_sh="/www/cgi-bin/firewall_function.sh"

firewall_stop()
{
	$netwall stop
}

firewall_start()
{
	$fw_sh sched_rule
	$netwall start
	[ "$($nvram get ipv6_type)" != "disabled" ] && $netwall -6 start
}

config_net_wall()
{
	if [ "$1" = "lan_setup" -o "$1" = "wan_setup" -o "$1" = "remote_management" -o "$1" = "port_forward" -o "$1" = "RADIUS" -o "$1" = "tr069_setup" ] ; then
		$netwall rule
	fi
}

case "$1" in
	stop)
		firewall_stop
	;;
	start)
		config_net_wall "$($nvram get forfirewall)"
		firewall_start
		$nvram set forfirewall=0
	;;
	restart)
		config_net_wall "$($nvram get forfirewall)"
		firewall_start
		$nvram set forfirewall=0
		if [ "$(config get forceshield_reset_flag)" = "0" ]; then
			if [ "$(config get remote_endis)" = "1" ]; then
				cd /media/nand
				./dap_port_reinit.sh
				./dap service restart
			fi
		fi
	;;
	*)
		logger -- "I donnt know what you want the firewall to do"
	;;
esac

