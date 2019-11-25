#!/bin/sh
CONFIG=/bin/config
flow_soap_cmd=`$CONFIG get flow_soap`
echo "flow soap start action=$flow_soap_cmd now......" > /dev/console


if [ "$flow_soap_cmd" = "UpdateNewFirmware2" ]; then
	echo "flow soap UpdateNewFirmware2 now......" > /dev/console
	config unset flow_soap
	config commit
	fw-upgrade --image_write_and_reboot
fi

if [ "$flow_soap_cmd" = "Reboot" ]; then
	echo "flow soap reboot now......" > /dev/console
	config unset flow_soap
	config commit
	reboot
fi

if [ "$flow_soap_cmd" = "ResetToDefault" ]; then
	/sbin/factory_default
	config commits
	echo "flow soap ResetToDefault reboot now......" > /dev/console
	reboot
fi
if [ "$flow_soap_cmd" = "CGI_wireless" ]; then
	echo "flow soap wlan harf restart now......" > /dev/console
	triband_enable=`$CONFIG get triband_enable`
	if [ "$triband_enable" = "1" ]; then
		wifison.sh updateconf lbd;wlan updateconf > /dev/console;wlan down >/dev/console; wlan up >/dev/console;/sbin/ledcontrol -n all -c recover >/dev/console;
	elif [ "$(cat /tmp/orbi_project)" = "Orbimini" ];then
		wifison.sh updateconf lbd;wlan updateconf > /dev/console;wlan down wifi0>/dev/console;wlan down wifi2>/dev/console;wlan up >/dev/console;/sbin/ledcontrol -n all -c recover >/dev/console;
	elif [ "$(cat /tmp/orbi_project)" = "OrbiOutdoor" ]; then
		if [ "$($CONFIG get Location)" = "outdoor" ]; then
			wifison.sh updateconf lbd;wlan updateconf > /dev/console;wlan down wifi0>/dev/console;wlan down wifi2>/dev/console;wlan up >/dev/console;/sbin/ledcontrol -n all -c recover >/dev/console;
		else
			wifison.sh updateconf lbd;wlan updateconf > /dev/console;wlan down wifi0>/dev/console;wlan down wifi1>/dev/console;wlan up >/dev/console;/sbin/ledcontrol -n all -c recover >/dev/console;
		fi
	else
		wifison.sh updateconf lbd;wlan updateconf > /dev/console;wlan down wifi0>/dev/console;wlan down wifi1>/dev/console;wlan up >/dev/console;/sbin/ledcontrol -n all -c recover >/dev/console;
	fi
fi

if [ "$flow_soap_cmd" = "CGI_wireless_backhaul" ]; then
	echo "flow soap wlan restart now......" > /dev/console
	wifison.sh updateconf lbd;wlan updateconf > /dev/console;wlan down >/dev/console;wlan up >/dev/console;/sbin/ledcontrol -n all -c recover >/dev/console;
fi
config unset flow_soap


