#
# Copyright (C) 2006-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=radvd_dni
PKG_VERSION:=1.5
PKG_RELEASE:=1

#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=$(DNI_DL_WEB) \
#		http://v6web.litech.org/radvd/dist \
#		http://download.sourcemage.org/mirror
#PKG_MD5SUM:=78598b60ed9d64920739189c3dc0934d

CONFIG_RADVD_GIT_TREEISH="radvd-1.5-dni15"
CONFIG_RADVD_GIT_REPOSITORY="radvd.git"

PKG_GIT_TREEISH:=$(CONFIG_RADVD_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=radvd_dni

include $(INCLUDE_DIR)/package.mk

define Package/radvd_dni
  SECTION:=ipv6
  CATEGORY:=IPv6
  TITLE:=IPv6 Routing Advertisement Daemon
  URL:=http://v6web.litech.org/radvd/
  DEPENDS:=+kmod-ipv6
endef

define Package/radvd_dni/description
IPv6 Routing Advertisement Daemon.
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/radvd.git/* $(PKG_BUILD_DIR)/
	touch $(PKG_BUILD_DIR)/*
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) radvd_LDADD=""
endef

define Build/Configure
	$(call Build/Configure/Default,\
		--with-configfile=/etc/radvd.conf \
		--with-logfile=/var/log/radvd.log \
		--with-pidfile=/var/run/radvd.pid \
	)
endef

define Package/radvd_dni/conffiles
/etc/config/radvd
endef

define Package/radvd_dni/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/radvd.config $(1)/etc/config/radvd
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/radvd.conf $(1)/etc/
	#$(INSTALL_DIR) $(1)/etc/init.d
	#$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/radvd.init $(1)/etc/init.d/radvd
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/radvd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/radvdump $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,radvd_dni))
