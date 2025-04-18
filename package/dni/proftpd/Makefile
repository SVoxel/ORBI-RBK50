#
# Copyright (C) 2009-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=proftpd
PKG_VERSION:=1.3.9
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=ftp://ftp.proftpd.org/distrib/source
PKG_MD5SUM:=760b2bf912e4ac26b5f1aa9d25b440c6

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS := $(filter-out -O%,$(TARGET_CFLAGS)) -Os
TARGET_CFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

define Package/proftpd
  SUBMENU:=File Transfer
  SECTION:=net
  CATEGORY:=Network
  TITLE:=ProFTPD FTP server
  URL:=http://www.proftpd.org/
  MAINTAINER:=Cezary Jackiewicz <cezary@eko.one.pl>
  DEPENDS:=+libintl-full +libiconv-full +libncurses
endef

MAKE_FLAGS += \
	INSTALL_USER=$(shell id -u) \
	INSTALL_GROUP=$(shell id -g)

CONFIGURE_ARGS += \
	--with-includes=$(STAGING_DIR)/include:$(STAGING_DIR)/usr/include:$(STAGING_DIR)/usr/lib/libintl-full/include:$(STAGING_DIR)/usr/lib/libiconv-full/include \
	--with-libraries=$(STAGING_DIR)/lib:$(STAGING_DIR)/usr/lib:$(STAGING_DIR)/usr/lib/libintl-full/lib:$(STAGING_DIR)/usr/lib/libiconv-full/lib \
	--disable-cap \
	--disable-auth-pam \
	--disable-strip \
	--with-lastlog=/var/log \
	--enable-autoshadow \
	--enable-nls \
	--enable-largefile \

CONFIGURE_VARS += \
	ac_cv_header_curses_h=no \
	ac_cv_header_ncurses_h=no

define Build/Configure
	$(call Build/Configure/Default)
	$(SED) 's/HAVE_LU/HAVE_LLU/g' $(PKG_BUILD_DIR)/config.h
endef

define Package/proftpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/proftpd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ftptop $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) ./files/cmdftp $(1)/sbin/
	$(LN) /usr/sbin/ftptop $(1)/usr/sbin/ftpload
	$(INSTALL_DIR) $(1)/usr/share
	$(CP) $(PKG_INSTALL_DIR)/usr/share/locale $(1)/usr/share/
endef

$(eval $(call BuildPackage,proftpd))
