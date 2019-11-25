#! /bin/sh /etc/rc.common
get_satellite_ctype()
{
		echo "" > /tmp/hyt_distant_result
		file_flag=0
		write_flag=0
		exit_flag=0
		if [ ! -x /usr/sbin/hyt ]; then
			continue
		fi

		(echo "td s2"; sleep 2) |hyt | while read line
		do
			mac_line=`echo $line |grep '#'`
			if [ "x$mac_line" != "x" ]; then
				mac_line=`echo ${mac_line#*device:}`
				mac=`echo ${mac_line%,*}`
			fi

			relation_line=`echo $line |grep Relation`
			if [ "x$relation_line" != "x" ]; then
				relation=`echo ${relation_line#*Relation:}`
				if [ "x$relation" = "xDistant Neighbor" ]; then
					distant_flag=1
					file_flag=$(($file_flag + 1))
				else
					distant_flag=0
				fi
			fi

			bssid_line=`echo $line |grep BSSID`
			if [ "x$bssid_line" != "x" ]; then
				connection_type=`echo $last_line |grep WLAN5G`
				if [ "x$connection_type" != "x" ]; then
					wlan5g_flag=1
				fi
				connection_type=`echo $last_line |grep WLAN2G`
				if [ "x$connection_type" != "x" ]; then
					wlan2g_flag=1
				fi
			else
				last_line=$line
			fi

			end_line=`echo $line |grep Bridged`
			if [ "x$end_line" != "x" ]; then
				write_flag=1
			fi

			if [ "x$distant_flag" = "x1" ] && [ "x$write_flag" = "x1" ]; then
				write_flag=0
				if [ "x$file_flag" = "x1" ]; then
					echo -n $mac > /tmp/hyt_distant_result
				else
					echo -n $mac >> /tmp/hyt_distant_result
				fi

				if [ "x$wlan5g_flag" = "x1" ]; then
					echo -n " WLAN5G" >> /tmp/hyt_distant_result
				fi

				if [ "x$wlan2g_flag" = "x1" ]; then
					echo -n " WLAN2G" >> /tmp/hyt_distant_result
				fi

				if [ "x$wlan5g_flag" != "x1" ] && [ "x$wlan2g_flag" != "x1" ]; then
					echo -n " ETHER" >> /tmp/hyt_distant_result
				fi
				echo "" >> /tmp/hyt_distant_result
			fi

			if [ "x$end_line" != "x" ]; then
				write_flag=0
				wlan5g_flag=0
				wlan2g_flag=0
			fi

		done
}

start()
{
	while [ 1 ];
	do
		sleep 15
		if [ ! -e /tmp/hyt_distant_result ]; then
			touch /tmp/hyt_distant_result
		fi
		get_satellite_ctype
	done
}

stop()
{
	rm /tmp/hyt_distant_result
	exit 1
}

