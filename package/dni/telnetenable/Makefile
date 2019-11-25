# 
# Copyright (C) 2008 OpenWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=telnetenable
PKG_RELEASE:=1

CONFIG_TELNETENABLE_GIT_TREEISH="telnetenable-dni5"
CONFIG_TELNETENABLE_GIT_REPOSITORY="telnetenable.git"

PKG_GIT_TREEISH:=$(CONFIG_TELNETENABLE_GIT_TREEISH)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=telnetenable

include $(INCLUDE_DIR)/package.mk

define Package/telnetenable
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=+datalib
	TITLE:=unlocking the utelnetd.
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/telnetenable.git/* $(PKG_BUILD_DIR)/
endef

define Package/telnetenable/install
	install -d -m0755 $(1)/usr/sbin
	install -m0755 $(PKG_BUILD_DIR)/telnetenable $(1)/usr/sbin/
	install -d -m0755 $(1)/lib/network
	install -m0755 $(PKG_BUILD_DIR)/files/RtDebug.sh $(1)/lib/network/
	install -d -m0755 $(1)/etc/init.d
	install -m0755 $(PKG_BUILD_DIR)/files/telnet.init $(1)/etc/init.d/telnet
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,telnetenable))
