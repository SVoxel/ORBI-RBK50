#!/bin/sh

CONFIG=/bin/config

local enable_jumbo_frame=`$CONFIG get enable_jumbo_frame`

if [ "$enable_jumbo_frame" = "1" ]; then
	ifconfig eth0 mtu 9000
	ifconfig eth1 mtu 9000
	ifconfig brwan mtu 9000
	ssdk_sh debug reg set 0x78 0x2400 4
elif [ "$enable_jumbo_frame" = "0" ]; then

	local wan_proto=`$CONFIG get wan_proto`
	
	if [ "$wan_proto" = "dhcp" ]; then
		wan_dhcp_mtu=`$CONFIG get wan_dhcp_mtu`
		ifconfig eth0 mtu $wan_dhcp_mtu
		ifconfig eth1 mtu $wan_dhcp_mtu
		ifconfig brwan mtu $wan_dhcp_mtu
		ssdk_sh debug reg set 0x78 0x2400 4
	elif [ "$wan_proto" = "pppoe" ]; then
		wan_pppoe_mtu=`$CONFIG get wan_pppoe_mtu`
		ifconfig eth0 mtu $wan_pppoe_mtu
		ifconfig eth1 mtu $wan_pppoe_mtu
		ifconfig brwan mtu $wan_pppoe_mtu
		ssdk_sh debug reg set 0x78 0x2400 4
	elif [ "$wan_proto" = "l2tp" ]; then                                   
        	wan_l2tp_mtu=`$CONFIG get wan_l2tp_mtu`                       
                ifconfig eth0 mtu $wan_l2tp_mtu                                
                ifconfig eth1 mtu $wan_l2tp_mtu                                
                ifconfig brwan mtu $wan_l2tp_mtu                               
       		ssdk_sh debug reg set 0x78 0x2400 4	
       	elif [ "$wan_proto" = "pptp" ]; then
       		wan_l2tp_mtu=`$CONFIG get wan_pptp_mtu`
       		ifconfig eth0 mtu $wan_pptp_mtu
       		ifconfig eth1 mtu $wan_pptp_mtu
       		ifconfig brwan mtu $wan_pptp_mtu
       		ssdk_sh debug reg set 0x78 0x2400 4
       	fi
fi
