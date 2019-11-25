# 
# Copyright (C) 2009 OpenWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=net-cgi
PKG_RELEASE:=1
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

WEB_PATH:=www
WEB_PATH_CC:=www.satellite

LOCAL_PKG_NAME_EXT:=net-cgi

include $(INCLUDE_DIR)/package.mk

PKG_GIT_TREEISH:=orbi-ax-dni033

define Package/net-cgi
  SECTION:=utils
  CATEGORY:=Base system
  DEPENDS:=libiconv-full +datalib +libpthread +d2 +dil +ntgdal +dniutil
  TITLE:=The mini_httpd CGI interface
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/net-cgi.git/* $(PKG_BUILD_DIR)/
endef


TARGET_CFLAGS += -Werror

define Build/Configure
endef
define Package/net-cgi/install
	$(MAKE) -C $(PKG_BUILD_DIR) install INS_DIR_PRE=$(1)

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/support_soap_list $(TOPDIR)/bin/

	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/dni_wlan $(1)/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/net-cgi.init $(1)/etc/init.d/net-cgi
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/inetd.init $(1)/etc/init.d/inetd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/get_wlan_info.sh $(1)/etc/init.d/get_wlan_info.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/send_soap_api.sh $(1)/sbin/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/* $(1)/usr/sbin
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,net-cgi))
