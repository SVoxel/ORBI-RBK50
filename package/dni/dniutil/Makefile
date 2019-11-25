#
# Copyright (C) 2007-2008 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dniutil
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=dniutil

include $(INCLUDE_DIR)/package.mk

define Package/dniutil
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+datalib
  TITLE:=DNI common function library.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Build/InstallDev
	mkdir -p $(STAGING_DIR)/usr/lib
	mkdir -p $(STAGING_DIR)/usr/include
	$(CP) -rp $(PKG_BUILD_DIR)/*.h $(STAGING_DIR)/usr/include
	$(CP) $(PKG_BUILD_DIR)/libdniutil.so $(STAGING_DIR)/usr/lib/
endef

define Build/UninstallDev
	rm -f $(STAGING_DIR)/usr/lib/libdniutil.so
endef

define Package/dniutil/install
	install -d -m0755 $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libdniutil.so $(1)/usr/lib/
	install -d -m0755 $(1)/bin
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,dniutil))
