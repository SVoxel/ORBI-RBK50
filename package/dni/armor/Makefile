include $(TOPDIR)/rules.mk
	
PKG_NAME:=armor
PKG_RELEASE:=1
			  
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
			    
include $(INCLUDE_DIR)/package.mk

LOCAL_PKG_NAME_EXT:=armor

define Package/armor
	CATEGORY:=Bigfoot
	TITLE:=armor and bitdefender related files
	DEPENDS:= +libpthread
endef

define Package/armor/config
	menu "Configuration"
		depends on PACKAGE_armor
		source "$(SOURCE)/Config.in"
	endmenu
endef
					
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/armor/install
	install -d -m0755 $(1)/lib/
	$(CP) $(PKG_BUILD_DIR)/lib/libbdbroker.so $(1)/lib/
	$(INSTALL_DIR) $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bdupd_start.sh $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bdupd_start_schedule.sh $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/get_armor_status $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/change_cloud_server.sh $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/BD_START.sh $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/upgrade_bd_cfg.sh $(1)/usr/share/armor
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bdbroker-client-cmd $(1)/usr/share/armor/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bdbroker-client-loop $(1)/usr/share/armor/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bdbroker-client-thread $(1)/usr/share/armor/
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/armor_init $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/lib/armor/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef
							
#call func is to expand BuildPackage with "armor" as the param.
$(eval $(call BuildPackage,armor))
