include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=atheros-gpio
PKG_VERSION:=
PKG_RELEASE:=

PKG_SOURCE:=
PKG_SOURCE_URL:=
PKG_MD5SUM:=
PKG_CAT:=zcat

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)

LOCAL_PKG_NAME_EXT:=atheros-gpio

include $(INCLUDE_DIR)/package.mk

define KernelPackage/atheros-gpio
  SUBMENU:=
  TITLE:=Driver for Atheros ar9344 GPIO
  URL:=http://www.atheros.com/
  VERSION:=$(LINUX_VERSION)+$(PKG_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= \
	$(PKG_BUILD_DIR)/atherosgpio.$(LINUX_KMOD_SUFFIX) \
	$(PKG_BUILD_DIR)/atherosgpio_nand.$(LINUX_KMOD_SUFFIX)
  #AUTOLOAD:=$(call AutoLoad,40,atherosgpio)
endef

define KernelPackage/atheros-gpio/config
  source "$(SOURCE)/Config.in"
endef

#For different product should change gpio number.

ifneq ($(CONFIG_GPIO_POWER_R),)
EXTRA_CFLAGS += -DPOWER_R=$(CONFIG_GPIO_POWER_R)
endif
ifneq ($(CONFIG_GPIO_POWER_G),)
EXTRA_CFLAGS += -DPOWER_G=$(CONFIG_GPIO_POWER_G)
endif
ifneq ($(CONFIG_GPIO_LED_R),)
EXTRA_CFLAGS += -DLED_R=$(CONFIG_GPIO_LED_R)
endif
ifneq ($(CONFIG_GPIO_LED_G),)
EXTRA_CFLAGS += -DLED_G=$(CONFIG_GPIO_LED_G)
endif
ifneq ($(CONFIG_GPIO_LED_B),)
EXTRA_CFLAGS += -DLED_B=$(CONFIG_GPIO_LED_B)
endif
ifneq ($(CONFIG_GPIO_LED_W),)
EXTRA_CFLAGS += -DLED_W=$(CONFIG_GPIO_LED_W)
endif
ifneq ($(CONFIG_GPIO_I2C_EN),)
EXTRA_CFLAGS += -DI2C_EN=$(CONFIG_GPIO_I2C_EN)
endif
ifneq ($(CONFIG_GPIO_I2C_RST),)
EXTRA_CFLAGS += -DI2C_RST=$(CONFIG_GPIO_I2C_RST)
endif
ifneq ($(CONFIG_GPIO_BTN_RST),)
EXTRA_CFLAGS += -DBTN_RST=$(CONFIG_GPIO_BTN_RST)
endif
ifneq ($(CONFIG_GPIO_WPS_BTN),)
EXTRA_CFLAGS += -DWPS_BTN=$(CONFIG_GPIO_WPS_BTN)
endif

ifeq ($(CONFIG_GPIO_HAVE_USB), y)
EXTRA_CFLAGS += -DHAVE_USB
ifneq ($(CONFIG_GPIO_USB_EN),)
EXTRA_CFLAGS += -DUSB_EN=$(CONFIG_GPIO_USB_EN)
endif
endif

ifeq ($(CONFIG_GPIO_HAVE_SENSOR), y)
EXTRA_CFLAGS += -DHAVE_SENSOR
endif

ifeq ($(CONFIG_GPIO_HAVE_TOP_LED), y)
EXTRA_CFLAGS += -DHAVE_TOP_LED
ifneq ($(CONFIG_GPIO_TOP_LED_EN),)
EXTRA_CFLAGS += -DTOP_LED_EN=$(CONFIG_GPIO_TOP_LED_EN)
endif
ifneq ($(CONFIG_GPIO_TOP_LED_RST),)
EXTRA_CFLAGS += -DTOP_LED_RST=$(CONFIG_GPIO_TOP_LED_RST)
endif
ifneq ($(CONFIG_GPIO_HW_LED_BTN),)
EXTRA_CFLAGS += -DHW_LED_BTN=$(CONFIG_GPIO_HW_LED_BTN)
endif
endif

ifeq ($(CONFIG_GPIO_HAVE_HEATER), y)
EXTRA_CFLAGS += -DHAVE_HEATER
ifneq ($(CONFIG_GPIO_HEATER_EN),)
EXTRA_CFLAGS += -DHEATER_EN=$(CONFIG_GPIO_HEATER_EN)
endif
endif

ENET_MAKEOPTS= \
                ENETDIR="$(PKG_BUILD_DIR)" \
                ARCH="$(LINUX_KARCH)" \
                CROSS_COMPILE="$(TARGET_CROSS)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
                PATH="$(KERNEL_STAGING_DIR)/bin:$(TARGET_PATH)" 
                #TOOLPREFIX="mips-linux-" \
                #TOOLPATH="mips-linux-"

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

define KernelPackage/atheros-gpio/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/init-gpio $(1)/etc/init.d
endef

$(eval $(call KernelPackage,atheros-gpio))
