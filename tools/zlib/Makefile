#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=zlib
PKG_VERSION:=1.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=@SF/libpng http://www.zlib.net
PKG_HASH:=8a9ba2898e1d0d774eca6ba5b4627a11e5588ba85c8851336eb38de4683050a7

PKG_LICENSE:=Zlib
PKG_LICENSE_FILES:=README
PKG_CPE_ID:=cpe:/a:gnu:zlib

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/cmake.mk

HOST_CFLAGS +=-fPIC

define Host/Install
	$(CP) $(HOST_BUILD_DIR)/libz.a $(STAGING_DIR_HOST)/lib/
	$(CP) $(HOST_BUILD_DIR)/zconf.h $(STAGING_DIR_HOST)/include/
	$(CP) $(HOST_BUILD_DIR)/zlib.h $(STAGING_DIR_HOST)/include/
	$(CP) $(HOST_BUILD_DIR)/zlib.pc $(STAGING_DIR_HOST)/lib/pkgconfig/
endef

define Host/Clean
	rm -f $(STAGING_DIR_HOST)/lib/libz.a
	rm -f $(STAGING_DIR_HOST)/include/zconf.h
	rm -f $(STAGING_DIR_HOST)/include/zlib.h
	rm -f $(STAGING_DIR_HOST)/lib/pkgconfig//zlib.pc
endef

$(eval $(call HostBuild))
