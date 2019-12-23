# Restored by Voxel
#

include $(TOPDIR)/rules.mk

PKG_NAME:=control-firmware
PKG_VERSION:=1
#PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/control-firmware
  SECTION:=utils
  DEPENDS:=@TARGET_ipq806x fwcheck d2
  TITLE:=control-firmware.
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/control-firmware/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/control_firmware.init $(1)/etc/init.d/control_firmware
	$(INSTALL_BIN) ./files/boot-notification $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/control-firmware $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,control-firmware))
