#
# Copyright (C) 2010-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libusb
PKG_VERSION:=1.0.29
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=@SF/$(PKG_NAME)
PKG_MD5SUM:=12d4a782ce606a0582fb5038c16d0f75

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=0
PKG_LICENSE:=LGPL-2.1

PKG_MAINTAINER := Felix Fietkau <nbd@openwrt.org>

include $(INCLUDE_DIR)/package.mk

define Package/libusb-1.0
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=A library for accessing Linux USB devices
  DEPENDS:=+libpthread +librt
  URL:=http://libusb.wiki.sourceforge.net/
endef

define Package/libusb-1.0/description
  libusb is a C library that gives applications easy access to USB devices on
  many different operating systems.
endef

TARGET_CFLAGS += $(FPIC)
CONFIGURE_ARGS += \
	--disable-udev \
	--disable-log

define Build/InstallDev
	$(CP) $(PKG_INSTALL_DIR)/* $(1)/
endef

define Package/libusb-1.0/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libusb*.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libusb-1.0))
