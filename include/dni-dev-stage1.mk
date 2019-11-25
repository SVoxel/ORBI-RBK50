# Copyright (c) 2013 The Linux Foundation. All rights reserved.
# allow for local directory containing source to be used

LOCAL_PKG_NAME_EXT ?= $(PKG_NAME)
LOCAL_DNI_MAKEFILE_EXT_STAGE1 ?= $(DNI_HOME)/package/$(LOCAL_PKG_NAME_EXT)/Makefile_stage1.dni

ifeq (exists, $(shell [ -f $(LOCAL_DNI_MAKEFILE_EXT_STAGE1) ] && echo exists))
include $(LOCAL_DNI_MAKEFILE_EXT_STAGE1)
endif

