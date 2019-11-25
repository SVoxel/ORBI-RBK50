include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-dnirtsp
PKG_RELEASE:=1
NF=nf
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)

CONFIG_DNIRTSP_GIT_TREEISH="alg-rtsp-v3.4-dni1"
CONFIG_DNIRTSP_GIT_REPOSITORY="kmod-dnirtsp.git"
CONFIG_DNIRTSP_GIT_URL="ssh://dniserver/scm/dnigit/common/kmods/kmod-dnirtsp.git"

LOCAL_PKG_NAME_EXT:=kmod-dnirtsp

include $(INCLUDE_DIR)/package.mk

define KernelPackage/dnirtsp
  SUBMENU:=DNI Kernel Module
  TITLE:=DNI RTSP ALG
  VERSION:=$(LINUX_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= \
	$(PKG_BUILD_DIR)/$(NF)_conntrack_dnirtsp.$(LINUX_KMOD_SUFFIX) \
	$(PKG_BUILD_DIR)/$(NF)_nat_dnirtsp.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoLoad,46,$(NF)_conntrack_dnirtsp $(NF)_nat_dnirtsp)
endef

define Build/Prepare
	$(CP) $(GIT_HOME)/kmod-dnirtsp.git/* $(PKG_BUILD_DIR)/
	$(call Dni_Prepare_Ext,$(LOCAL_PKG_NAME_EXT))
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		SUBDIRS="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(BUILDFLAGS)" \
		modules
endef

$(eval $(call KernelPackage,dnirtsp))
