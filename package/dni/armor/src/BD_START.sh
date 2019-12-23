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

net-wall restart
#/opt/bitdefender/guster/script/create_chain.sh 0


