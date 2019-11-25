# 
#  Copyright (C) 2007 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=igmpproxy_dni
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
CONFIG_DIR=${shell pwd}

LOCAL_PKG_NAME_EXT:=igmpproxy_dni

include $(INCLUDE_DIR)/package.mk

define Package/igmpproxy_dni
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=+libpcap +datalib
	TITLE:=igmp for Embedded Router.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Package/igmpproxy_dni/install
	install -d -m0755 $(1)/sbin
	install -d -m0755 $(1)/etc/init.d
	install -m0755 $(PKG_BUILD_DIR)/igmpproxy $(1)/sbin/
	install -m0755 $(PKG_BUILD_DIR)/files/igmpproxy.init $(1)/etc/init.d/
	install -m0755 $(PKG_BUILD_DIR)/files/cmdigmp $(1)/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,igmpproxy_dni))
