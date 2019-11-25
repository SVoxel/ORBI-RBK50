# 
# Copyright (C) 2008 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=led-extender
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=led-extender

include $(INCLUDE_DIR)/package.mk

define Package/led-extender
  SECTION:=utils
  CATEGORY:=Base system
  DEPENDS:=+datalib
  TITLE:=Update utility for LED control
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/files
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./files/* $(PKG_BUILD_DIR)/files
endef

define Build/Compile
endef

define Package/led-extender/install
	install -d -m0755 $(1)/sbin
	install -m0755 $(PKG_BUILD_DIR)/led-extender $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/led-extender-5G $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/scan_result_process $(1)/sbin/
	install -m0755 ./files/disable_dhcp $(1)/sbin/
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/files/bring_fronthaul_down $(1)/usr/sbin/
	install -m0755 $(PKG_BUILD_DIR)/files/kick_backhaul $(1)/usr/sbin/
	install -m0755 $(PKG_BUILD_DIR)/files/get_satellite_hop_number.sh $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,led-extender))
