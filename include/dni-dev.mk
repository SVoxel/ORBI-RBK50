# Copyright (c) 2013 The Linux Foundation. All rights reserved.
# allow for local directory containing source to be used

LOCAL_PKG_NAME_EXT ?= $(PKG_NAME)
LOCAL_DNI_EXT_PATH ?= $(DNI_HOME)/package/$(LOCAL_PKG_NAME_EXT)
LOCAL_DNI_PATCH_EXT ?= $(LOCAL_DNI_EXT_PATH)/patches

ifeq (exists, $(shell [ -d $(LOCAL_DNI_PATCH_EXT) ] && echo exists))
DNI_PATCH_DIR:=$(LOCAL_DNI_PATCH_EXT)
endif

LOCAL_DNI_MAKEFILE_EXT ?= $(LOCAL_DNI_EXT_PATH)/Makefile.dni
LOCAL_DNI_FILES_EXT ?= $(LOCAL_DNI_EXT_PATH)/files

define Dni_Install_Ext
	$(call Package/$(1)/install_dniext,$(2),$(3))
endef

define Dni_Prepare_Ext
	$(call Package/$(1)/prepare_dniext)
endef

define Package/$(LOCAL_PKG_NAME_EXT)/install_dniext
endef

define Package/$(LOCAL_PKG_NAME_EXT)/prepare_dniext
endef

ifeq (exists, $(shell [ -f $(LOCAL_DNI_MAKEFILE_EXT) ] && echo exists))
include $(LOCAL_DNI_MAKEFILE_EXT)
endif

