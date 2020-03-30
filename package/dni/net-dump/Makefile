# 
# Copyright (C) 2008 OpenWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=net-dump
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=net-dump

include $(INCLUDE_DIR)/package.mk

define Package/net-dump
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=+datalib
	TITLE:=Mini dump tool to capture packets.
endef


define Package/net-dump/description
	It is used for NTGR's Router Debug mode.
endef

TARGET_CFLAGS += -L$(STAGING_DIR)/usr/lib -lconfig

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)
	$(call Build/Patch/Default)
	$(if $(PLATFORM_PATCH_DIR), $(call PatchDir,$(PKG_BUILD_DIR),$(PLATFORM_PATCH_DIR),))
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Package/net-dump/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/net-dump $(1)/usr/sbin/
	install -d -m0755 $(1)/sbin
	install -m0755 ./file/wan_debug $(1)/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,net-dump))
