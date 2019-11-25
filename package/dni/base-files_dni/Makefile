#
# Copyright (C) 2007-2016 OpenWrt.org
# Copyright (C) 2010 Vertical Communications
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/version.mk

PKG_NAME:=base-files_dni
PKG_RELEASE:=157.2

LOCAL_PKG_NAME_EXT:=base-files_dni
PKG_FILE_DEPENDS:=$(shell [ -d $(DNI_HOME)/kernel/base-files/ ] && echo -n "$(DNI_HOME)/kernel/base-files/ ")

include $(INCLUDE_DIR)/package.mk

BASE_FILES_DEPENDS:=+base-files

define Package/base-files_dni
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=$(BASE_FILES_DEPENDS)
  TITLE:=Base filesystem for OpenWrt
  URL:=http://openwrt.org/
  VERSION:=$(PKG_RELEASE)-$(REVISION)
endef

define Package/base-files_dni/description
 This package contains a base filesystem and system scripts for OpenWrt.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/files
	if [ -d ./files/. ]; then \
		$(CP) ./files/* $(PKG_BUILD_DIR)/files/; \
	fi
	if [ -d $(PLATFORM_DIR)/base-files_dni/. ]; then \
		$(CP) $(PLATFORM_DIR)/base-files_dni/* $(PKG_BUILD_DIR)/files/; \
	fi
	$(call Build/Patch/Default)
	$(if $(PLATFORM_PATCH_DIR), $(call PatchDir,$(PKG_BUILD_DIR),$(PLATFORM_PATCH_DIR),))
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Build/Compile
endef

define Package/base-files_dni/install
	$(CP) $(PKG_BUILD_DIR)/files/* $(1)/
	if [ -d $(DNI_HOME)/kernel/base-files/. ]; then \
		$(CP) $(DNI_HOME)/kernel/base-files/* $(1)/; \
	fi
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,base-files_dni))
