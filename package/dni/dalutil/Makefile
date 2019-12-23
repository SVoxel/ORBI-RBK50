# Restored by Voxel
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dalutil
PKG_VERSION:=1
#PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/dalutil
  SECTION:=utils
  DEPENDS:=@TARGET_ipq806x datalib d2 dil ntgdal bst dniutil
  TITLE:=Updating speed test data to DAL and other DAL attached feature according to NETGEAR's spec.
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/dalutil/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/dal-set $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/rmdal-entry $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/dal-bst $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,dalutil))
