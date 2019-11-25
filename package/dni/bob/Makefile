

include $(TOPDIR)/rules.mk


BTDIST_ROOT:=$(BUILD_DIR)/bluetopia-4.2.1.c1/
BTPM_ROOT:=$(BTDIST_ROOT)/BluetopiaPM_Dist
BT_ROOT=$(BTDIST_ROOT)/Bluetopia_Dist/

EXTRA_CFLAGS+= \
	-I $(BTPM_ROOT)/include \
	-I $(BTPM_ROOT)/include/client \
	-I $(BT_ROOT)/profiles/GATT/include \
	-I $(BT_ROOT)/include

EXTRA_LDFLAGS+= \
	-L$(BTPM_ROOT)/lib/client

PKG_NAME:=bob
PKG_VERSION:=1.8.10

PKG_BUILD_DIR:=$(BUILD_DIR)/bob-$(PKG_VERSION)
#PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/bob
  SECTION:=arlo
  CATEGORY:=arlo
  TITLE:=bob
  DEPENDS:= +ntgdal +libopenssl
endef

define Package/bob/description
 Netgear arlo bob
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -rp ./src/* $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/bob/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/bob $(1)/usr/bin
endef

$(eval $(call BuildPackage,bob))
