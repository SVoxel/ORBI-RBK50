# 
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=patch
PKG_VERSION:=2.8
PKG_RELEASE:=1
PKG_CPE_ID:=cpe:/a:gnu:patch

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=@GNU/patch
PKG_HASH:=f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3

HOST_BUILD_PARALLEL := 1

include $(INCLUDE_DIR)/host-build.mk

HOSTCC := $(HOSTCC_NOCACHE)
HOSTCXX := $(HOSTCXX_NOCACHE)

$(eval $(call HostBuild))
