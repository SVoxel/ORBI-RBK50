# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile,v 1.1.2.2 2007/01/31 06:23:51 ronger Exp $

include $(TOPDIR)/rules.mk

PKG_NAME:=dniminiupnpd
PKG_VERSION:=20070127
PKG_RELEASE:=3

CONFIG_DNIMINIUPNPD_GIT_TREEISH="miniupnpd-20070127-dni43"
CONFIG_DNIMINIUPNPD_GIT_REPOSITORY="miniupnpd.git"

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

WAN_IFNAME_VAR:=$(CONFIG_DGC_IF_WAN_IFNAME)
LAN_IFNAME:=\\\"$(CONFIG_DGC_IF_LAN_IFNAME)\\\"

LOCAL_PKG_NAME_EXT:=dniminiupnpd

include $(INCLUDE_DIR)/package.mk

config-y					= --with-friendly_name=$(CONFIG_DNIMINIUPNPD_FRIENDLYNAME)
config-y					+= --with-model_name=$(CONFIG_DNIMINIUPNPD_MODELNAME)
config-y					+= --with-model_number=$(CONFIG_DNIMINIUPNPD_MODELNUMBER)
config-y                                        += --with-service_name=$(CONFIG_DNIMINIUPNPD_SERVICENAME)
config-y					+= --with-universal_product_code=$(CONFIG_DNIMINIUPNPD_DEVUPC)
config-y					+= --with-model_url=$(CONFIG_DNIMINIUPNPD_MODELURL)
config-y					+= --with-wan_ifname=$(WAN_IFNAME_VAR)
config-$(CONFIG_DNIMINIUPNPD_SUPPORT_PNPX)		+= --enable-support_pnpx
config-$(CONFIG_DNIMINIUPNPD_SUPPORT_PNPX)		+= --with-pnpx_hwid=$(CONFIG_DNIMINIUPNPD_PNPX_HWID)

define Package/dniminiupnpd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Miniupnpd Daemon
  DEPENDS:=+datalib
  URL:=http://pptpclient.sourceforge.net/
endef

define Package/dniminiupnpd/config
	menu "Configuration"
		depends on PACKAGE_dniminiupnpd
		source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/miniupnpd.git/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/dniminiupnpd/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/miniupnpd $(1)/usr/sbin/
	install -d -m0755 $(1)/sbin
	install -m0755 $(PKG_BUILD_DIR)/cmdupnp $(1)/sbin/
	install -d -m0755 $(1)/etc/init.d
	install -m0755 $(PKG_BUILD_DIR)/files/upnp.init $(1)/etc/init.d/upnp
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,dniminiupnpd))
