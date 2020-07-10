#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

BASE_NAME:=json-c
PKG_NAME:=$(BASE_NAME)-012
PKG_VERSION:=0.12.1
PKG_RELEASE:=1

PKG_SOURCE:=$(BASE_NAME)-$(PKG_VERSION)-nodoc.tar.gz
PKG_SOURCE_URL:=https://s3.amazonaws.com/json-c_releases/releases/
PKG_HASH:=5a617da9aade997938197ef0f8aabd7f97b670c216dc173977e1d56eef9e1291
PKG_SOURCE_SUBDIR:=$(BASE_NAME)-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:json-c_project:json-c

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

TARGET_CFLAGS += $(FPIC) -Wno-implicit-fallthrough
HOST_CFLAGS += -Wno-implicit-fallthrough
HOST_BUILD_PREFIX:=$(STAGING_DIR_HOST)

define Package/libjson-c-012
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=javascript object notation
  URL:=https://json-c.github.io/json-c/
  ABI_VERSION:=2
endef

define Package/libjson-c-012/description
 This package contains a library for javascript object notation backends.
endef

define Package/libjson-c-012/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libjson-c.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libjson-c-012))
