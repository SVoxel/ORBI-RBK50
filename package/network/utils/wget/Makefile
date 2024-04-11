#
# Copyright (C) 2007-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wget
PKG_VERSION:=1.24.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@GNU/$(PKG_NAME)
PKG_MD5SUM:=271bf949384d0858c2c3d419f6311365
PKG_MAINTAINER:=Maxim Storchak <m.storchak@gmail.com>
PKG_LICENSE:=GPL-3.0+
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

TARGET_CPPFLAGS:=-I$(STAGING_DIR)/usr/include/openssl-1.1.x $(TARGET_CPPFLAGS)
TARGET_LDFLAGS:=-L$(STAGING_DIR)/usr/lib/openssl-1.1.x $(TARGET_LDFLAGS)
TARGET_CFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

define Package/wget/Default
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libpcre
  SUBMENU:=File Transfer
  TITLE:=Non-interactive network downloader
  URL:=http://www.gnu.org/software/wget/index.html
endef

define Package/wget/Default/description
 Wget is a network utility to retrieve files from the Web using http
 and ftp, the two most widely used Internet protocols. It works
 non-interactively, so it will work in the background, after having
 logged off. The program supports recursive retrieval of web-authoring
 pages as well as ftp sites -- you can use wget to make mirrors of
 archives and home pages or to travel the Web like a WWW robot.
endef

define Package/wget
$(call Package/wget/Default)
  DEPENDS+= +libopenssl-1.1.x +librt +zlib
  TITLE+= (with SSL support)
  VARIANT:=ssl
endef

define Package/wget/description
$(call Package/wget/Default/description)
 This package is built with SSL support.
endef

define Package/wget-nossl
$(call Package/wget/Default)
  TITLE+= (without SSL support)
  DEPENDS+= +zlib
  VARIANT:=nossl
endef

define Package/wget-nossl/description
$(call Package/wget/Default/description)
 This package is built without SSL support.
endef

CONFIGURE_ARGS+= \
	--disable-rpath \
	--disable-iri \
	--without-libuuid

CONFIGURE_VARS += \
	ac_cv_header_uuid_uuid_h=no

ifeq ($(BUILD_VARIANT),ssl)
	CONFIGURE_ARGS+= \
		--with-ssl=openssl \
		--with-libssl-prefix="$(STAGING_DIR)/usr/lib/openssl-1.1.x"
endif

ifeq ($(BUILD_VARIANT),nossl)
	CONFIGURE_ARGS+= \
		--disable-ntlm \
		--without-ssl
endif

define Package/wget/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/wget $(1)/usr/bin/wget-ssl
endef

define Package/wget-nossl/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/wget $(1)/usr/bin/wget-nossl
endef

define Package/wget/postinst
#!/bin/sh
if [ -e $${IPKG_INSTROOT}/usr/bin/wget ]; then
  rm -rf $${IPKG_INSTROOT}/usr/bin/wget;
fi
ln -sf ./wget-ssl $${IPKG_INSTROOT}/usr/bin/wget
endef

define Package/wget/postrm
#!/bin/sh
rm $${IPKG_INSTROOT}/usr/bin/wget
[ -x $${IPKG_INSTROOT}/usr/bin/wget-nossl ] && ln -s ./wget-nossl $${IPKG_INSTROOT}/usr/bin/wget || {
  ln -s ../../bin/busybox $${IPKG_INSTROOT}/usr/bin/wget
  $${IPKG_INSTROOT}/usr/bin/wget 2>&1 | grep 'applet not found' > /dev/null 2>&1 && rm $${IPKG_INSTROOT}/usr/bin/wget
}
exit 0
endef

define Package/wget-nossl/postinst
#!/bin/sh
if [ -e $${IPKG_INSTROOT}/usr/bin/wget ]; then
  rm -rf $${IPKG_INSTROOT}/usr/bin/wget;
fi
ln -s ./wget-nossl $${IPKG_INSTROOT}/usr/bin/wget
endef

define Package/wget-nossl/postrm
#!/bin/sh
rm $${IPKG_INSTROOT}/usr/bin/wget
[ -x $${IPKG_INSTROOT}/usr/bin/wget-ssl ] && ln -s ./wget-ssl $${IPKG_INSTROOT}/usr/bin/wget || {
  ln -s ../../bin/busybox $${IPKG_INSTROOT}/usr/bin/wget
  $${IPKG_INSTROOT}/usr/bin/wget 2>&1 | grep 'applet not found' > /dev/null 2>&1 && rm $${IPKG_INSTROOT}/usr/bin/wget
}
exit 0
endef

$(eval $(call BuildPackage,wget))
$(eval $(call BuildPackage,wget-nossl))
