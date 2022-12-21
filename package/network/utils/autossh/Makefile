#
# Copyright (C) 2006-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=autossh
PKG_VERSION:=1.4g
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tgz
PKG_SOURCE_URL:=https://www.harding.motd.ca/autossh/
PKG_MD5SUM:=5d38405b8380e3e470819b390fee0236
PKG_LICENSE:=0BSD

include $(INCLUDE_DIR)/package.mk

define Package/autossh
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Autossh client
  URL:=https://www.harding.motd.ca/autossh/
  MAINTAINER:=Christian Beier <cb@shoutrlabs.com>
  SUBMENU:=SSH
endef

CONFIGURE_VARS += \
	ac_cv_path_ssh=/usr/bin/ssh

define Package/autossh/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/autossh $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,autossh))
