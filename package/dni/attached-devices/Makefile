# 
#  Copyright (C) 2007-2009 Delta Networks Inc.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=attached-devices
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_NETSCAN_GIT_TREEISH="a0ede1acf216a5bbd548f8716da81c3596779501"
CONFIG_NETSCAN_GIT_REPOSITORY="attached-devices.git"

PKG_GIT_TREEISH:=$(CONFIG_NETSCAN_GIT_TREEISH)

LOCAL_PKG_NAME_EXT:=attached-devices

include $(INCLUDE_DIR)/package.mk

define Package/attached-devices
	SECTION:=utils
	CATEGORY:=Network
	DEPENDS:=@TARGET_ipq806x +datalib +d2 +dil +ntgdal +dniutil
	TITLE:=Scanning the attached devices according to NETGEAR's spec.
endef

TARGET_CFLAGS += -DSUPPORT_FING="1"  -DDGC_MODULE_NAME="\\\"$(call qstrip,$(CONFIG_DGC_MODULE_NAME))\\\"" -ld2lib -ld2dil -ldal -lpthread -ldniutil

define Package/attached-devices/config
	menu "Configuration"
		depends on PACKAGE_attached-devices
		source "$(SOURCE)/Config.in"
	endmenu
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/attached-devices.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

EXTRA_CFLAGS := $(EXTRA_CFLAGS) $(call qstrip,$(CONFIG_NETSCAN_EXTRA_FLAGS))

define Package/attached-devices/install
	$(INSTALL_DIR)  $(1)/etc/init.d
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/files/attached-devices.init $(1)/etc/init.d/netscan
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/files/netscan_if.init $(1)/etc/init.d/netscan_if.init
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/files/send_soap $(1)/etc/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/oui.csv $(1)/etc/oui.csv
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/mam.csv $(1)/etc/mam.csv
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/oui36.csv $(1)/etc/oui36.csv
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/UA_String_Match_Table.txt $(1)/etc/UA_String_Match_Table.txt
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/device_type_table.json $(1)/etc/device_type_table.json
	$(INSTALL_DIR)  $(1)/usr/sbin
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/attached-devices $(1)/usr/sbin/net-scan
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/fing-devices $(1)/usr/sbin/fing-devices
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/dal-scan $(1)/usr/sbin/dal-scan
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/dev-scan $(1)/usr/sbin/
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/UA_Parser $(1)/usr/sbin/
	$(INSTALL_BIN)  $(PKG_BUILD_DIR)/devices_info $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,attached-devices))
