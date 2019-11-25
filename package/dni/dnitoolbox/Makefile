#
# Copyright (C) 2015 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dnitoolbox
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

FILES_DIR:=./files

LOCAL_PKG_NAME_EXT:=dnitoolbox

include $(INCLUDE_DIR)/package.mk

define Package/dnitoolbox
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=a set of dni common tools
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Build/InstallDev
	mkdir -p $(STAGING_DIR)/usr/lib
	mkdir -p $(STAGING_DIR)/lib
	$(CP) $(PKG_BUILD_DIR)/cfgmtd/libcfgmtd.so $(STAGING_DIR)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/cfgmtd/libcfgmtd.so $(STAGING_DIR)/lib/
endef

define Build/UninstallDev
	rm -f $(STAGING_DIR)/usr/lib/libcfgmtd.so
endef

define Package/dnitoolbox/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/part_dev/part_dev $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/firmware/firmware_update $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/usr/etc/firmware_update
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/firmware/do_action.sh $(1)/usr/etc/firmware_update/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/firmware/post_action.sh $(1)/usr/etc/firmware_update/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/firmware/pre_action.sh $(1)/usr/etc/firmware_update/
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cfgmtd/libcfgmtd.so $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/fw_upg.sh $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,dnitoolbox))
