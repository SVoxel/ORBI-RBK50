# 
#  Copyright (C) 2012 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=noip2
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=noip2

include $(INCLUDE_DIR)/package.mk

define Package/noip2
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=+datalib
	TITLE:=no-ip DDNS utility.
endef

define Build/Prepare
	$(CP) -r ./src/* $(PKG_BUILD_DIR)/
	$(call Build/Patch/Default)
	$(if $(PLATFORM_PATCH_DIR), $(call PatchDir,$(PKG_BUILD_DIR),$(PLATFORM_PATCH_DIR),))
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Package/noip2/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/noip2 $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,noip2))
