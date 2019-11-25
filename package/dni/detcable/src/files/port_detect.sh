#!/bin/sh
CONFIG=/bin/config

add_rule()
{
	mac=$1
	[ "x$mac" = "x" ] && exit 0
	mac=`echo ":$mac" | sed 's/:0/:/g' | cut -d ':' -f2-`

	ebtables -t broute -L |grep -i 0x893a |grep -i "$mac" |grep -i DROP > /tmp/deny_rules
	while read loop
	do
		if [ "$loop" != "" ]; then
			rm  /tmp/deny_rules
			 exit 0
		fi
	done < /tmp/deny_rules
	rm  /tmp/deny_rules

	/usr/sbin/ebtables -t broute -A BROUTING -p 0x893a -s $mac -j DROP
}

del_rule()
{
	mac=$1
	[ "x$mac" = "x" ] && exit 0
	[ "x$mac" = "xall" ] && mac=""
	mac=`echo ":$mac" | sed 's/:0/:/g' | cut -d ':' -f2-`
	ebtables -t broute -L | grep -i 0x893a |grep -i "$mac" |grep -i DROP > /tmp/deny_rules
	while read loop
	do
		if [ "$loop" != "" ]; then
			/usr/sbin/ebtables -t broute -D BROUTING $loop
		fi
	done < /tmp/deny_rules
	rm  /tmp/deny_rules
}

port_up()
{
	echo "port $1 up !!!!" >/dev/console
}

case "$1" in
	up)
		port_up $2
	;;
	add)
		add_rule $2
	;;
	del)
		del_rule $2
	;;
	show)
		ebtables -t broute -L
	;;
	*)
		logger -- "usage: $0 up port_id"
	;;
esac

