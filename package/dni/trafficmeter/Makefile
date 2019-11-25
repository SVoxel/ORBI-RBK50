# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.2 2007/02/06 13:52:33 anderson Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=traffic_meter
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

CONFIG_TRAFFICMETER_GIT_TREEISH="trafficmeter-v2.0.0-dni49"
CONFIG_TRAFFICMETER_GIT_REPOSITORY="trafficmeter.git"
PKG_GIT_TREEISH:=$(CONFIG_TRAFFICMETER_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=trafficmeter

include $(INCLUDE_DIR)/package.mk

define Package/trafficmeter
  SECTION:=utils
  CATEGORY:=Base system
  DEPENDS:=@TARGET_ipq806x +datalib
  TITLE:=Update utility for trx firmware images
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/trafficmeter.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/trafficmeter/install
	install -d -m0755 $(1)/sbin
	install -d -m0755 $(1)/etc
	install -d -m0755 $(1)/etc/init.d
	install -d -m0755 $(1)/usr
	install -d -m0755 $(1)/usr/traffic_meter
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/sbin/generate_traffic_meter_conf $(1)/sbin/generate_traffic_meter_conf
	$(CP) $(PKG_BUILD_DIR)/files/last_* $(1)/usr/traffic_meter/
	$(CP) $(PKG_BUILD_DIR)/files/network_status $(1)/usr/traffic_meter/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/traffic_meter $(1)/usr/traffic_meter/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/traffic_statistics $(1)/usr/traffic_meter/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/traffic_meter.init $(1)/etc/init.d/traffic_meter
	install -m0755 $(PKG_BUILD_DIR)/traffic_meter $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/cmd_traffic_meter $(1)/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,trafficmeter))
