# 
#  Copyright (C) 2007-2008 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=detwan
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_DETWAN_GIT_TREEISH="wan-detection-dni33"
CONFIG_DETWAN_GIT_REPOSITORY="wan-detection.git"

PKG_GIT_TREEISH:=$(CONFIG_DETWAN_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=detwan

include $(INCLUDE_DIR)/package.mk

define Package/detwan
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=@TARGET_ipq806x +datalib
	TITLE:=Detection of Internet Connection Type
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/wan-detection.git/* $(PKG_BUILD_DIR)/
endef

define Package/detwan/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/detwan $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,detwan))
