#!/bin/sh

WAN_PORTMAP="0x02"

wired_get_linkspeed(){
	local _linkspeed
	local gw_switch_port
	gw_mac=$1

	if [ "$(/bin/config get i_opmode)" = "apmode" ]; then
	# AP Mode
	portmap=`swconfig dev switch0 get dump_arl | grep -i $gw_mac | grep -v "PORTMAP: 0x01" | grep -wE "VID: 0x1|VID: 0x2" | awk '{print $4}'`
	else
	# Normal Mode
	portmap=`swconfig dev switch0 get dump_arl | grep -i $gw_mac | grep -v "PORTMAP: 0x01" | grep -wE "VID: 0x1" | awk '{print $4}'`
	
	# If Get Port Map is WAN Port for Some Unknown Reason, IGNORE, return null
	[ "$portmap" = "$WAN_PORTMAP" ] && echo -n "" && return
	fi

	# if no find the Device MAC on ARL Table expect CPU Port, return null
	[ "x$portmap" = "x"  ] && echo -n "" && return

	case $portmap in
		0x02) gw_switch_port=1;; # Port #1
		0x04) gw_switch_port=2;; # Port #2
		0x08) gw_switch_port=3;; # Port #3
		0x10) gw_switch_port=4;; # Port #4
		0x20) gw_switch_port=5;; # Port #5
		*) gw_switch_port="";;
	esac

	# if find one invalid switch port id, return null
	[ "x$gw_switch_port" = "x" ] && echo -n "" && return

	_linkspeed=$(swconfig dev switch0 port $gw_switch_port get link 2>&1 | awk  '{print $3}' | tr -cd '0-9')
	# there is a situation, if a swith connect to DUT, and PC connect to switch, we cannot get link speed by PC's MAC
	[ "x$_linkspeed" = "x" ] && _linkspeed=0
	echo -n "$_linkspeed"
}

wired_get_linkspeed $1 2>/dev/null
