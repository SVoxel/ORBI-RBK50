# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 4855 2006-09-24 20:49:31Z nico $

include $(TOPDIR)/rules.mk

PKG_NAME:=udhcp
PKG_VERSION:=0.9.8
PKG_RELEASE:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_UDHCP_GIT_TREEISH="f7907029951b0441f046abaa7b554bc98d8f2828"
CONFIG_UDHCP_GIT_REPOSITORY="udhcp.git"

LOCAL_PKG_NAME_EXT:=udhcp

include $(INCLUDE_DIR)/package.mk

config-$(CONFIG_UDHCP_DHCPD_STATIC_LEASE)		+= --enable-dhcpd_static_lease
config-$(CONFIG_UDHCP_DHCPD_SHOW_HOSTNAME)		+= --enable-dhcpd_show_hostname
config-$(CONFIG_UDHCP_WAN_LAN_IPCONFLICT)		+= --enable-wan_lan_ipconflict
config-$(CONFIG_UDHCP_WAN_LAN_IPCONFLICT)		+= --with-ip_conflict_cmd=$(CONFIG_UDHCP_IP_CONFLICT_CMD)
config-$(CONFIG_UDHCP_RFC3442_121_SUPPORT)		+= --enable-rfc3442_121_support
config-$(CONFIG_UDHCP_RFC2132_33_SUPPORT)		+= --enable-rfc2132_33_support
config-$(CONFIG_UDHCP_RFC3442_249_SUPPORT)		+= --enable-rfc3442_249_support
config-$(CONFIG_UDHCP_DHCPD_CHECK_SERVER_IP)		+= --enable-dhcpd_check_server_ip
config-$(CONFIG_UDHCP_SUPPORT_OPTION_60)		+= --enable-support_option_60
config-$(CONFIG_UDHCP_SUPPORT_OPTION_77)		+= --enable-support_option_77
config-$(CONFIG_UDHCP_SUPPORT_OPTION_90)		+= --enable-support_option_90
config-$(CONFIG_UDHCP_SUPPORT_OPTION_43)		+= --enable-support_option_43
config-$(CONFIG_UDHCP_DHCPC_CHOOSE_OLDIP)		+= --enable-dhcpc_choose_oldip
config-$(CONFIG_UDHCP_DHCP_PACKET_RESIZE)		+= --enable-dhcp_packet_resize
config-$(CONFIG_UDHCP_SATELLITE_MODEL_NAME_SUPPORT)		+= --with-satellite_model_name=$(CONFIG_UDHCP_SATELLITE_MODEL_NAME)
config-$(CONFIG_UDHCP_SUPPORT_ARLO)        += --enable-support_arlo
config-$(CONFIG_DHCPD_SHOW_CLIENT_OPTIONS)		+= --enable-dhcpd_show_client_options

define Package/udhcp
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=@TARGET_ipq806x +datalib
  TITLE:=udhcp Server and Client Package
  URL:=http://udhcp.busybox.net/source
endef

define Package/udhcp/description
 This package contains udhcp Server and Client.
endef

define Package/udhcp/config
	menu "Configuration"
		depends on PACKAGE_udhcp
		source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/udhcp.git/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); \
		./configure \
			$(config-y) \
	);
endef

define Package/udhcp/install
	install -d -m0755 $(1)/sbin
	install -m0755 $(PKG_BUILD_DIR)/udhcpd $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/udhcpc $(1)/sbin/
	install -d -m0755 $(1)/usr/share/udhcpc
	install -m0755 $(PKG_BUILD_DIR)/default.script $(1)/usr/share/udhcpc/
	install -m0755 $(PKG_BUILD_DIR)/default.script.ap $(1)/usr/share/udhcpc/
	install -d -m0755 $(1)/usr/share/zcip
	install -m0755 $(PKG_BUILD_DIR)/files/zcip.script $(1)/usr/share/zcip/
	install -m0755 $(PKG_BUILD_DIR)/files/org_dhcp_pri_config.script $(1)/usr/share/udhcpc/
	install -m0755 $(PKG_BUILD_DIR)/files/org_check_egress_pri.script $(1)/usr/share/udhcpc/
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/files/sync_arlo_arp $(1)/usr/sbin/sync_arlo_arp
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,udhcp))
