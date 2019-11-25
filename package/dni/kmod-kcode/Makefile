include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-kcode
PKG_VERSION:=
PKG_RELEASE:=

PKG_SOURCE:=
PKG_MD5SUM:=
PKG_CAT:=zcat

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/kmod-kcode

NetUSB_AUTOLOAD:= \
		GPL_NetUSB \
		NetUSB

LOCAL_PKG_NAME_EXT:=kmod-kcode

include $(INCLUDE_DIR)/package.mk

define KernelPackage/kcode
  SUBMENU:=Other modules
  DEPENDS:=@TARGET_ipq806x +libc +libpthread
  TITLE:=KCode USB Printer
  VERSION:=$(LINUX_VERSION)+$(PKG_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= \
	$(PKG_BUILD_DIR)/NetUSB.$(LINUX_KMOD_SUFFIX) \
	$(PKG_BUILD_DIR)/GPL_NetUSB.$(LINUX_KMOD_SUFFIX)
# AUTOLOAD:=$(call AutoLoad,90,$(NetUSB_AUTOLOAD))
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

define KernelPackage/kcode/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/kcode.init $(1)/etc/init.d/kcode

	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/KC_BONJOUR $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/KC_PRINT $(1)/sbin/
	$(call Dni_Install_Ext,$(LOCAL_PKG_NAME_EXT),$(1))
endef

$(eval $(call KernelPackage,kcode))
