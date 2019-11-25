# 
#  Copyright (C) 2007-2008 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=net-wall
PKG_RELEASE:=2
PKG_BUILD_DEPENDS:=datalib
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_NETWALL_GIT_TREEISH="net-wall-v2.0-dni95"
CONFIG_NETWALL_GIT_REPOSITORY="net-wall.git"
PKG_GIT_TREEISH:=$(CONFIG_NETWALL_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=net-wall

include $(INCLUDE_DIR)/package.mk

define Package/net-wall
  SECTION:=utils
  CATEGORY:=Network
  DEPENDS:=@TARGET_ipq806x +datalib
  TITLE:=Mini Firewall for Embedded Router.
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/net-wall.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/net-wall/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/net-wall $(1)/usr/sbin/
	install -m0755 $(PKG_BUILD_DIR)/net-wall-bin $(1)/usr/sbin/
	install -d -m0755 $(1)/etc
	$(CP) $(PKG_BUILD_DIR)/files/l7_patten.dat $(1)/etc
	$(CP) $(PKG_BUILD_DIR)/files/etc/* $(1)/etc
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,net-wall))
