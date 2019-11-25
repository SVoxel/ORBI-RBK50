#! /bin/bash

js_list="advanced.js \
	 backup.js \
	 bas_ether.js \
	 basic.js \
	 bas_pppoe.js \
	 bas_pptp.js \
	 block_services.js \
	 funcs.js \
	 jquery-1.7.2.min.js \
	 jquery.base64.min.js \
	 lan.js \
	 logs.js \
	 orbi_upgrade.js \
	 passwd.js \
	 reservation.js \
	 str_router.js \
	 top.js \
	 upgrade.js \
	 wan.js \
	 access_control/AccessControl.js \
	 advanced_qos/qos_prru.js \
	 block_sites/block_sites.js \
	 browser_hijack/RU_isp_list.js \
	 browser_hijack/RU_mac_spoof.js \
	 browser_hijack/RU_welcome.js \
	 browser_hijack/script/brs_00_02_ap_select.js \
	 browser_hijack/script/brs_00_03_ap_setup.js \
	 browser_hijack/script/brs_04_B_ppptp_pppoe_or_other_checkNet.js \
	 browser_hijack/script/brs_check_manulConfig.js \
	 browser_hijack/script/brs_hijack_03A_D_bigpond.js \
	 browser_hijack/script/brs_hijack_04_applySettings.js \
	 browser_hijack/script/brs_hijack.js \
	 browser_hijack/script/brs_hijack_success.js \
	 browser_hijack/script/funcs.js \
	 browser_hijack/script/ru_detcInetType.js \
	 cd_less_download/script/brs_hijack_download_apps.js \
	 components/common.js \
	 components/jquery-1.12.3.min.js \
	 components/materialize.min.js \
	 components/orbidesktop.min.js \
	 components/bootstrap/js/bootstrap.js \
	 components/bootstrap/js/bootstrap.min.js \
	 components/bootstrap/js/npm.js \
	 ddns/ddns.js \
	 dynamic_qos/streamboost.js \
	 email/email.js \
	 fastlane/fastlane.js \
	 forwarding_range/forwarding.js \
	 ipv6/ipv6_6rd.js \
	 ipv6/ipv6_autoConfig.js \
	 ipv6/ipv6_dhcp.js \
	 ipv6/ipv6_fixed.js \
	 ipv6/ipv6.js \
	 ipv6/ipv6_pppoe.js \
	 ipv6/ipv6_tunnel.js \
	 l2tp/bas_l2tp.js \
	 multipppoe/bas_mulpppoe.js \
	 multipppoe/mp_lang.js \
	 plc/plc_available_device.js \
	 plc/plc_dev_class.js \
	 plc/plc_dev_config.js \
	 plc/plc_qos_mac.js \
	 plc/plc_qos_port.js \
	 qos/qos.js \
	 qos/qos_prru.js \
	 rae/rae_bridge.js \
	 rae/wlan_bridge.js \
	 readyshare_mobile/readyshare_mobile.js \
	 remote/remote.js \
	 schedule/schedule.js \
	 tr069/tr069.js \
	 traffic/traffic.js \
	 triggering/triggering.js \
	 upnp/upnp.js \
	 upnp/UPnP_Media.js \
	 usb_storage/dtree.js \
	 usb_storage/USB_NETStorage.js \
	 user_hdd_storage/check_user.js \
	 user_hdd_storage/hdd.js \
	 vlan/vlan.js \
	 vpn/vpn.js \
	 wds/wds.js \
	 wireless/wadv_sechdule.js \
	 wireless/wlacl.js \
	 wireless/wlan.js \
	 wl_bridge/wlan_bridge.js \
	 wl_bridge/wlg_bridge.js"


css_list="components/bootstrap/css/bootstrap.css \
	  components/bootstrap/css/bootstrap.min.css \
	  components/bootstrap/css/bootstrap-theme.css \
	  components/bootstrap/css/bootstrap-theme.min.css \
	  css/ie.css \
	  css/localstyle.css \
	  css/materialize.min.css \
	  css/modalBoxControl.css \
	  css/orbidesktop.min.css \
	  css/parentalControls.css \
	  css/styles.css \
	  style/advanced.css \
	  style/advanced_home.css \
	  style/attach_device2.css \
	  style/attach_device.css \
	  style/basic.css \
	  style/basic_home.css \
	  style/form2.css \
	  style/form.css \
	  style/help.css \
	  style/hijack_02_genieHelp.css \
	  style/hijack_03A_D_bigpond.css \
	  style/hijack_03A_E_IP_problem.css \
	  style/hijack_03A_E_IP_problem_staticIP_A_inputIP.css \
	  style/hijack_03A_wanInput.css \
	  style/hijack_03A_wanInput_reenter.css \
	  style/hijack_05_networkIssue.css \
	  style/hijack_download_apps.css \
	  style/hijack_ru_finish_manual.css \
	  style/hijack_ru_isp_fail.css \
	  style/hijack_ru_welcome.css \
	  style/hijack_style.css \
	  style/hijack_success.css \
	  style/priority_zone.css \
	  style/top.css \
	  style/top_style.css"

compress_file(){
	list=$1

	echo "Compress $result start ...";
	hasJava=$(which java)
	if [ "x$hasJava" != "x" ]; then
		for i in $list; do
			java -jar ../files/yuicompressor-2.4.8.jar -o $i --charset utf-8 $i;
		done;
	else
		echo "Compress $result failed. Please install java";
		exit 1;
	fi
	echo "Compress $result finished.";
}

compress_file "$js_list"
compress_file "$css_list"
