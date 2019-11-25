# 
# Copyright (C) 2008 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=led-control
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=led-control

include $(INCLUDE_DIR)/package.mk

define Package/led-control
  SECTION:=utils
  DEPENDS:=@TARGET_ipq806x +datalib
  CATEGORY:=Base system
  TITLE:=Update utility for LED control
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/led-control/install
	install -d -m0755 $(1)/sbin
	install -d -m0755 $(1)/etc
	install -m0755 $(PKG_BUILD_DIR)/ledcontrol $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/gpio $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/files/led_status $(1)/etc/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,led-control))
