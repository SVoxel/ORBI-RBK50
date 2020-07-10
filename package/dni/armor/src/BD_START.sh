#!/bin/sh

#Run restore, if we have backup dir, that means router has performed upgrade and backup BD configuration to backup dir
/usr/share/armor/upgrade_bd_cfg.sh restore
/usr/share/armor/change_cloud_server.sh set_server production

sed -i "/BootstrapServer/s/\(BootstrapServer = \)\(.*\)/\1nimbus.bitdefender.net/g" /opt/bitdefender/lib/guster/bdnc/bdnc.ini

chown -R root:root /opt/bitdefender/
chmod +x /opt/bitdefender/guster/scripts/*

if [ "x`/bin/config get i_opmode`" = "xapmode" ]; then
	exit 0
fi
#insmod armor.ko
kernel_version=`uname -a | awk -F " " '{print $3}'`
insmod /lib/modules/$kernel_version/guster.ko

echo "BD agent start"
/opt/bitdefender/bin/bd_procd start

/etc/init.d/ASH start
#iptables -t filter -I FORWARD -p tcp ! --sport 53 ! --dport 53 -j GUSTER

#trigger VA scan every day
LD_LIBRARY_PATH=/opt/bitdefender/lib /opt/bitdefender/bin/bdsett -set-key /daemons/bdvad/va_schedule_interval -to-string 604800
#LD_LIBRARY_PATH=/opt/bitdefender/lib /opt/bitdefender/bin/bdsett -set-key /daemons/bddevicediscovery/online_devices_sync_interval -to-string 90
#LD_LIBRARY_PATH=/opt/bitdefender/lib /opt/bitdefender/bin/bdsett -set-key /daemons/bddevicediscovery/neigh_expiry_time -to-string 200

activation_status=`/usr/share/armor/get_armor_status activate`
if [ "$activation_status" != "true" ]; then
	LD_LIBRARY_PATH=/opt/bitdefender/lib /opt/bitdefender/bin/bdsett -set-key /daemons/bdvad/first_wait -to-string 3600
fi

check_status=`/usr/share/armor/bdagent_check`

if [ "$check_status" != "0" ];then
	/etc/init.d/ASH stop
	/opt/bitdefender/bin/bd_procd stop
	sleep 15
	/opt/bitdefender/bin/bd_procd start
	/etc/init.d/ASH start
	check_status=`/usr/share/armor/bdagent_check`
	if [ "$check_status" != "0" ];then
		/etc/init.d/ASH stop
		/opt/bitdefender/bin/bd_procd stop
		sleep 15
		rm -rf /opt/bitdefender/*	
		if [ ! -e "/opt/bitdefender/bitdefender-release" ]; then
			[ -e /lib/armor/phase2.tar.gz ] && tar -zxvf /lib/armor/phase2.tar.gz -C / --keep-directory-symlink
			if [ "$?" != 0 ];then
				[ -e /lib/armor/phase2.tar.gz ] && tar -zxvf /lib/armor/phase2.tar.gz -C / --keep-directory-symlink
			fi
			sync
		fi
	
		if [ ! -e "/opt/bitdefender/bin/bdupd" ]; then
			[ -e /lib/armor/phase2-upd.tar.gz ] && tar -zxvf /lib/armor/phase2-upd.tar.gz -C /opt/bitdefender --keep-directory-symlink
			if [ "$?" != 0 ];then
				[ -e /lib/armor/phase2-upd.tar.gz ] && tar -zxvf /lib/armor/phase2-upd.tar.gz -C /opt/bitdefender --keep-directory-symlink
			fi
			sync
		fi
		chown -R root:root /opt/bitdefender/
		chmod +x /opt/bitdefender/guster/scripts/*
		#Per MH request,disable bdupdater carried in BD agent, Set BD updater check interval to 14days, this requirement is from DT 2.3.0.28
		sed -ri "/check_interval/s/(check_interval=)[^ ]+/\11209600/g" /opt/bitdefender/etc/patch.server
	
		if [ -e /lib/armor/phase2.tar.gz ]; then
			#if we have prebuild BD agent, directly start
			/usr/share/armor/BD_START.sh &
		elif [ -e /lib/armor/phase2-upd.tar.gz ]; then
			#If not have prebuild BD agent, call bdupd to download and start
			/usr/share/armor/bdupd_start.sh boot &
		fi
		exit 0
	fi
fi

net-wall restart
#/opt/bitdefender/guster/script/create_chain.sh 0


