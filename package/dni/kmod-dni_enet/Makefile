include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-dni_enet
PKG_VERSION:=
PKG_RELEASE:=

PKG_SOURCE:=
PKG_SOURCE_URL:=
PKG_MD5SUM:=
#PKG_SOURCE_PROTO:=git
#PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/oss/lklm/nss-gmac
#PKG_BRANCH:=master
#PKG_RELEASE:=1
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/kmod-dni_enet

#ifeq ($(DUMP)$(PKG_VERSION),)
#  PKG_VERSION:=$(shell git ls-remote $(PKG_SOURCE_URL) $(PKG_BRANCH) | cut -b -7)
#endif
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
#PKG_SOURCE_VERSION:=$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

#ENET_AUTOLOAD:= dni_enet 

define KernelPackage/dni_enet
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  DEPENDS:=@TARGET_ipq806x
  TITLE:=Kernel driver for NSS gmac
  FILES:=$(PKG_BUILD_DIR)/dni_enet.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,90,dni_enet)
endef

define KernelPackage/kmod-dni_enet/Description
This package contains a NSS driver for QCA chipset
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef
define Build/InstallDev
endef

define Build/UninstallDev
endef

define KernelPackage/dni_enet/install
endef

$(eval $(call KernelPackage,dni_enet))
