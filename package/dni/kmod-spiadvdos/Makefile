#
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-spiadvdos
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)

CONFIG_SPIADVDOS_GIT_TREEISH="905edab902dfabc9a4317ddd23b800017a62a43b"
CONFIG_SPIADVDOS_GIT_REPOSITORY="kmod-spiadvdos.git"
CONFIG_SPIADVDOS_GIT_URL="ssh://dniserver/scm/dnigit/common/kmods/kmod-spiadvdos.git"

LOCAL_PKG_NAME_EXT:=kmod-spiadvdos

include $(INCLUDE_DIR)/package.mk

define KernelPackage/spiadvdos
  SUBMENU:=Other modules
  TITLE:=DNI Advanced SPI DOS firewall module
  VERSION:=$(LINUX_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= \
	$(PKG_BUILD_DIR)/ipt_spiadvDoS.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,46,ipt_spiadvDoS)
endef


define Build/Prepare
	$(CP) $(GIT_HOME)/kmod-spiadvdos.git/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define KernelPackage/spiadvdos/install
	$(INSTALL_DIR) $(1)/lib/network/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call KernelPackage,spiadvdos))
