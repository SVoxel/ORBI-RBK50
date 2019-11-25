# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.3 2007/03/11 05:08:58 agui Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=pot
PKG_RELEASE:=4

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

PKG_GIT_TREEISH=pot-v1.0.8

include $(INCLUDE_DIR)/package.mk

define Package/pot
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=@TARGET_ipq806x +datalib
  TITLE:=POT
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/pot.git/* $(PKG_BUILD_DIR)/
endef

#define Build/Configure
#	mkdir -p $(PKG_BUILD_DIR)/files
#	$(CP) $(PKG_BUILD_DIR)/files/config.h $(BUILD_DIR)/$(PKG_NAME)/
#	test "$(CONFIG_DGC_SUPPORT_NAND_FLASH)x" == "x" || echo "#define SUPPORT_NAND_TYPE $(CONFIG_DGC_SUPPORT_NAND_FLASH)" >> $(PKG_BUILD_DIR)/config.h
#	test "$(CONFIG_DGC_SUPPORT_NOR_FLASH)x" == "x" || echo "#define SUPPORT_NOR_TYPE $(CONFIG_DGC_SUPPORT_NOR_FLASH)" >> $(PKG_BUILD_DIR)/config.h
#	test "$(CONFIG_DGC_SUPPORT_EMMC)x" == "x" || echo "#define SUPPORT_EMMC_TYPE $(CONFIG_DGC_SUPPORT_EMMC)" >> $(PKG_BUILD_DIR)/config.h
#endef

define Package/pot/install
	$(MAKE) -C $(PKG_BUILD_DIR) install INS_DIR_PRE=$(1)
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/netconn.sh $(1)/sbin/netconn.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/netconn.init $(1)/etc/init.d/netconn_detect
endef

$(eval $(call BuildPackage,pot))
