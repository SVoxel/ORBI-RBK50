#!/bin/sh

model_name=`cat /module_name | tr 'A-Z' 'a-z'`
if [ -e /lib/armor/phase2.tar.gz ]; then
	BDagent_Prebuild=1
elif [ -e /lib/armor/phase2-upd.tar.gz ]; then
	BDagent_Prebuild=2
fi
URL="url=https://http.fw.updates1.netgear.com/sw-apps/armor/${model_name}/2.2/bdagent.tar"
echo "$URL" > /tmp/mnt/bitdefender/etc/bdupd.server
downBD_first(){
	echo "$URL" > /tmp/mnt/bitdefender/etc/bdupd.server
	check_result=`/opt/bitdefender/bin/bdupd check-update | grep false`
	num=0	
	maxnum=5
       	while [ "x${check_result}" != "x" ] && [ $num -lt ${maxnum} ]
	do
		echo "[bdupd] ${check_result}, wait 5 minuters, will check-update again" > /dev/console
		sleep 300
		num=$(( $num + 1 ))
		check_result= `/opt/bitdefender/bin/bdupd check-update | grep false`
 	done
	if [ $num -eq $maxnum ]; then
		echo "[bdupd]have 5 times retry for check-update, will try again next day" >/dev/console
		exit 2
	fi
	echo "[bdupd] {\"update_available\": true}, will apply update" > /dev/console

	#apply-check
	apply_result=`/opt/bitdefender/bin/bdupd apply-update | grep false`
	num=0
	while [ "x${apply_result}" != "x" ] && [ $num -lt $maxnum ] 
	do
		echo "[bdupd] ${apply_result}, wait 5 minuter, will apply-update again" > /dev/console
		sleep 300
		num=$(( $num + 1 ))
		apply_result=`/opt/bitdefender/bin/bdupd apply-update | grep false` 
	done	
	if [ $num -eq $maxnum ]; then
		echo "[bdupd]have 5 times retry for apply-update, will try again next day" >/dev/console
		exit 2
	fi
	echo "[bdupd] update successfully" > /dev/console

	consistent_result=`/opt/bitdefender/bin/bdupd check-consistency` 
       	echo "[bdupd] ${consistent_result}" > /dev/console
	[ "$BDagent_Prebuild" = "2" ] && touch /tmp/mnt/bitdefender/first_download_done

}

deal_inconsistency(){
		echo "[bdupd]remove all file in /tmp/mnt/bitdefender" > /dev/console
		#We don't delete the configuration backuped, only del bdagent
		ls /opt/bitdefender/ |grep -v bd_backup_dir |xargs rm -rf
		[ -e /lib/armor/phase2.tar.gz ] && tar -zxvf /lib/armor/phase2.tar.gz -C / --keep-directory-symlink
		[ -e /lib/armor/phase2-upd.tar.gz ] && tar -zxvf /lib/armor/phase2-upd.tar.gz -C /opt/bitdefender/ --keep-directory-symlink
		downBD_first
	}
host="www.netgear.com"
ping_result=`cat /tmp/ping_netgear_result`
dni_ping(){
	ping -c 4 www.netgear.com > /tmp/ping_netgear_result 2>/dev/null
	sleep 5
	ping_result=`cat /tmp/ping_netgear_result`
}
boot(){
if [ ! -e "/tmp/mnt/bitdefender/first_download_done" ];then  #first download, there is no bdagent in the router
	echo "[bdupd] do ping netgear..." >/dev/console
	dni_ping
	while [ "x${ping_result}" = "x" ] || [ "x$( echo ${ping_result} | grep "100% packet loss")" != "x" ]
	do
		echo "[bdupd]Conn't connect to ${host}" >/dev/console
		sleep 30
		dni_ping
	done
	echo "[bdupd]can ping to ${host}" >/dev/console
	downBD_first
else
	#there is a bdagent in the router
	consistent_result=`/opt/bitdefender/bin/bdupd check-consistency | grep false`
	if [ "x${consistent_result}" != "x" ];then    #consistent false
		echo "[bdupd] ${consistent_result}, will remove the all file, and download the BDagent again" > /dev/console
		deal_inconsistency	
	else
       		echo "[bdupd] {\"consistent\": true}" > /dev/console
	fi
fi

# start BD
	/usr/share/armor/BD_START.sh 

}

day_check(){
	[ -f "/tmp/fileinfo.txt" ] && rm "/tmp/fileinfo.txt"
	fw-upgrade --get_fileinfo
	sleep 60 
	check_status=`hexdump -n 2 -e '/2 "%d"' /tmp/auto_ctlfile`
	if [ ${check_status} = "9999" ]; then
		echo "[bdupd]there is availbe new FW, will not upgrade BDagent today, and will try next day" >/dev/console
		exit 1
	fi
	
	if [ "$BDagent_Prebuild" = "2" ]; then
		if [ ! -e "/tmp/mnt/bitdefender/first_download_done" ];then  #first download, there is no bdagent in the router
			downBD_first
			/usr/share/armor/BD_START.sh 
			exit 0
		fi
	fi
	consistent_result=`/opt/bitdefender/bin/bdupd check-consistency | grep false`
	if [ "x${consistent_result}" != "x" ];then    #consistent false
		echo "[bdupd] ${consistent_result}, will remove the all file, and download the BDagent again" > /dev/console	
		/etc/init.d/ASH stop
		/opt/bitdefender/bin/bd_procd stop
		deal_inconsistency	
		/usr/share/armor/BD_START.sh 
	else
		check_result=`/opt/bitdefender/bin/bdupd check-update |grep true`
		if [ "x${check_result}" != "x" ];then
			d2 -c armorcfg.bdUpgradeState "true"
			/etc/init.d/ASH stop
			/opt/bitdefender/bin/bd_procd stop
			echo "[bdupd] {\"update_available\": true}, will apply update" > /dev/console
			apply_result=`/opt/bitdefender/bin/bdupd apply-update | grep false`
			if [ "x${apply_result}" != "x" ];then
				echo "[bdupd] ${apply_result}" > /dev/console
				consistent_result=`/opt/bitdefender/bin/bdupd check-consistency | grep false`
				if [ "x${consistent_result}" != "x" ];then    #consistent false
					echo "[bdupd] ${consistent_result}, will remove the all file, and download the BDagent again" > /dev/console	
					deal_inconsistency	
				fi
			else
				echo "[bdupd] apply-update successfully" > /dev/console
			fi	
			d2 -c armorcfg.bdUpgradeState "false"
			/usr/share/armor/BD_START.sh 
		else
			echo "[bdupd] {\"update_available\": false}, try to check next day" > /dev/console
		fi	
	 	
	fi
}

case "$1" in
	"boot")
		boot
	;;
	"day-check")
		day_check
	;;
	*)
		echo "Unknow command" >/dev/console
		echo "Usage: $0 boot|day-check" > /dev/console
	;;
esac

