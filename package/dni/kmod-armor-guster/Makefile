include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-armor-guster
PKG_VERSION:=
PKG_RELEASE:=

PKG_SOURCE:=
PKG_SOURCE_URL:=
PKG_MD5SUM:=
PKG_CAT:=zcat

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/kmod-armor-guster

LOCAL_PKG_NAME_EXT:=kmod-armor-guster

include $(INCLUDE_DIR)/package.mk

ifeq ($(CONFIG_DGC_FUNC_HAVE_ARMOR),y)
	BD_GUSTER:=$(PKG_BUILD_DIR)/files/guster.ko
endif

define KernelPackage/armor-guster
  SUBMENU:=Other modules
  DEPENDS:=@TARGET_ipq806x 
  TITLE:=Armor-guster
  VERSION:=$(LINUX_VERSION)+$(PKG_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:=$(BD_GUSTER)
endef

define Build/Prepare
	mkdir -p  $(PKG_BUILD_DIR)/files
	cp -f ./files/guster.ko $(PKG_BUILD_DIR)/files/
	$(call Build/Patch/Default)
	$(if $(PLATFORM_PATCH_DIR), $(call PatchDir,$(PKG_BUILD_DIR),$(PLATFORM_PATCH_DIR),))
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Build/Compile
endef

define Build/InstallDev
endef

define Build/UninstallDev
endef

define KernelPackage/armor-guster/install
	$(INSTALL_DIR) $(1)/lib/modules/3.14.77/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/guster.ko $(1)/lib/modules/3.14.77/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call KernelPackage,armor-guster))
