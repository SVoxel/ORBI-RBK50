# 
#  Copyright (C) 2014 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=netgear-integration-api
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/netgear-integration-api
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Netgear integration API
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/netgear-integration-api/install
	$(MAKE) -C $(PKG_BUILD_DIR) install INS_DIR_PRE=$(1)
endef

$(eval $(call BuildPackage,netgear-integration-api))
