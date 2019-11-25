cd /tmp/
echo 0 >/tmp/openvpn/cert_file_status
killall openvpn
board_sn=$(artmtd -r sn | head -n 1 | awk -F : '{print $2}') 
prefix_sn=$(cat openvpn_keys.tar.gz | head -c 13) 
[ $board_sn != $prefix_sn ] && echo "Serial number is not matched!" > /dev/console && exit 
tail -c +16 openvpn_keys.tar.gz > openvpn.tar.gz
mkdir openvpn
tar zxvf openvpn.tar.gz -C openvpn
rm openvpn.tar.gz
cd openvpn && dos2unix cert.info && tar zcvf openvpn.tar.gz ./*
cd /tmp/ && mv /tmp/openvpn/openvpn.tar.gz /tmp/
rm -rf openvpn
partition=`part_dev cert`
flash_type=`cat /flash_type`
if [ "x$flash_type" = "xEMMC" ];then
	dd if=/dev/zero of=$partition
	dd if=/tmp/openvpn.tar.gz of=$partition
else
	nandwrite -p -m -q $partition openvpn.tar.gz
fi
/etc/init.d/openvpn boot
