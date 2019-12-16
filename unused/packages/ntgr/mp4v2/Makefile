# Restored by Voxel
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mp4v2
PKG_VERSION:=1.9.1
#PKG_RELEASE:=1
PKG_LICENSE:=MPLv1.1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/mp4v2
  SECTION:=utils
  DEPENDS:=@TARGET_ipq806x libstdcpp
  TITLE:=This library provides functions to read, create, and modify mp4 file
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/mp4v2/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,mp4v2))
