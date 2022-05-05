include $(TOPDIR)/rules.mk
	
PKG_NAME:=circle
PKG_RELEASE:=1
			  
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
			    
include $(INCLUDE_DIR)/package.mk

LOCAL_PKG_NAME_EXT:=circle

define Package/circle
	CATEGORY:=Bigfoot
	TITLE:=circle parental control related files
	DEPENDS:= +libopenssl +libpthread +d2 +libcurl +libpcap
endef
					
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/circle/install
	$(CP) -rf $(PKG_BUILD_DIR)/Binary/* $(1)/
endef
							
#call func is to expand BuildPackage with "circle" as the param.
$(eval $(call BuildPackage,circle))
