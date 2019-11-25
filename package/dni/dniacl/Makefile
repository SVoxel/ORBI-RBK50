# 
#  Copyright (C) 2007-2009 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dniacl
PKG_RELEASE:=1

CONFIG_DNIACL_GIT_TREEISH="b6b29c8c7e3a34b8659092cc2f47647b430f444b"
CONFIG_DNIACL_GIT_REPOSITORY="dni-acl.git"

PKG_GIT_TREEISH:=$(CONFIG_DNIACL_GIT_TREEISH)

PKG_BUILD_DEPENDS:=datalib
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=dniacl

include $(INCLUDE_DIR)/package.mk

define Package/dniacl
  SECTION:=utils
  CATEGORY:=Network
  TITLE:=Manage ACL.
  DEPENDS:=+datalib
endef

EXTRA_LDFLAGS := $(EXTRA_CFLAGS) $(call qstrip,$(CONFIG_DNIACL_EXTRA_FLAGS)) -DDGC_IF_WLAN_2G_PHYNAME="\\\"$(call qstrip,$(CONFIG_DGC_IF_WLAN_2G_PHYNAME))\\\""  -DDGC_IF_WLAN_5G_PHYNAME="\\\"$(call qstrip,$(CONFIG_DGC_IF_WLAN_5G_PHYNAME))\\\""

define Package/dniacl/config
	menu "Configuration"
	depends on PACKAGE_dniacl
	source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/dni-acl.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/dniacl/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/acld $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/acl_update_name $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aclctl $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aclhijackdns $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/acl_group $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/acl $(1)/etc/init.d/acl
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,dniacl))
