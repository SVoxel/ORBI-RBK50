#!/bin/sh

RAE_DIR=/tmp/router-analytics
INTERVAL=86400
FIRST_RUN=1

ra_daemon_monitor()
{
	if [ "$(/bin/config get ra_monitor_disable)" = "1" ]; then
		echo "RA_Monitor: Configure Setting is Disable, Exit RA Daemon Monitor!!!" >/dev/console
		exit
	fi

	[ "$FIRST_RUN" = "1" ] && FIRST_RUN=0 && sleep 60
	
	if [ -d $RAE_DIR -a -f $RAE_DIR/status -a "$(cat $RAE_DIR/status)" = "1" ]; then
		# RAE Binary Has been Download, No Need RA Daemon Monitor for "ra_check" Process Detection, Exit.
		echo "RA_Monitor: $RAE_DIR/status is $(cat $RAE_DIR/status), Exit RA Daemon Monitor!!!" >/dev/console
		exit
	else
		ra_check_status="$(ps -w | grep ra_check | grep -v grep)"
		if [ "x$ra_check_status" = "x" ]; then
			echo "RA_Monitor: ra_check process disappear, resume ra_check process!!!" >/dev/console
			killall ra_check
			rm /var/run/ra_check.pid >/dev/console
			/usr/sbin/ra_check >/dev/console
		fi
	fi
}

while true
do
	[ "x$(/bin/config get ra_monitor_interval)" != "x" ] && INTERVAL=$(/bin/config get ra_monitor_interval)
	ra_daemon_monitor
	sleep $INTERVAL
done
