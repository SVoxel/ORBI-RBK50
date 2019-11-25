# 
#  Copyright (C) 2007-2009 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=attached-devices-ext
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_NETSCAN-EXT_GIT_TREEISH="net-scan-orbi-series-ext-v1.0-dni5"
CONFIG_NETSCAN-EXT_GIT_REPOSITORY="attached-devices.git"

PKG_GIT_TREEISH:=$(CONFIG_NETSCAN-EXT_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=attached-devices-ext

include $(INCLUDE_DIR)/package.mk

define Package/attached-devices-ext
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=@TARGET_ipq806x
	TITLE:=Scanning the attached devices according to NETGEAR's spec.
	DEPENDS:=datalib
endef


define Package/attached-devices-ext/config
	menu "Configuration"
		depends on PACKAGE_attached-devices-ext
		source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/attached-devices-ext.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

EXTRA_CFLAGS := $(EXTRA_CFLAGS) $(call qstrip,$(CONFIG_NETSCANEXT_EXTRA_FLAGS))

define Package/attached-devices-ext/install
	install -d -m0755 $(1)/etc/init.d
	install -m0755 $(PKG_BUILD_DIR)/files/attach_device.init $(1)/etc/init.d/netscan
	install -m0755 $(PKG_BUILD_DIR)/files/netscan_if.init $(1)/etc/init.d/netscan_if.init
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/attach_device $(1)/usr/sbin/net-scan-ext
	install -m0755 $(PKG_BUILD_DIR)/dev-scan $(1)/usr/sbin/dev-scan-ext
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,attached-devices-ext))
