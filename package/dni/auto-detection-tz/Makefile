#
# Copyright(C) 2006-2018 OpenWrt.org
#
include $(TOPDIR)/rules.mk
PKG_NAME:=auto-detection-tz
PKG_VERSION:=1.0
PKG_RELEASE:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/auto-detection-tz
    SECTION:=utils
    DEPENDS:=@TARGET_ipq806x +datalib
    CATEGORY:=DNI Package
    TITLE:=auto-detection-tz
endef
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/auto-detection-tz/description
	Auto Detection TimeZone
endef

define Package/auto-detection-tz/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/auto-detection-tz $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/get_xCloud_MAXmind.sh $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,auto-detection-tz))
