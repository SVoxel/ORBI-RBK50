# 
# Copyright (C) 2008 OpenWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wlan-common
PKG_VERSION:=2.5
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

CONFIG_WLAN_COMMON_GIT_TREEISH="b324d0e3407a9138d0ec0b7590c500d386669760"
CONFIG_WLAN_COMMON_GIT_REPOSITORY="wlan-common.git"
CONFIG_WLAN_COMMON_GIT_URL="ssh://dniserver/scm/dnigit/apps/wlan-common/spencer/wlan-common.git"

LOCAL_PKG_NAME_EXT:=wlan-common

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/wlan-common
  SECTION:=net
  CATEGORY:=Network
  TITLE:=DNI wlan common scripts
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/wlan-common.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/wlan-common/install
	$(INSTALL_DIR) $(1)/etc
	cp -af $(PKG_BUILD_DIR)/etc/* $(1)/etc
	if [ -f $(PKG_BUILD_DIR)/etc/ath/wifi.conf ]; then \
		sed -i 's/vht_11ng=.*/vht_11ng="on"/g' $(1)/etc/ath/wifi.conf; \
		sed -i 's/^wla2_exist=.*/wla2_exist="on"/g' $(1)/etc/ath/wifi.conf; \
		sed -i 's/^USE_QCA_SECTION_RULE=.*/USE_QCA_SECTION_RULE=1/g' $(1)/etc/ath/wifi.conf; \
	fi
	$(INSTALL_DIR) $(1)/sbin
	cp -af $(PKG_BUILD_DIR)/sbin/* $(1)/sbin
	$(INSTALL_DIR) $(1)/lib/wifi/
	cp -af $(PKG_BUILD_DIR)/lib/wifi/* $(1)/lib/wifi
	$(INSTALL_DIR) $(1)/usr/sbin
	cp -af ./files/* $(1)/
	install -d -m0755 $(1)/etc/config
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call BuildPackage,wlan-common))
