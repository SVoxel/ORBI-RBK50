. /lib/dni_platform/dni_global.config
. /lib/dni_platform/project/dni_project.sh

dgc_conf_defconfig() {
	# DGC Network Interface Information
	$CONFIG set dgc_netif_br_if="$BR_IF"
	$CONFIG set dgc_netif_lan_if="$LAN_IF"
	$CONFIG set dgc_netif_wan_if="$WAN_IF"
	$CONFIG set dgc_netif_wan_phyif="$WAN_PHYIF"
	$CONFIG set dgc_netif_lan_phyif="$LAN_PHYIF"
	$CONFIG set dgc_netif_ppp_if="$PPP_IFNAME"
	$CONFIG set dgc_netif_mppp_if="$MPPP_IFNAME"
	$CONFIG set dgc_netif_ipv6_ppp_if="$IPV6_PPP_IFNAME"

	# DGC Wireless Network Interface Information
	$CONFIG set dgc_wlan_2g_phyif="$WLAN_2G_PHYNAME"
	$CONFIG set dgc_wlan_5g_phyif="$WLAN_5G_PHYNAME"
	$CONFIG set dgc_wlan_5g_bh_phyif="$WLAN_5G_BH_PHYNAME"
	# DGC Wireless Network Interface Information prefix
	$CONFIG set dgc_wlan_5g_fh_prefix="$WLAN_5G_FH_PREFIX"
	$CONFIG set dgc_wlan_5g_guest_prefix="$WLAN_5G_GUEST_PREFIX"
	$CONFIG set dgc_wlan_5g_bh_prefix="$WLAN_5G_BH_PREFIX"
	# Base Wireless Interface
	$CONFIG set dgc_wlan_base_2g_ap_if="$WLAN_Base_2G_AP_IFNAME"
	$CONFIG set dgc_wlan_base_2g_guestap_if="$WLAN_Base_2G_GUEST_AP_IFNAME"
	$CONFIG set dgc_wlan_base_5g_ap_if="$WLAN_Base_5G_AP_IFNAME"
	$CONFIG set dgc_wlan_base_5g_guestap_if="$WLAN_Base_5G_GUEST_AP_IFNAME"
	$CONFIG set dgc_wlan_base_2g_bh_ap_if="$WLAN_Base_2G_BH_AP_IFNAME"
	$CONFIG set dgc_wlan_base_5g_bh_ap_if="$WLAN_Base_5G_BH_AP_IFNAME"
	# Satellite Wireless Interface
	$CONFIG set dgc_wlan_sate_2g_ap_if="$WLAN_Sate_2G_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_2g_guestap_if="$WLAN_Sate_2G_GUEST_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_5g_ap_if="$WLAN_Sate_5G_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_5g_guestap_if="$WLAN_Sate_5G_GUEST_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_2g_bh_sta_if="$WLAN_Sate_2G_BH_STA_IFNAME"
	$CONFIG set dgc_wlan_sate_5g_bh_sta_if="$WLAN_Sate_5G_BH_STA_IFNAME"
	$CONFIG set dgc_wlan_sate_ds_2g_bh_ap_if="$WLAN_Sate_DS_2G_BH_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_ds_2g_guestap_if="$WLAN_Sate_DS_2G_GUEST_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_ds_5g_bh_ap_if="$WLAN_Sate_DS_5G_BH_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_ds_5g_guestap_if="$WLAN_Sate_DS_5G_GUEST_AP_IFNAME"
	$CONFIG set dgc_wlan_sate_ds_2g_bh_sta_if="$WLAN_Sate_DS_2G_BH_STA_IFNAME"
	$CONFIG set dgc_wlan_sate_ds_5g_bh_sta_if="$WLAN_Sate_DS_5G_BH_STA_IFNAME"

	# DGC System Information
	$CONFIG set dgc_sysinfo_device_name="$SYS_DEVICE_NAME"
	$CONFIG set dgc_sysinfo_module_name="$SYS_MODULE_NAME"
	$CONFIG set dgc_sysinfo_module_name_cc="$SYS_MODULE_NAME_CC"

	# DGC Flash Information
	$CONFIG set dgc_flash_type=`cat /flash_type`
	$CONFIG set dgc_flash_caldata_dev="$FLASH_CALDATA_DEV"
	$CONFIG set dgc_flash_caldata_name="$FLASH_CALDATA_NAME"
	$CONFIG set dgc_flash_language_dev="$FLASH_LANGUAGE_DEV"
	$CONFIG set dgc_flash_language_name="$FLASH_LANGUAGE_NAME"
	$CONFIG set dgc_flash_config_dev="$FLASH_CONFIG_DEV"
	$CONFIG set dgc_flash_config_name="$FLASH_CONFIG_NAME"
	$CONFIG set dgc_flash_pot_dev="$FLASH_POT_DEV"
	$CONFIG set dgc_flash_pot_name="$FLASH_POT_NAME"
	$CONFIG set dgc_flash_trafficmeter_dev="$FLASH_TRAFFICMETER_DEV"
	$CONFIG set dgc_flash_trafficmeter_name="$FLASH_TRAFFICMETER_NAME"
	$CONFIG set dgc_flash_firmware_dev="$FLASH_FW_DEV"
	$CONFIG set dgc_flash_firmware_name="$FLASH_FW_NAME"
	$CONFIG set dgc_flash_firmware2_dev="$FLASH_FW2_DEV"
	$CONFIG set dgc_flash_firmware2_name="$FLASH_FW2_NAME"
	$CONFIG set dgc_flash_oops_dev="$FLASH_OOPS_DEV"
	$CONFIG set dgc_flash_oops_name="$FLASH_OOPS_NAME"
	$CONFIG set dgc_flash_cert_dev="$FLASH_CERT_DEV"
	$CONFIG set dgc_flash_cert_name="$FLASH_CERT_NAME"
	$CONFIG set dgc_flash_devtable_dev="$FLASH_DEVTABLE_DEV"
	$CONFIG set dgc_flash_devtable_name="$FLASH_DEVTABLE_NAME"

	# DGC Feature Information
	$CONFIG set dgc_func_have_usb="$FUNC_HAVE_USB"
	$CONFIG set dgc_func_have_vpn="$FUNC_HAVE_VPN"
	$CONFIG set dgc_func_have_guest_portal="$FUNC_HAVE_GUEST_PORTAL"
	$CONFIG set dgc_func_have_dual_image="$FUNC_HAVE_DUAL_IMAGE"
	$CONFIG set dgc_func_have_readyshare_printer="$FUNC_HAVE_READYSHARE_PRINTER"
	$CONFIG set dgc_func_have_guest_network="$FUNC_HAVE_GUEST_NETWORK"
	$CONFIG set dgc_func_have_byod_network="$FUNC_HAVE_BYOD_NETWORK"
	$CONFIG set dgc_func_have_dni_parental_ctl="$FUNC_HAVE_DNI_PARENTAL_CTL"
	$CONFIG set dgc_func_have_vlan="$FUNC_HAVE_VLAN"
	$CONFIG set dgc_func_have_vlan_sb="$FUNC_HAVE_VLAN_SB"
	$CONFIG set dgc_func_have_business_ap_detect="$FUNC_HAVE_BUSINESS_AP_DETECT"
	$CONFIG set dgc_func_have_wireless_combine="$FUNC_HAVE_WIRELESS_COMBINE"
	$CONFIG set dgc_func_have_speedtest_menu="$FUNC_HAVE_SPEEDTEST_MENU"
	$CONFIG set dgc_func_have_orbi_mini="$FUNC_HAVE_ORBI_MINI"
	$CONFIG set dgc_func_have_forceshield="$FUNC_HAVE_FORCESHIELD"
	$CONFIG set dgc_func_have_tt3="$FUNC_HAVE_TT3"
	$CONFIG set dgc_func_have_qos="$FUNC_HAVE_QOS"
	$CONFIG set dgc_func_have_circle="$FUNC_HAVE_CIRCLE"
	$CONFIG set dgc_func_have_vpncheck="$FUNC_HAVE_VPNCHECK"
	$CONFIG set dgc_func_have_control_firmware="$FUNC_HAVE_CONTROL_FIRMWARE"
	$CONFIG set dgc_func_have_lacpd_dni="$FUNC_HAVE_LACPD_DNI"
	$CONFIG set dgc_func_base_have_tri_band="$FUNC_BASE_HAVE_TRI_BAND"
	$CONFIG set dgc_func_sate_have_tri_band="$FUNC_SATE_HAVE_TRI_BAND"
	$CONFIG set dgc_func_have_armor="$FUNC_HAVE_ARMOR"
	$CONFIG set dgc_func_have_autotimezone="$FUNC_HAVE_AUTOTIMEZONE"
}

dni_boot_stage0() {
	project_boot_stage0
	dgc_conf_defconfig
}

dni_boot_stage1() {
	project_boot_stage1
}
