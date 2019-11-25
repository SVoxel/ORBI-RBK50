#!/bin/sh

local fail=0
local country_code=$(uci get wireless.wifi0.country)
REGULATORY_DOMAIN=FCC_ETSI
IPQ4019_BDF_DIR=/lib/firmware/IPQ4019/hw.1
QCA9984_BDF_DIR=/lib/firmware/QCA9984/hw.1
QCA9888_BDF_DIR=/lib/firmware/QCA9888/hw.2

#config_get wl_super_wifi qcawifi wl_super_wifi
#config_get wla_super_wifi qcawifi wla_super_wifi
#if [ "$wl_super_wifi" == "1" ] || [ "$wla_super_wifi" == "1" ]; then
#	REGULATORY_DOMAIN=SUPER_WIFI
#else
	case "$country_code" in
		5001)
			REGULATORY_DOMAIN=Canada
			;;
		5000)
			REGULATORY_DOMAIN=AU
			;;
		412)
			REGULATORY_DOMAIN=Korea
			;;
		356)
			REGULATORY_DOMAIN=INS
			;;
		458|156|702|764)
			REGULATORY_DOMAIN=SRRC
			;;
	esac
#fi

BOARD_VERSION=$(/bin/cat /tmp/hw_revision)
if [ "x${BOARD_VERSION}" == "x01" ]; then
	BOARD_ID="board-01"
	echo "it is cost down hw board, checking the cost down boardata......." > /dev/console
else
	BOARD_ID=""
	echo "it is normal board hw baord, checking the normal boardata......." > /dev/console
fi

REGULATORY_DOMAIN="$BOARD_ID/$REGULATORY_DOMAIN"

if [ -d $IPQ4019_BDF_DIR/$REGULATORY_DOMAIN ]; then
	ls $IPQ4019_BDF_DIR/$REGULATORY_DOMAIN | while read line
	do
		if [ "x$(/usr/bin/md5sum $IPQ4019_BDF_DIR/$REGULATORY_DOMAIN/$line |cut -d ' ' -f 1)" = "x$(/usr/bin/md5sum $IPQ4019_BDF_DIR/$line |cut -d ' ' -f 1)" ]; then
			/usr/bin/md5sum $IPQ4019_BDF_DIR/$REGULATORY_DOMAIN/$line > /dev/console
		else
			echo "Fail: IPQ4019 boarddata is error"  > /dev/console
			fail=$(($fail + 1))
		fi
	done
	echo "Success: IPQ4019 boarddata is correct"  > /dev/console
fi

if [ -d $QCA9984_BDF_DIR/$REGULATORY_DOMAIN ]; then
	ls $QCA9984_BDF_DIR/$REGULATORY_DOMAIN | while read line
	do
		if [ "x$(/usr/bin/md5sum $QCA9984_BDF_DIR/$REGULATORY_DOMAIN/$line |cut -d ' ' -f 1)" = "x$(/usr/bin/md5sum $QCA9984_BDF_DIR/$line |cut -d ' ' -f 1)" ]; then
			/usr/bin/md5sum $QCA9984_BDF_DIR/$REGULATORY_DOMAIN/$line > /dev/console
		else
			echo "Fail: QCA9984 boarddata is error"  > /dev/console
			fail=$(($fail + 1))
		fi
	done
	echo "Success: QCA9984 boarddata is correct"  > /dev/console
fi


if [ -d $QCA9888_BDF_DIR/$REGULATORY_DOMAIN ]; then
	ls $QCA9888_BDF_DIR/$REGULATORY_DOMAIN | while read line
	do
		if [ "x$(/usr/bin/md5sum $QCA9888_BDF_DIR/$REGULATORY_DOMAIN/$line |cut -d ' ' -f 1)" = "x$(/usr/bin/md5sum $QCA9888_BDF_DIR/$line |cut -d ' ' -f 1)" ]; then
			/usr/bin/md5sum $QCA9888_BDF_DIR/$REGULATORY_DOMAIN/$line > /dev/console
		else
			echo "Fail: QCA9888 boarddata is error"  > /dev/console
			fail=$(($fail + 1))
		fi
	done
	echo "Success: QCA9888 boarddata is correct"  > /dev/console
fi

[ -f /tmp/thermalwifi0.txt ] && rm /tmp/thermalwifi0.txt
[ -f /tmp/thermalwifi1.txt ] && rm /tmp/thermalwifi1.txt
[ -f /tmp/thermalwifi2.txt ] && rm /tmp/thermalwifi2.txt
[ -f /tmp/thermal.txt ] && rm /tmp/thermal.txt
thermaltool -i wifi0 -get > /tmp/thermalwifi0.txt
thermaltool -i wifi1 -get > /tmp/thermalwifi1.txt
thermaltool -i wifi2 -get > /tmp/thermalwifi2.txt
awk '{if(NR<=6) print $0}' /tmp/thermalwifi0.txt >> /tmp/thermal.txt
awk '{if(NR<=6) print $0}' /tmp/thermalwifi1.txt >> /tmp/thermal.txt
awk '{if(NR<=6) print $0}' /tmp/thermalwifi2.txt >> /tmp/thermal.txt
if [ "x${BOARD_VERSION}" == "x01" ]; then
	echo "it is cost down hw baord, checking cost down board thermal.............." > /dev/console
	if [ "x$(/bin/cat /tmp/thermal.txt)" = "x$(/bin/cat /usr/sbin/thermal_costdown)" ]; then
		echo "Success: cost down board thermal setting ok!"
		/bin/cat /tmp/thermal.txt
	else
		echo "Fail: cost down board thermal setting fail!"
		fail=$(($fail + 1))
	fi
else
	echo "it is normal hw baord, checking normal board thermal.............." > /dev/console
	if [ "x$(/bin/cat /tmp/thermal.txt)" = "x$(/bin/cat /usr/sbin/thermal_normal)" ]; then
		echo "Success: normal board thermal setting ok!"
		/bin/cat /tmp/thermal.txt
	else
		echo "Fail: noral board thermal setting fail!"
		fail=$(($fail + 1))
	fi
fi


if [ "x$fail" = "x0" ]; then
	echo "============HW Revision Checking result: SUCCESS!==========="
else
	echo "============HW Revison Checking result: FAIL!==========="
fi
