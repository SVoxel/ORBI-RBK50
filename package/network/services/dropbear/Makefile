#
# Copyright (C) 2006-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dropbear
PKG_VERSION:=2022.83
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:= \
	http://matt.ucc.asn.au/dropbear/releases/ \
	https://dropbear.nl/mirror/releases/
PKG_MD5SUM:=a75a34bcc03cacf71a2db9da3b7c94a5

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE libtomcrypt/LICENSE libtommath/LICENSE
PKG_CPE_ID:=cpe:/a:matt_johnston:dropbear_ssh_server

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_FIXUP:=autoreconf

PKG_CONFIG_DEPENDS:= \
	CONFIG_TARGET_INIT_PATH CONFIG_DROPBEAR_ECC CONFIG_DROPBEAR_ECC_FULL \
	CONFIG_DROPBEAR_CURVE25519 CONFIG_DROPBEAR_ZLIB \
	CONFIG_DROPBEAR_UTMP CONFIG_DROPBEAR_PUTUTLINE \
	CONFIG_DROPBEAR_DBCLIENT

include $(INCLUDE_DIR)/package.mk

ifneq ($(DUMP),1)
  STAMP_CONFIGURED:=$(strip $(STAMP_CONFIGURED))_$(shell echo $(CONFIG_TARGET_INIT_PATH) | mkhash md5)
endif

define Package/dropbear/Default
  URL:=http://matt.ucc.asn.au/dropbear/
endef

define Package/dropbear/config
	source "$(SOURCE)/Config.in"
endef

define Package/dropbear
  $(call Package/dropbear/Default)
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=Small SSH2 client/server
  DEPENDS:= +DROPBEAR_ZLIB:zlib
  ALTERNATIVES:=\
	  100:/usr/bin/ssh:/usr/sbin/dropbear \
	  100:/usr/bin/scp:/usr/sbin/dropbear \

endef

define Package/dropbear/description
 A small SSH2 server/client designed for small memory environments.
endef

define Package/dropbear/conffiles
$(if $(CONFIG_DROPBEAR_ECC),/etc/dropbear/dropbear_ecdsa_host_key)
$(if $(CONFIG_DROPBEAR_CURVE25519),/etc/dropbear/dropbear_ed25519_host_key)
/etc/dropbear/dropbear_rsa_host_key
endef

CONFIGURE_ARGS += \
	--disable-pam \
	--enable-openpty \
	--enable-syslog \
	--disable-lastlog \
	--disable-utmpx \
	$(if $(CONFIG_DROPBEAR_UTMP),,--disable-utmp) \
	--disable-wtmp \
	--disable-wtmpx \
	--disable-loginfunc \
	$(if $(CONFIG_DROPBEAR_PUTUTLINE),,--disable-pututline) \
	--disable-pututxline \
	$(if $(CONFIG_DROPBEAR_ZLIB),,--disable-zlib) \
	--enable-bundled-libtom

TARGET_CFLAGS += -DARGTYPE=3 -ffunction-sections -fdata-sections -flto
TARGET_LDFLAGS += -Wl,--gc-sections -flto=jobserver

define Build/Configure
	: > $(PKG_BUILD_DIR)/localoptions.h

	$(Build/Configure/Default)

	echo '#define DEFAULT_PATH "$(TARGET_INIT_PATH)"' >> \
		$(PKG_BUILD_DIR)/localoptions.h

	echo '#define DROPBEAR_CURVE25519 $(if $(CONFIG_DROPBEAR_CURVE25519),1,0)' >> \
		$(PKG_BUILD_DIR)/localoptions.h

	for OPTION in DROPBEAR_ECDSA DROPBEAR_ECDH; do \
		echo "#define $$$$OPTION $(if $(CONFIG_DROPBEAR_ECC),1,0)" >> \
			$(PKG_BUILD_DIR)/localoptions.h; \
	done

	# disable legacy/unsafe methods and unused functionality
	for OPTION in INETD_MODE DROPBEAR_CLI_NETCAT \
	DROPBEAR_3DES DROPBEAR_DSS DROPBEAR_ENABLE_CBC_MODE \
	DROPBEAR_SHA1_96_HMAC DROPBEAR_USE_PASSWORD_ENV; do \
		echo "#define $$$$OPTION 0" >> \
			$(PKG_BUILD_DIR)/localoptions.h; \
	done

	# Enforce rebuild of svr-chansession.c
	rm -f $(PKG_BUILD_DIR)/svr-chansession.o

	# Rebuild them on config change
	+$(MAKE) -C $(PKG_BUILD_DIR)/libtomcrypt clean
	+$(MAKE) -C $(PKG_BUILD_DIR)/libtommath clean
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		PROGRAMS="dbclient dropbear dropbearconvert dropbearkey scp ssh" \
		MULTI=1
endef

define Package/dropbear/install
	$(INSTALL_DIR) $(1)/usr/{bin,sbin}
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dropbearmulti $(1)/usr/bin/dropbearmulti
	$(LN) dropbearmulti $(1)/usr/bin/dbclient
	$(LN) dropbearmulti $(1)/usr/bin/dropbearconvert
	$(LN) dropbearmulti $(1)/usr/bin/dropbearkey
	$(LN) dropbearmulti $(1)/usr/bin/scp
	$(LN) dropbearmulti $(1)/usr/bin/ssh
	$(LN) ../bin/dropbearmulti $(1)/usr/sbin/dropbear
	$(INSTALL_DIR) $(1)/etc/{dropbear,init.d}
	$(INSTALL_BIN) ./files/dropbear.init    $(1)/etc/init.d/dropbear
	$(CP) ./files/dropbear_ecdsa_host_key   $(1)/etc/dropbear
	$(CP) ./files/dropbear_ed25519_host_key $(1)/etc/dropbear
	$(CP) ./files/dropbear_rsa_host_key     $(1)/etc/dropbear
	chmod 0600 $(1)/etc/dropbear/dropbear_ecdsa_host_key
	chmod 0600 $(1)/etc/dropbear/dropbear_ed25519_host_key
	chmod 0600 $(1)/etc/dropbear/dropbear_rsa_host_key
	$(CP) ./files/ssh_host_ecdsa_key.pub    $(1)/etc/dropbear
	$(CP) ./files/ssh_host_ed25519_key.pub  $(1)/etc/dropbear
	$(CP) ./files/ssh_host_rsa_key.pub      $(1)/etc/dropbear
	$(INSTALL_DIR) $(1)/root/.ssh
endef

$(eval $(call BuildPackage,dropbear))
