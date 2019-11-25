# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.5.2.1 2008-05-13 06:54:33 echo.niu Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=nmrp
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

LOCAL_PKG_NAME_EXT:=nmrp

include $(INCLUDE_DIR)/package.mk

define Package/nmrp
  SECTION:=net
  CATEGORY:=DNI Package
  TITLE:=NMRP
endef

define Build/Prepare
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/nmrp/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/nmrp-client $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef
$(eval $(call BuildPackage,nmrp))
