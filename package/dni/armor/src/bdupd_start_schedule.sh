#! /bin/sh

	echo "-----------------------bdupd schedule start-----------------------" > /dev/console

	[ "x$(ps -w|grep {bdupd_start.sh} |grep -v grep)" != "x" ]&& exit 0
	/usr/share/armor/bdupd_start.sh day-check &

