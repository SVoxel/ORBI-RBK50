# 
# Copyright (C) 2014 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=openvpn-miscprogs_dni
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=openvpn-miscprogs_dni

include $(INCLUDE_DIR)/package.mk

define Package/openvpn-miscprogs_dni
  TITLE:= misc programs for openvpn
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  MENU:=1
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/openvpn-miscprogs_dni/install
	install -d -m0755 $(1)/usr/bin/
	install -m0755 $(PKG_BUILD_DIR)/tun_net $(1)/usr/bin/
	install -m0755 $(PKG_BUILD_DIR)/net_id $(1)/usr/bin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,openvpn-miscprogs_dni))
