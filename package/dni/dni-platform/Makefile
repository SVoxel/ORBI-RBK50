# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.1 2008-05-08 05:17:53 stoneliu Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=dni-platform

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

DGC_CONFIG_DIR:=lib/dni_platform/config
DGC_NETIF_FILE:=$(DGC_CONFIG_DIR)/02-network_interface_info.config
DGC_FLASH_FILE:=$(DGC_CONFIG_DIR)/03-flash_info.config
DGC_FUNC_FILE:=$(DGC_CONFIG_DIR)/04-feature_info.config
DGC_SYS_FILE:=$(DGC_CONFIG_DIR)/05-system_info.config

FLASH_TYPE_VAR:=EMMC
ifdef CONFIG_DGC_FLASH_TYPE_EMMC
FLASH_TYPE_VAR:=EMMC
endif

ifdef CONFIG_DGC_FLASH_TYPE_NOR
FLASH_TYPE_VAR:=NOR_FLASH
endif

ifdef CONFIG_DGC_FLASH_TYPE_NAND
FLASH_TYPE_VAR:=NAND_FLASH
endif

LOCAL_PKG_NAME_EXT:=dni-platform

include $(INCLUDE_DIR)/package.mk

define Package/dni-platform
  SECTION:=net
  CATEGORY:=DNI Package
  TITLE:=DNI Platform Configure
  VERSION:=1
endef

define Package/dni-platform/DGC_Config
	test x$(call qstrip, $(1)) == x || sed -i '/^$(call qstrip, $(2))=/ s/^.*/$(call qstrip, $(2))=$(call qstrip, $(1))/g' $(3)
endef

define Package/dni-platform/DGC_Config_NetIF
	$(call Package/dni-platform/DGC_Config,$(1),$(2),$(PKG_BUILD_DIR)/$(DGC_NETIF_FILE))
endef

define Package/dni-platform/DGC_Config_FlashSet
	$(call Package/dni-platform/DGC_Config,$(shell echo -n $(1) | sed 's/\//\\\//g'),$(2),$(PKG_BUILD_DIR)/$(DGC_FLASH_FILE))
endef

define Package/dni-platform/DGC_Config_FuncSet
	test x$(call qstrip, $(1)) == x || sed -i '/^$(call qstrip, $(2))=/ s/^.*/$(call qstrip, $(2))=1/g' $(PKG_BUILD_DIR)/$(DGC_FUNC_FILE)
endef

define Package/dni-platform/DGC_Config_SysSet
	$(call Package/dni-platform/DGC_Config,$(1),$(2),$(PKG_BUILD_DIR)/$(DGC_SYS_FILE))
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./files/* $(PKG_BUILD_DIR)/

	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WAN_PHYNAME),"WAN_PHYNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_LAN_PHYNAME),"LAN_PHYNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_2G_PHYNAME),"WLAN_2G_PHYNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_5G_PHYNAME),"WLAN_5G_PHYNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_5G_BH_PHYNAME),"WLAN_5G_BH_PHYNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_5G_FH_PREFIX),"WLAN_5G_FH_PREFIX")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_5G_GUEST_PREFIX),"WLAN_5G_GUEST_PREFIX")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_5G_BH_PREFIX),"WLAN_5G_BH_PREFIX")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WAN_IFNAME),"WAN_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_LAN_IFNAME),"LAN_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_PPP_IFNAME),"PPP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_MPPP_IFNAME),"MPPP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_IPV6_PPP_IFNAME),"IPV6_PPP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Base_2G_AP_IFNAME),"WLAN_Base_2G_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Base_2G_GUEST_AP_IFNAME),"WLAN_Base_2G_GUEST_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Base_5G_AP_IFNAME),"WLAN_Base_5G_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Base_5G_GUEST_AP_IFNAME),"WLAN_Base_5G_GUEST_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Base_2G_BH_AP_IFNAME),"WLAN_Base_2G_BH_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Base_5G_BH_AP_IFNAME),"WLAN_Base_5G_BH_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_2G_AP_IFNAME),"WLAN_Sate_2G_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_2G_GUEST_AP_IFNAME),"WLAN_Sate_2G_GUEST_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_5G_AP_IFNAME),"WLAN_Sate_5G_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_5G_GUEST_AP_IFNAME),"WLAN_Sate_5G_GUEST_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_2G_BH_STA_IFNAME),"WLAN_Sate_2G_BH_STA_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_5G_BH_STA_IFNAME),"WLAN_Sate_5G_BH_STA_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_DS_2G_BH_AP_IFNAME),"WLAN_Sate_DS_2G_BH_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_DS_2G_GUEST_AP_IFNAME),"WLAN_Sate_DS_2G_GUEST_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_DS_5G_BH_AP_IFNAME),"WLAN_Sate_DS_5G_BH_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_DS_5G_GUEST_AP_IFNAME),"WLAN_Sate_DS_5G_GUEST_AP_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_DS_2G_BH_STA_IFNAME),"WLAN_Sate_DS_2G_BH_STA_IFNAME")
	$(call Package/dni-platform/DGC_Config_NetIF,$(CONFIG_DGC_IF_WLAN_Sate_DS_5G_BH_STA_IFNAME),"WLAN_Sate_DS_5G_BH_STA_IFNAME")

	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_CALDATA_NAME),"FLASH_CALDATA_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_CALDATA_DEV),"FLASH_CALDATA_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_LANGUAGE_NAME),"FLASH_LANGUAGE_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_LANGUAGE_DEV),"FLASH_LANGUAGE_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_CONFIG_NAME),"FLASH_CONFIG_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_CONFIG_DEV),"FLASH_CONFIG_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_POT_NAME),"FLASH_POT_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_POT_DEV),"FLASH_POT_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_TRAFFICMETER_NAME),"FLASH_TRAFFICMETER_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_TRAFFICMETER_DEV),"FLASH_TRAFFICMETER_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_FW_NAME),"FLASH_FW_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_FW_DEV),"FLASH_FW_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_FW2_NAME),"FLASH_FW2_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_FW2_DEV),"FLASH_FW2_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_OOPS_NAME),"FLASH_OOPS_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_OOPS_DEV),"FLASH_OOPS_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_CERT_NAME),"FLASH_CERT_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_CERT_DEV),"FLASH_CERT_DEV")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_DEVTABLE_NAME),"FLASH_DEVTABLE_NAME")
	$(call Package/dni-platform/DGC_Config_FlashSet,$(CONFIG_DGC_FLASH_DEVTABLE_DEV),"FLASH_DEVTABLE_DEV")

	$(call Package/dni-platform/DGC_Config_FlashSet,$(FLASH_TYPE_VAR),"FLASH_TYPE")

	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_USB),"FUNC_HAVE_USB")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_VPN),"FUNC_HAVE_VPN")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_GUEST_PORTAL),"FUNC_HAVE_GUEST_PORTAL")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_DUAL_IMAGE),"FUNC_HAVE_DUAL_IMAGE")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_READYSHARE_PRINTER),"FUNC_HAVE_READYSHARE_PRINTER")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_GUEST_NETWORK),"FUNC_HAVE_GUEST_NETWORK")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_BYOD_NETWORK),"FUNC_HAVE_BYOD_NETWORK")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_DNI_PARENTAL_CTL),"FUNC_HAVE_DNI_PARENTAL_CTL")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_VLAN),"FUNC_HAVE_VLAN")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_VLAN_SB),"FUNC_HAVE_VLAN_SB")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_BUSINESS_AP_DETECT),"FUNC_HAVE_BUSINESS_AP_DETECT")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_WIRELESS_COMBINE),"FUNC_HAVE_WIRELESS_COMBINE")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_SPEEDTEST_MENU),"FUNC_HAVE_SPEEDTEST_MENU")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_ORBI_MINI),"FUNC_HAVE_ORBI_MINI")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_FORCESHIELD),"FUNC_HAVE_FORCESHIELD")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_TT3),"FUNC_HAVE_TT3")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_QOS),"FUNC_HAVE_QOS")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_CIRCLE),"FUNC_HAVE_CIRCLE")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_CONTROL_FIRMWARE),"FUNC_HAVE_CONTROL_FIRMWARE")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_VPNCHECK),"FUNC_HAVE_VPNCHECK")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_LACPD_DNI),"FUNC_HAVE_LACPD_DNI")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_BASE_HAVE_TRI_BAND),"FUNC_BASE_HAVE_TRI_BAND")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_SATE_HAVE_TRI_BAND),"FUNC_SATE_HAVE_TRI_BAND")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_ARMOR),"FUNC_HAVE_ARMOR")
	$(call Package/dni-platform/DGC_Config_FuncSet,$(CONFIG_DGC_FUNC_HAVE_AUTOTIMEZONE),"FUNC_HAVE_AUTOTIMEZONE")

	$(call Package/dni-platform/DGC_Config_SysSet,$(CONFIG_DGC_DEVICE_NAME),"SYS_DEVICE_NAME")
	$(call Package/dni-platform/DGC_Config_SysSet,$(CONFIG_DGC_MODULE_NAME),"SYS_MODULE_NAME")
	$(call Package/dni-platform/DGC_Config_SysSet,$(CONFIG_DGC_MODULE_NAME_CC),"SYS_MODULE_NAME_CC")
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Build/Compile
endef

define Package/dni-platform/install
	$(INSTALL_DIR) $(1)/lib/dni_platform
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/dni_platform/dni_global.config $(1)/lib/dni_platform/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/dni_platform/dni_platform.sh $(1)/lib/dni_platform/
	$(INSTALL_DIR) $(1)/lib/dni_platform/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/dni_platform/config/* $(1)/lib/dni_platform/config/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,dni-platform))
