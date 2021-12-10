#
# Copyright (C) 2014 2015 The Linux Foundation. All rights reserved.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=coccinelle
PKG_VERSION:=1.0.8

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/coccinelle/coccinelle/archive/
PKG_MD5SUM:=d58871107c28a970fc53e4f8124d14e1

HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/coccinelle-$(PKG_VERSION)

HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk

HOST_CONFIGURE_ARGS += --with-pdflatex=no --disable-pcre-syntax

define Host/Configure
	(cd $(HOST_BUILD_DIR); \
		aclocal && autoconf && \
		autoheader && \
		automake --add-missing; \
	)
	$(Host/Configure/Default)
endef


$(eval $(call HostBuild))
