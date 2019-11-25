include $(TOPDIR)/rules.mk

PKG_NAME:=ntgdal
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

#include $(INCLUDE_DIR)/local-development.mk
#ifeq ($(DUMP)$(PKG_VERSION),)
#PKG_REV:=381256a
#PKG_VERSION:=g381256a
#endif
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
#PKG_SOURCE_VERSION:=$(PKG_REV)
#PKG_SOURCE_MIRROR:=none
#PKG_BUILD_DEPENDS:=argp-standalone

#PKG_FIXUP:=autoreconf
#PKG_REMOVE_FILES:=autogen.sh

include $(INCLUDE_DIR)/package.mk

# use SPACES here instead of tabs
define Package/ntgdal
  SECTION:=utils
  CATEGORY:=Network
  TITLE:=ntgdal lib and utils for bluetooth
  DEPENDS:=+libsbdaemon +hiredis +libc +bluetopia +datalib
endef


include $(INCLUDE_DIR)/package.mk


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef



define Package/ntgdal/description
	ntgdal lib and utils for bluetooth.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libdal.so    $(1)/usr/lib/libdal.so
	
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/include/libdal.h $(1)/usr/include
endef


define Package/ntgdal/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dal     $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/btdm     $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libdal.so    $(1)/usr/lib/libdal.so
	
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/include/libdal.h $(1)/usr/include
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ntgdal $(1)/etc/init.d/ntgdal
endef

$(eval $(call BuildPackage,ntgdal))
