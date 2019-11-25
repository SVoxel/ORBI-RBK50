#
# Copyright (C) 2008 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=insight
PKG_VERSION:=0.01
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=insight

include $(INCLUDE_DIR)/package.mk

define Package/insight
  SECTION:=dni
  CATEGORY:=DNI Package
  TITLE:=insight
endef


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/files
	if [ -d ./files ] ; then \
		$(CP) ./files/* $(PKG_BUILD_DIR)/files; \
	fi
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Build/Compile
endef

define Package/insight/install
	$(CP) $(PKG_BUILD_DIR)/files/* $(1)/
endef

$(eval $(call BuildPackage,insight))
