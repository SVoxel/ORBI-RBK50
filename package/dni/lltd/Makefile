# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.3 2007/01/12 02:45:49 ronger Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=lltd
PKG_VERSION:=0.1
PKG_RELEASE:=1

#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=$(DNI_DL_WEB) http://gentoo.osuosl.org/distfiles @SF/utelnetd
#PKG_MD5SUM:=45fc2b66b3d2dade396ed122a41d5b23
#PKG_CAT:=zcat

CONFIG_LLTD_GIT_TREEISH="lltd-v1.2-dni2"
CONFIG_LLTD_GIT_REPOSITORY="lltd.git"
PKG_GIT_TREEISH:=$(CONFIG_LLTD_GIT_TREEISH)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

LOCAL_PKG_NAME_EXT:=lltd

include $(INCLUDE_DIR)/package.mk

define Package/lltd
  SECTION:=net
  CATEGORY:=Base system
  DEPENDS:=@TARGET_ipq806x
  TITLE:=Link Layer Topology Discovery Daemon
  URL:=http://lltd.sourceforge.net/
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/lltd.git/* $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
endef

define Build/Compile
endef

MAKE_PATH := src/native-linux

define Package/lltd/install
	install -d -m0755 $(1)/etc/init.d
	install -m0755 $(PKG_BUILD_DIR)/files/lltd.init $(1)/etc/init.d/lltd
	install -m0755 -d $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/src/native-linux/lld2d $(1)/usr/sbin/
	install -m0755 -d $(1)/etc
	install -m0755 $(PKG_BUILD_DIR)/files/lld2d.conf  $(1)/etc/
	install -m0755 $(PKG_BUILD_DIR)/files/large.ico  $(1)/etc/
	install -m0755 $(PKG_BUILD_DIR)/files/icon.ico $(1)/etc/
	#install -m0755 -d $(1)/etc/init.d
	#install -m0755 $(PKG_BUILD_DIR)/files/lltd.init $(1)/etc/init.d/lltd
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,lltd))
