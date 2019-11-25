# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.1 2008-05-08 05:17:53 stoneliu Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=dni-network

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=dni-network

include $(INCLUDE_DIR)/package.mk

define Package/dni-network
  SECTION:=net
  CATEGORY:=DNI Package
  TITLE:=dni-network
  VERSION:=1
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile/Default

endef
Build/Compile = $(Build/Compile/Default)

define Package/dni-network/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sw.conf $(1)/etc/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sw_extender.conf $(1)/etc/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/init.d/* $(1)/etc/init.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/config/network $(1)/etc/config/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,dni-network))
