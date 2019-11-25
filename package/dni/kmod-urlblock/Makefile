#
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 6565 2007-03-14 13:42:21Z nbd $

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-urlblock
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)

CONFIG_URLBLOCK_GIT_TREEISH="478ad1642a2490909267b56bab4d2a0b10741ae3"
CONFIG_URLBLOCK_GIT_REPOSITORY="kmod-urlblock.git"
CONFIG_URLBLOCK_GIT_URL="ssh://dniserver/scm/dnigit/common/kmods/kmod-urlblock.git"

LOCAL_PKG_NAME_EXT:=kmod-urlblock

include $(INCLUDE_DIR)/package.mk

define KernelPackage/urlblock
  SUBMENU:=Other modules
  TITLE:=DNI URL Block firewall module
  VERSION:=$(LINUX_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= \
	$(PKG_BUILD_DIR)/ipt_urlBlock.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,46,ipt_urlBlock)
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/kmod-urlblock.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define KernelPackage/urlblock/install
	$(INSTALL_DIR) $(1)/lib/network/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call KernelPackage,urlblock))
