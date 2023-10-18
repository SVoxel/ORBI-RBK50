 
# Copyright (C) 2009-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=ipt-ipset
PKG_SRC:=ipset
PKG_VERSION:=7.19
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_SRC)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=http://ipset.netfilter.org
PKG_MD5SUM:=34b92f93292e6114aede1a0f18a75251

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/$(PKG_SRC)-$(PKG_VERSION)

PKG_MAINTAINER:=Jo-Philipp Wich <jow@openwrt.org>

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk


CONFIGURE_ARGS += \
	--with-kbuild="$(LINUX_DIR)"

MAKE_FLAGS += \
	ARCH="$(LINUX_KARCH)" \

IPSET_MODULES:= \
	ipset/ip_set \
	ipset/ip_set_bitmap_ip \
	ipset/ip_set_bitmap_ipmac \
	ipset/ip_set_bitmap_port \
	ipset/ip_set_hash_ip \
	ipset/ip_set_hash_mac \
	ipset/ip_set_hash_ipport \
	ipset/ip_set_hash_ipportip \
	ipset/ip_set_hash_ipportnet \
	ipset/ip_set_hash_net \
	ipset/ip_set_hash_netiface \
	ipset/ip_set_hash_netport \
	ipset/ip_set_list_set \
	xt_set \


define KernelPackage/ipt-ipset
$(call Package/ipset/Default)
  SUBMENU:=Netfilter Extensions
  TITLE:=IPset netfilter modules
  DEPENDS+= +kmod-ipt-core +kmod-nfnetlink
  FILES:=$(foreach mod,$(IPSET_MODULES),$(PKG_BUILD_DIR)/kernel/net/netfilter/$(mod).ko)
  AUTOLOAD:=$(call AutoLoad,49,$(notdir $(IPSET_MODULES)))
endef

define Build/Compile
	$(call Build/Compile/Default,modules)
endef

$(eval $(call KernelPackage,ipt-ipset))
