#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lighttpd
PKG_VERSION:=1.4.69
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=http://download.lighttpd.net/lighttpd/releases-1.4.x
PKG_MD5SUM:=15cf1d07b4130d82673d8630251cf997

PKG_LICENSE:=BSD-3c
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

LOCAL_PKG_NAME_EXT:=lighttpd_dni

include $(INCLUDE_DIR)/package.mk

TARGET_CPPFLAGS:=-I$(STAGING_DIR)/usr/include/openssl-1.1.x $(TARGET_CPPFLAGS)
TARGET_LDFLAGS:=-L$(STAGING_DIR)/usr/lib/openssl-1.1.x $(TARGET_LDFLAGS)
TARGET_CFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

define Package/lighttpd_dni/Default
  SUBMENU:=Web Servers/Proxies
  SECTION:=net
  CATEGORY:=Network
  URL:=http://www.lighttpd.net/
  MAINTAINER:=W. Michael Petullo <mike@flyn.org>
endef

define Package/lighttpd_dni
  $(call Package/lighttpd_dni/Default)
  MENU:=1
  DEPENDS:=+LIGHTTPD_SSL:libopenssl-1.1.x +libpcre +libpthread
  TITLE:=A flexible and lightweight web server
endef

define Package/lighttpd_dni/config
config LIGHTTPD_SSL
	bool "SSL support"
	depends on PACKAGE_lighttpd_dni
	default y
	help
	  Implements SSL support in lighttpd (using libopenssl). This
	  option is required if you enable the SSL engine in your
	  lighttpd confguration file.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/files
	$(PKG_UNPACK)
	$(CP) ./files/* $(PKG_BUILD_DIR)/files/
	$(call Build/Patch/Default)
	$(if $(PLATFORM_PATCH_DIR), $(call PatchDir,$(PKG_BUILD_DIR),$(PLATFORM_PATCH_DIR),))
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

CONFIGURE_ARGS+= \
	--libdir=/usr/lib/lighttpd \
	--sysconfdir=/etc/lighttpd \
	--enable-shared \
	--enable-static \
	--disable-rpath \
	--without-attr \
	--without-bzip2 \
	--without-fam \
	--without-gdbm \
	--without-ldap \
	--with-lua \
	--without-memcache \
	--with-pcre \
	--without-valgrind \
	 $(call autoconf_bool,CONFIG_IPV6,ipv6)

CONFIGURE_VARS+= \
	PCRE_LIB="-lpcre" \

ifneq ($(strip $(CONFIG_LIGHTTPD_SSL)),)
  CONFIGURE_ARGS+= \
	--with-openssl="$(STAGING_DIR)/usr/lib/openssl-1.1.x"
else
  CONFIGURE_ARGS+= \
	--without-openssl
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_lighttpd_dni-mod-mysql-vhost),)
  CONFIGURE_ARGS+= \
	--with-mysql
else
  CONFIGURE_ARGS+= \
	--without-mysql
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_lighttpd_dni-mod-webdav),)
  CONFIGURE_ARGS+= \
	--with-webdav-locks \
	--with-webdav-props
  # XXX: needed by sqlite3 to prevent segfaults in mod_webdav.so
  CONFIGURE_VARS+= \
	LIBS="-lpthread"
else
  CONFIGURE_ARGS+= \
	--without-webdav-locks \
	--without-webdav-props
endif

define Build/Configure
(cd $(PKG_BUILD_DIR)/files && \
./https_cert.sh)
$(call Build/Configure/Default)
	# XXX: override pcre (mis)detection by ./configure when cross-compiling
	echo "#define HAVE_LIBPCRE 1" >>$(PKG_BUILD_DIR)/config.h
	echo "#define HAVE_PCRE_H 1" >>$(PKG_BUILD_DIR)/config.h
endef

define Package/lighttpd_dni/conffiles
/etc/lighttpd/lighttpd.conf
endef

define Package/lighttpd_dni/install
	$(INSTALL_DIR) $(1)/etc/lighttpd
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lighttpd.conf $(1)/etc/lighttpd/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lighttpd_satellite.conf $(1)/etc/lighttpd/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/doc/config/conf.d/mime.conf $(1)/etc/lighttpd/
	$(INSTALL_DIR) $(1)/etc/lighttpd/conf.d
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lighttpd.init $(1)/etc/init.d/lighttpd
	$(INSTALL_DIR) $(1)/usr/lib/lighttpd
	for m in dirlisting indexfile staticfile openssl setenv; do \
		$(CP) $(PKG_INSTALL_DIR)/usr/lib/lighttpd/mod_$$$${m}.so $(1)/usr/lib/lighttpd/ ; \
	done
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/lighttpd $(1)/usr/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

define BuildPlugin
  define Package/lighttpd_dni-mod-$(1)
    $(call Package/lighttpd_dni/Default)
    DEPENDS:=lighttpd_dni
    ifneq ($(3),)
      DEPENDS+= $(3)
    endif
    TITLE:=$(2) module
  endef

  define Package/lighttpd_dni-mod-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/lib/lighttpd
	$(CP) $(PKG_BUILD_DIR)/files/conf.d/* $(PKG_BUILD_DIR)/doc/config/conf.d/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/lighttpd/mod_$(1).so $$(1)/usr/lib/lighttpd
	$(INSTALL_DIR) $$(1)/etc/lighttpd/conf.d
	if [ -f $(PKG_BUILD_DIR)/doc/config/conf.d/$(1).conf ]; then \
		$(CP) $(PKG_BUILD_DIR)/doc/config/conf.d/$(1).conf $$(1)/etc/lighttpd/conf.d/$(4)-$(1).conf ; \
	else \
		echo 'server.modules += ( "mod_$(1)" )' > $$(1)/etc/lighttpd/conf.d/$(4)-$(1).conf ; \
	fi
	$(INSTALL_DIR) $$(1)/etc/lighttpd/certs
	$(CP) ./files/https_cert.sh $$(1)/etc/lighttpd/certs/https_cert.sh
	$(CP) ./files/crtconfig.conf $$(1)/etc/lighttpd/certs/crtconfig.conf
	$(CP) $(PKG_BUILD_DIR)/files/server.pem $$(1)/etc/lighttpd/certs/server.pem
	$(CP) ./files/routerlogin.pem $$(1)/etc/lighttpd/certs/routerlogin.pem
	$(CP) ./files/dhparam.pem $$(1)/etc/lighttpd/certs/dhparam.pem
  endef

  $$(eval $$(call BuildPackage,lighttpd_dni-mod-$(1)))
endef

$(eval $(call BuildPackage,lighttpd_dni))

# First, permit redirect from HTTP to HTTPS.
$(eval $(call BuildPlugin,redirect,URL redirection,+PACKAGE_lighttpd_dni-mod-redirect:libpcre,10))

# Next, permit authentication.
$(eval $(call BuildPlugin,auth,Authentication,,20))

# Finally, everything else.
$(eval $(call BuildPlugin,access,Access restrictions,,30))
$(eval $(call BuildPlugin,accesslog,Access logging,,30))
$(eval $(call BuildPlugin,alias,Directory alias,,30))
$(eval $(call BuildPlugin,cgi,CGI,,30))
$(eval $(call BuildPlugin,cml,Cache Meta Language,+liblua,30))
$(eval $(call BuildPlugin,compress,Compress output,+PACKAGE_lighttpd_dni-mod-compress:zlib,30))
$(eval $(call BuildPlugin,evasive,Evasive,,30))
$(eval $(call BuildPlugin,evhost,Exnhanced Virtual-Hosting,,30))
$(eval $(call BuildPlugin,expire,Expire,,30))
$(eval $(call BuildPlugin,fastcgi,FastCGI,,30))
$(eval $(call BuildPlugin,flv_streaming,FLV streaming,,30))
$(eval $(call BuildPlugin,magnet,Magnet,+liblua,30))
$(eval $(call BuildPlugin,mysql_vhost,Mysql virtual hosting,+PACKAGE_lighttpd_dni-mod-mysql_vhost:libmysqlclient,30))
$(eval $(call BuildPlugin,proxy,Proxy,,30))
$(eval $(call BuildPlugin,rewrite,URL rewriting,+PACKAGE_lighttpd_dni-mod-rewrite:libpcre,30))
$(eval $(call BuildPlugin,rrdtool,RRDtool,,30))
$(eval $(call BuildPlugin,scgi,SCGI,,30))
$(eval $(call BuildPlugin,secdownload,Secure and fast download,,30))
$(eval $(call BuildPlugin,setenv,Environment variable setting,,30))
$(eval $(call BuildPlugin,simple_vhost,Simple virtual hosting,,30))
$(eval $(call BuildPlugin,ssi,SSI,+libpcre,30))
$(eval $(call BuildPlugin,status,Server status display,,30))
$(eval $(call BuildPlugin,trigger_b4_dl,Trigger before download,+PACKAGE_lighttpd_dni-mod-trigger_b4_dl:libpcre,30))
$(eval $(call BuildPlugin,userdir,User directory,,30))
$(eval $(call BuildPlugin,usertrack,User tracking,,30))
$(eval $(call BuildPlugin,webdav,WebDAV,+PACKAGE_lighttpd_dni-mod-webdav:libsqlite3 +PACKAGE_lighttpd_dni-mod-webdav:libuuid +PACKAGE_lighttpd_dni-mod-webdav:libxml2,30))
