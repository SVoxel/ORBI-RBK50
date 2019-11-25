include $(TOPDIR)/rules.mk
	
PKG_NAME:=circle
PKG_RELEASE:=1
			  
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
			    
include $(INCLUDE_DIR)/package.mk

LOCAL_PKG_NAME_EXT:=circle

define Package/circle
	CATEGORY:=Bigfoot
	TITLE:=circle parental control related files
	DEPENDS:= +libopenssl +libpthread
endef
					
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/circle/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/circle_init $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/circled $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/circle_check_account $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/backup_cfg $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/parental_cmd $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/check_connect $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/lib/circle
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/database.bin $(1)/lib/circle
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/firmware.bin $(1)/lib/circle
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef
							
#call func is to expand BuildPackage with "circle" as the param.
$(eval $(call BuildPackage,circle))
