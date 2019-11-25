include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=dni-mtdoops
PKG_VERSION:=
PKG_RELEASE:=

PKG_SOURCE:=
PKG_MD5SUM:=
PKG_CAT:=zcat

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=dni-mtdoops

include $(INCLUDE_DIR)/package.mk

define KernelPackage/dni-mtdoops
  SUBMENU:=
  TITLE:= MTD Oops/Panic console logger/driver
  URL:=http://www.deltaww.com/
  DEPENDS:= +libgcc +libc
  VERSION:=$(LINUX_VERSION)+$(PKG_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= \
	$(PKG_BUILD_DIR)/mtdoops.$(LINUX_KMOD_SUFFIX)
endef

ENET_MAKEOPTS= \
                ENETDIR="$(PKG_BUILD_DIR)" \
                PATH="$(KERNEL_STAGING_DIR)/bin:$(TARGET_PATH)" \
                ARCH="$(LINUX_KARCH)" \
                CROSS_COMPILE="$(TARGET_CROSS)" \
                TOOLPREFIX="arm-linux-" \
                TOOLPATH="arm-linux-"

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(LINUX_DIR) KERNELPATH="$(LINUX_DIR)" SUBDIRS=$(PKG_BUILD_DIR) MODVERDIR=$(PKG_BUILD_DIR)/modules modules $(ENET_MAKEOPTS)
	$(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR)/tools $(MAKE_FLAGS)
endef

define Build/InstallDev
endef

define Build/UninstallDev
endef

define KernelPackage/dni-mtdoops/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/debug_save_panic_log $(1)/sbin/
	$(INSTALL_BIN) ./files/*.sh $(1)/sbin/
	$(INSTALL_BIN) ./files/dni-debug.init $(1)/etc/init.d
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call KernelPackage,dni-mtdoops))
