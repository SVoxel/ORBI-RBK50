# 
# Copyright (C) 2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id$

include $(TOPDIR)/rules.mk

PKG_NAME:=soapclient
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_BUILD_DEPENDS:=datalib

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_SOAPCLIENT_GIT_TREEISH="soapclient-dni81"
CONFIG_SOAPCLIENT_GIT_REPOSITORY="soapclient.git"

LOCAL_PKG_NAME_EXT:=soapclient

include $(INCLUDE_DIR)/package.mk

PKG_GIT_TREEISH:=$(CONFIG_SOAPCLIENT_GIT_TREEISH)

define Package/soapclient
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+datalib +libopenssl
  TITLE:= soapclient
endef

TARGET_CFLAGS += -DDGC_MODULE_NAME_CC="\\\"$(call qstrip,$(CONFIG_DGC_MODULE_NAME_CC))\\\""

define Package/soapclient/config
	menu "Configuration"
		depends on PACKAGE_soapclient
		source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/soapclient.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DORBI_XSS -DSOAP_BLOCK -DLIGHTING_LED -DVOICE_CONTROL -DLOCATION_FUNC $(call qstrip,$(CONFIG_SOAPCLIENT_EXTRA_FLAGS))

ifeq ($(CONFIG_PACKAGE_insight), y)
	EXTRA_CFLAGS += -DINSIGHT_LOG
endif

ifeq ($(CONFIG_DGC_FUNC_HAVE_CONTROL_FIRMWARE), y)
	EXTRA_CFLAGS += -DCONTROL_FW_ROLLOUT
endif

define Package/soapclient/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/soapclient $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/soap_agent $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/satelliteinfo $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/soap_check_fw $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/schedule_speed_test $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/soap_agent.init $(1)/etc/init.d/soap_agent
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/checkfirmware.sh $(1)/usr/sbin/checkfirmware.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/check_wps_soap $(1)/usr/sbin/check_wps_soap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/soap_wifi_action.sh $(1)/usr/sbin/soap_wifi_action.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/check_soapagent.sh $(1)/usr/sbin/check_soapagent.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/check_satellite_allconfig $(1)/usr/sbin/check_satellite_allconfig
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/iwlist_scan.sh $(1)/usr/sbin/iwlist_scan.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/satellite_allconfig_result.sh $(1)/usr/sbin/satellite_allconfig_result.sh
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,soapclient))
