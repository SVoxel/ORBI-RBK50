# 
# Copyright (C) 2013 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ntgrddns
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_NTGRDDNS_GIT_TREEISH="ntgrddns-dni13"
CONFIG_NTGRDDNS_GIT_REPOSITORY="ntgrddns.git"

PKG_GIT_TREEISH:=$(CONFIG_NTGRDDNS_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=ntgrddns

include $(INCLUDE_DIR)/package.mk

define Package/ntgrddns
  SECTION:=utils
  CATEGORY:=Network
  DEPENDS:=@TARGET_ipq806x +datalib
  TITLE:=Tiny ddns util for Netgear Home Router
endef

define Package/ntgrddns/description
	This package contains a tiny ddns util for Netgear Home Router.
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/ntgrddns.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/ntgrddns/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/ntgrddns $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,ntgrddns))
