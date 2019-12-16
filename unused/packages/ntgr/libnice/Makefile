# Restored by Voxel
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libnice
PKG_VERSION:=0.1.10
#PKG_RELEASE:=1
PKG_LICENSE:=LGPLv2.1 & MPLv1.1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/libnice
  SECTION:=utils
  DEPENDS:=@TARGET_ipq806x glib2 librt
  TITLE:=Libnice is an implementation of the IETF's Interactive Connectivity Establishment (ICE) standard (RFC 5245).
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/libnice/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,libnice))
