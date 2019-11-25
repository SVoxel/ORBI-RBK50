# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 4855 2006-09-24 20:49:31Z nico $

include $(TOPDIR)/rules.mk

PKG_NAME:=udhcp-ext
PKG_VERSION:=0.9.8
PKG_RELEASE:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_UDHCP-EXT_GIT_TREEISH="udhcp-ext-v0.9.8-dni79"
CONFIG_UDHCP-EXT_GIT_REPOSITORY="udhcp.git"

LOCAL_PKG_NAME_EXT:=udhcp-ext

include $(INCLUDE_DIR)/package.mk

config-$(CONFIG_UDHCP-EXT_DHCPD_STATIC_LEASE)		+= --enable-dhcpd_static_lease
config-$(CONFIG_UDHCP-EXT_DHCPD_SHOW_HOSTNAME)		+= --enable-dhcpd_show_hostname
config-$(CONFIG_UDHCP-EXT_WAN_LAN_IPCONFLICT)		+= --enable-wan_lan_ipconflict
config-$(CONFIG_UDHCP-EXT_WAN_LAN_IPCONFLICT)		+= --with-ip_conflict_cmd=$(CONFIG_UDHCP-EXT_IP_CONFLICT_CMD)
config-$(CONFIG_UDHCP-EXT_RFC3442_121_SUPPORT)		+= --enable-rfc3442_121_support
config-$(CONFIG_UDHCP-EXT_RFC2132_33_SUPPORT)		+= --enable-rfc2132_33_support
config-$(CONFIG_UDHCP-EXT_RFC3442_249_SUPPORT)		+= --enable-rfc3442_249_support
config-$(CONFIG_UDHCP-EXT_DHCPD_CHECK_SERVER_IP)		+= --enable-dhcpd_check_server_ip
config-$(CONFIG_UDHCP-EXT_SUPPORT_OPTION_60)		+= --enable-support_option_60
config-$(CONFIG_UDHCP-EXT_SUPPORT_OPTION_43)		+= --enable-support_option_43
config-$(CONFIG_UDHCP-EXT_DHCPC_CHOOSE_OLDIP)		+= --enable-dhcpc_choose_oldip
config-$(CONFIG_UDHCP-EXT_DHCP_PACKET_RESIZE)		+= --enable-dhcp_packet_resize

define Package/udhcp-ext
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=@TARGET_ipq806x
  TITLE:=udhcp Server and Client Package
  URL:=http://udhcp.busybox.net/source
endef

define Package/udhcp-ext/description
 This package contains udhcp Server and Client.
endef

define Package/udhcp-ext/config
	menu "Configuration"
		depends on PACKAGE_udhcp-ext
		source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/udhcp-ext.git/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); \
		./configure \
			$(config-y) \
	);
endef

define Package/udhcp-ext/install
	install -d -m0755 $(1)/sbin
	install -m0755 $(PKG_BUILD_DIR)/udhcpd $(1)/sbin/udhcpd-ext
	install -m0755 $(PKG_BUILD_DIR)/udhcpc $(1)/sbin/udhcpc-ext
	install -d -m0755 $(1)/usr/share/udhcpc
	install -m0755 $(PKG_BUILD_DIR)/files/default.script.backhaul $(1)/usr/share/udhcpc/default.script.backhaul
	install -m0755 $(PKG_BUILD_DIR)/files/default.script $(1)/usr/share/udhcpc/default.script-ext
	install -m0755 $(PKG_BUILD_DIR)/files/default-arlo.script $(1)/usr/share/udhcpc/default-arlo.script-ext
	install -m0755 $(PKG_BUILD_DIR)/default.script.ap $(1)/usr/share/udhcpc/default.script.ap-ext
	install -d -m0755 $(1)/etc/init.d
	install -m0755 $(PKG_BUILD_DIR)/files/setacl $(1)/etc/init.d/setacl
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,udhcp-ext))
