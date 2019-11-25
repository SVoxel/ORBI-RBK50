#!/bin/sh

cmd="${0##*/}"
wan_if="eth0"
result_file="/tmp/ookla_speedtest_result"

cmd_usage()
{
	printf "%s\n" \
		"Usage:	$cmd run|cancel|isrunning" \
		"" \
		"  run		run once test by ookla powered by speedtest." \
		"  cancel	cancel any running speedtest process." \
		"  isrunning	check if one ookla process is running now."
}

trun_wan_gro_on()
{
	[ "$(ethtool -k "$wan_if" | awk '/generic-receive-offload/ {print $2}')" = "off" ] \
		&& ethtool -K "$wan_if" gro on
}

trun_wan_gro_off()
{
	[ "$(ethtool -k "$wan_if" | awk '/generic-receive-offload/ {print $2}')" = "off" ] \
		|| ethtool -K "$wan_if" gro off
}

task_run()
{
	trun_wan_gro_on
	ethtool -k "$wan_if"
	ookla --configurl=http://www.speedtest.net/api/embed/netgear/config \
		--tracelevel=1 > /tmp/ookla_speedtest_result
	trun_wan_gro_off
	ethtool -k "$wan_if"
}

task_cancel()
{
	kill -9 "$(pidof ookla)" 2>/dev/null && rm -f "$result_file"
	trun_wan_gro_off
}

task_isrunning()
{
	[ -n "$(pidof ookla)" ] && printf "yes" || printf "no"
}

case "$1" in
	"run")
		task_run ;;
	"cancel")
		task_cancel ;;
	"isrunning")
		task_isrunning ;;
	*)
		cmd_usage
		exit 255 ;;
esac
