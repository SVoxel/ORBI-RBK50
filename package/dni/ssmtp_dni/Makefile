#
# Copyright (C) 2007-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ssmtp
PKG_VERSION:=2.64
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)_$(PKG_VERSION).orig.tar.bz2
PKG_SOURCE_URL:=http://ftp.debian.org/debian/pool/main/s/ssmtp
PKG_MD5SUM:=65b4e0df4934a6cd08c506cabcbe584f

LOCAL_PKG_NAME_EXT:=ssmtp_dni

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += $(TARGET_CPPFLAGS) -lconfig

define Package/ssmtp_dni
  SECTION:=mail
  CATEGORY:=Mail
  DEPENDS:=+libopenssl +datalib
  TITLE:=A minimal and secure mail sender
  URL:=http://packages.debian.org/ssmtp
endef

define Package/ssmtp_dni/description
 A secure, effective and simple way of getting mail off a system to your
 mail hub. It contains no suid-binaries or other dangerous things - no
 mail spool to poke around in, and no daemons running in the background.
 mail is simply forwarded to the configured mailhost. Extremely easy
 configuration.
endef

#define Package/ssmtp/conffiles
#/etc/ssmtp/ssmtp.conf
#/etc/ssmtp/revaliases
#endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/files
	$(PKG_UNPACK)
	$(CP) ./files/* $(PKG_BUILD_DIR)/files/
	$(call Build/Patch/Default)
	$(if $(PLATFORM_PATCH_DIR), $(call PatchDir,$(PKG_BUILD_DIR),$(PLATFORM_PATCH_DIR),))
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

CONFIGURE_VARS += \
	LIBS="$(TARGET_LDFLAGS) -lcrypto -lssl"

CONFIGURE_ARGS += \
	--enable-ssl

define Package/ssmtp_dni/install
	#$(INSTALL_DIR) $(1)/etc/ssmtp
	#$(INSTALL_CONF) $(PKG_BUILD_DIR)/ssmtp.conf $(1)/etc/ssmtp/
	#$(INSTALL_DATA) $(PKG_BUILD_DIR)/revaliases $(1)/etc/ssmtp/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ssmtp $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/email
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/email/email_log $(1)/etc/email/email_log
	ln -sf email_log $(1)/etc/email/email_full_log
	ln -sf email_log $(1)/etc/email/send_email_alert
	ln -sf email_log $(1)/etc/email/send_log
	ln -sf email_log $(1)/etc/email/email_HDD_err_log
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

define Package/ssmtp_dni/postinstall
	ln -sf ssmtp $${IPKG_INSTROOT}/usr/sbin/sendmail
endef

$(eval $(call BuildPackage,ssmtp_dni))
