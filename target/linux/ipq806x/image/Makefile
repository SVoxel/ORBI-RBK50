# Copyright (c) 2014 The Linux Foundation. All rights reserved.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

UBIFS_OPTS = -m 2048 -e 124KiB -c 4096 -U -F
UBI_OPTS = -m 2048 -p 128KiB

E2SIZE=$(shell echo $$(($(CONFIG_TARGET_ROOTFS_PARTSIZE)*1024)))

ifeq ($(strip $(call CompareKernelPatchVer,$(KERNEL_PATCHVER),eq,3.18)),1)
IPQ806X_KERNEL_LOADADDR = 0x42008000
IPQ40XX_KERNEL_LOADADDR = 0x80008000
else
IPQ806X_KERNEL_LOADADDR = 0x42208000
IPQ40XX_KERNEL_LOADADDR = 0x80208000
endif
IPQ807X_KERNEL_LOADADDR = 0x41208000

ifeq ($(OPENWRT_BUILD_TYPE),DNI_BUILD)
MODULE_NAME=$(CONFIG_DGC_MODULE_NAME)
MODULE_NAME_CC=$(CONFIG_DGC_MODULE_NAME_CC)
HW_VERSION=$(CONFIG_DGC_HW_VERSION)
FW_VERSION=$(CONFIG_DGC_FW_VERSION)
LG_VERSION=$(CONFIG_DGC_LG_VERSION)
CLOUD_VERSION=$(CONFIG_DGC_CLOUD_VERSION)
HW_ID=$(CONFIG_DGC_HW_ID)
HW_ID_CC=$(CONFIG_DGC_HW_ID_CC)
ifeq ($(HW_ID_CC),"")
HW_ID_CC:=$(HW_ID)
endif
ifndef FW_REGION
	FW_REGION=$(CONFIG_DGC_FW_REGION)
endif

FLASH_TYPE_VAR:=EMMC
ifdef CONFIG_DGC_FLASH_TYPE_EMMC
FLASH_TYPE_VAR:=EMMC
endif

ifdef CONFIG_DGC_FLASH_TYPE_NOR
FLASH_TYPE_VAR:=NOR_FLASH
 endif
 
ifdef CONFIG_DGC_FLASH_TYPE_NAND
FLASH_TYPE_VAR:=NAND_FLASH
endif

# 8M
#KERNEL_SIZE=3407872
KERNEL_SIZE=$(CONFIG_DGC_FW_KERNEL_SIZE)
KERNEL_SIZE_CC=$(CONFIG_DGC_FW_KERNEL_SIZE_CC)
# 10.875M
ROOTFS_SIZE=$(CONFIG_DGC_FW_ROOTFS_SIZE)
ROOTFS_SIZE_CC=$(CONFIG_DGC_FW_ROOTFS_SIZE_CC)

ifeq ($(KERNEL_SIZE_CC),"")
KERNEL_SIZE_CC=$(CONFIG_DGC_FW_KERNEL_SIZE)
endif
ifeq ($(ROOTFS_SIZE_CC),"")
ROOTFS_SIZE_CC=$(CONFIG_DGC_FW_ROOTFS_SIZE)
endif
endif

ifeq ($(OPENWRT_BUILD_TYPE),DNI_BUILD)
define Image/Prepare
	echo "$(MODULE_NAME)" > $(TARGET_DIR)/module_name
	echo "$(HW_VERSION)" > $(TARGET_DIR)/hardware_version
	echo "V$(FW_VERSION)" > $(TARGET_DIR)/firmware_version
	echo "$(CLOUD_VERSION)" > $(TARGET_DIR)/cloud_version
	echo "$(FLASH_TYPE_VAR)" > $(TARGET_DIR)/flash_type
	echo "$(FW_REGION)" > $(TARGET_DIR)/firmware_region
	echo "$(LG_VERSION)" > $(TARGET_DIR)/firmware_language_version
	echo $(HW_ID) > $(TARGET_DIR)/hw_id
	date > $(TARGET_DIR)/firmware_time
	echo "1" > $(TARGET_DIR)/etc/init.d/.hidden_new_features
endef
else
define Image/Prepare
	$(CP) $(LINUX_DIR)/vmlinux $(KDIR)/$(IMG_PREFIX)-vmlinux.elf
endef
endif

ifneq ($(CONFIG_TARGET_ROOTFS_UBIFS),)
define Image/mkfs/ubifs_fit
	$(call Image/ubifs_128MB,$(1))
	$(call Image/ubifs_512MB,$(1))
	$(call Image/UbiImage,$(1))
endef
endif

define Image/BuildKernel/FIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image.gz, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb,gzip,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
	$(CP) $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb $(BIN_DIR)/$(IMG_PREFIX)-$(1).dtb
	mkdir -p $(BIN_DIR)/dtbs/
	$(CP) $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq80*.dtb $(BIN_DIR)/dtbs/
	$(CP) $(KDIR)/Image $(BIN_DIR)/dtbs/
endef

define Image/BuildKernel/FITInitramfs
	$(CP) $(KDIR)/Image-initramfs $(BIN_DIR)/dtbs/
	$(CP) $(KDIR)/Image-initramfs $(BIN_DIR)/$(IMG_PREFIX)-vmlinux-initramfs.bin
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image-initramfs, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb, none,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage-initramfs.itb
endef

define Image/BuildKernel/GenericFIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image.gz,,gzip,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
endef

define Image/BuildKernel/MultiDTBFIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
	$(call Image/BuildKernel/MkFITMulti,$(1),$(KDIR)/Image.gz,$(2),gzip,$(3),$(3))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
endef

# some tree's don't have all the device tree's so we filter out
# the ones that are not present
# $(1) is the filter to apply
FindDeviceTrees ?= $(notdir $(basename $(shell find $(LINUX_DIR)/arch/arm/boot/dts/ -name $(1)*.dts $(2) 2>/dev/null)))

define Image/BuildKernel/template
	$(CP) $(KDIR)/vmlinux$(subst openwrt-ipq806x,,$(IMG_PREFIX)).debug $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.elf

	$(foreach device, $(call FindDeviceTrees, qcom-ipq8064-), \
		$(call Image/BuildKernel/$(1),$(device),$(IPQ806X_KERNEL_LOADADDR));)

	$(foreach device, $(call FindDeviceTrees, qcom-ipq40??-), \
		$(call Image/BuildKernel/$(1),$(device),$(IPQ40XX_KERNEL_LOADADDR));)

	$(foreach device, $(call FindDeviceTrees, qcom-ipq807x-), \
		$(call Image/BuildKernel/$(1),$(device),$(IPQ807X_KERNEL_LOADADDR));)
endef

ifeq ($(OPENWRT_BUILD_TYPE),DNI_BUILD)
define Image/BuildKernel
	$(CP) $(KDIR)/vmlinux$(subst openwrt-ipq806x,,$(IMG_PREFIX)).debug $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.elf
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq40xx-ap.dkxx,"$(CONFIG_DGC_DTS_BASE1) \
			$(CONFIG_DGC_DTS_BASE2) \
			$(CONFIG_DGC_DTS_BASE3) \
			$(CONFIG_DGC_DTS_BASE4) \
			$(CONFIG_DGC_DTS_BASE5) \
			$(CONFIG_DGC_DTS_BASE6) \
			$(CONFIG_DGC_DTS_BASE7) \
			$(CONFIG_DGC_DTS_BASE8) \
			$(CONFIG_DGC_DTS_BASE9)"\
			,0x80208000)
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq40xx-ap.dkxx_cc,"$(CONFIG_DGC_DTS_SATELLITE1) \
			$(CONFIG_DGC_DTS_SATELLITE2) \
			$(CONFIG_DGC_DTS_SATELLITE3) \
			$(CONFIG_DGC_DTS_SATELLITE4) \
			$(CONFIG_DGC_DTS_SATELLITE5) \
			$(CONFIG_DGC_DTS_SATELLITE6) \
			$(CONFIG_DGC_DTS_SATELLITE7) \
			$(CONFIG_DGC_DTS_SATELLITE8) \
			$(CONFIG_DGC_DTS_SATELLITE9)"\
			,0x80208000)
endef
else
define Image/BuildKernel
	$(call Image/BuildKernel/template,FIT)

	$(call Image/BuildKernel/GenericFIT,qcom-ipq40xx,$(IPQ40XX_KERNEL_LOADADDR))
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq40xx-ap.dkxx, \
		$(call FindDeviceTrees, qcom-ipq40??-ap) $(call FindDeviceTrees, qcom-ipq40??-db), \
		$(IPQ40XX_KERNEL_LOADADDR))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap148_1xx.dtb), \
		$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap148_1xx, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap148_1xx), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap148.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap148, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap148,-not -name *ap148_1xx* -not -name *ap148-nand*), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-db149.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-db149, \
		$(call FindDeviceTrees, qcom-ipq8064-*db149), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ak01.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ak01, \
		$(call FindDeviceTrees, qcom-ipq8064-*ak01), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap145_1xx.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap145_1xx, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap145_1xx), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap145.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap145, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap145,-not -name *ap145_1xx*), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap160_2xx.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap160_2xx, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap160_2xx), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap160.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap160, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap160,-not -name *ap160_2xx*), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap161.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap161, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap161), \
		$(IPQ806X_KERNEL_LOADADDR)))
endef
endif

define Image/BuildKernel/Initramfs
	$(CP) $(KDIR)/vmlinux-initramfs$(subst openwrt-ipq806x,,$(IMG_PREFIX)).debug $(BIN_DIR)/$(IMG_PREFIX)-vmlinux-initramfs.elf
	$(call Image/BuildKernel/template,FITInitramfs)
endef

UBI_IMAGES=qcom-ipq8064-db149 \
	qcom-ipq8064-ap148 \
	qcom-ipq8064-ak01 \
	qcom-ipq8064-ap145_1xx \
	qcom-ipq8064-ap145 \
	qcom-ipq8064-ap160 \
	qcom-ipq8064-ap161 \
	qcom-ipq8064-ap160_2xx

define Image/UbiPrepare
	$(if $(wildcard $(DTS_DIR)/$(1).dtb), \
	$(call Image/Build/UbinizeImage,$(1),$(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb,$(2),$(3),$(4));)
endef

define Image/UbiImage

ifeq ($(1),-ipq806x)
	$(eval UBI_OPTS:="-m 2048 -p 128KiB")
	$(foreach image,$(UBI_IMAGES), \
	$(call Image/UbiPrepare,$(image),squashfs,"ubi_rootfs","rootfs_data"))
endif
endef

define Image/ubifs_512MB

  ifeq ($(1),-ipq40xx)
	$(eval UBI_OPTS:="-m 4096 -p 256KiB")
	$(call Image/mkfs/ubifs/generate,$(1))
	$(call Image/Build,ubi,$(1),-512MB)
  endif
endef

define Image/ubifs_128MB
	$(eval UBI_OPTS:="-m 2048 -p 128KiB")
	$(call Image/mkfs/ubifs/generate,$(1))
	$(call Image/Build,ubi,$(1))
endef

ifeq ($(OPENWRT_BUILD_TYPE),DNI_BUILD)
define Image/Build/squashfs
	$(call prepare_generic_squashfs,$(KDIR)/root.squashfs)
	$(call prepare_generic_squashfs,$(KDIR)/root_cc.squashfs)
endef
else
define Image/Build/squashfs
	$(call prepare_generic_squashfs,$(KDIR)/root.squashfs)
endef
endif

DAKOTA_CHIPCODE_GIT_REPO:=$(GIT_HOME)/qsdk-chipcode.git
DAKOTA_CHIPCODE_TREEISH := 206f34d6ca9d3621d28528c60dac0c265cc06ad3
DAKOTA_SINGLE_IMG_OUTPUT_DIR := $(BIN_DIR)/dakota-single-imgs/

#
# According to include/image.mk and this Makefile, ubifs should be the last
# built rootfs image. Thus, build single image after ubifs rootfs image is
# ready.
#
define Image/BuildSingleImg/ubifs
	### Generating single images for Dakota reference board
	$(INSTALL_DIR) "$(DAKOTA_SINGLE_IMG_OUTPUT_DIR)"
	"$(TOPDIR)/scripts/gen-single-img.sh" --force-remove \
		--git-repo "$(DAKOTA_CHIPCODE_GIT_REPO)" \
		--treeish $(DAKOTA_CHIPCODE_TREEISH) \
		-w "$(BUILD_DIR_HOST)/qsdk-chipcode-$(DAKOTA_CHIPCODE_TREEISH)" \
		-o "$(DAKOTA_SINGLE_IMG_OUTPUT_DIR)"/ \
		"$(BIN_DIR)"/openwrt*
endef

ifeq ($(OPENWRT_BUILD_TYPE),DNI_BUILD)
KERNEL_IMG:=$(IMG_PREFIX)-qcom-ipq40xx-ap.dkxx-fit-uImage.itb
KERNEL_IMG_CC:=$(IMG_PREFIX)-qcom-ipq40xx-ap.dkxx_cc-fit-uImage.itb
ROOTFS_IMG:=$(IMG_PREFIX)-squashfs-root.img
ROOTFS_IMG_CC:=$(IMG_PREFIX)-squashfs-root_cc.img
ONE_IMAGE:=$(BIN_DIR)/oneimage.img
ONE_IMAGE_CC:=$(BIN_DIR)/oneimage_cc.img
DNI_IMAGE:=$(BIN_DIR)/$(MODULE_NAME)-V$(FW_VERSION)$(FW_REGION).img
DNI_IMAGE_CC:=$(BIN_DIR)/$(MODULE_NAME_CC)-V$(FW_VERSION)$(FW_REGION).img
ONE_IMAGE_FINAL:=$(BIN_DIR)/oneimage.img.final
ONE_IMAGE_FINAL_CC:=$(BIN_DIR)/oneimage_cc.img.final

define Image/Build/Orbi
	$(SCRIPT_DIR)/scan-module.sh "$(TOPDIR)"
	echo "Generating $(2) Firmware"
	test `cat $(BIN_DIR)/$(KERNEL_IMG) |wc -c` -le $(KERNEL_SIZE)
	test `cat $(BIN_DIR)/$(ROOTFS_IMG) |wc -c` -le $(ROOTFS_SIZE)
	rm -f $(ONE_IMAGE)
	(\
		dd if=$(BIN_DIR)/$(KERNEL_IMG) bs=$(KERNEL_SIZE) conv=sync; \
		dd if=$(BIN_DIR)/$(ROOTFS_IMG) bs=64k; \
	) > $(ONE_IMAGE)
	$(STAGING_DIR_HOST)/bin/orbi $(BIN_DIR)/$(KERNEL_IMG) $(BIN_DIR)/$(KERNEL_IMG).normal
	dd if=$(BIN_DIR)/$(KERNEL_IMG) bs=$(shell expr $(KERNEL_SIZE) - 64) conv=sync of=$(BIN_DIR)/$(KERNEL_IMG).final
	$(call Image/BuildKernel/MkuImage,lzma,0x40908000,0x40908000,$(BIN_DIR)/$(ROOTFS_IMG),$(BIN_DIR)/$(ROOTFS_IMG).uImage)
	$(STAGING_DIR_HOST)/bin/orbi $(BIN_DIR)/$(ROOTFS_IMG).uImage $(BIN_DIR)/$(ROOTFS_IMG).tmp
	dd if=$(BIN_DIR)/$(ROOTFS_IMG).tmp bs=64 count=1 >> $(BIN_DIR)/$(KERNEL_IMG).final
	(\
		dd if=$(BIN_DIR)/$(KERNEL_IMG).final bs=$(KERNEL_SIZE) conv=sync; \
		dd if=$(BIN_DIR)/$(ROOTFS_IMG) bs=64k; \
	) > $(ONE_IMAGE_FINAL)
	$(STAGING_DIR_HOST)/bin/mkdniimg \
		-B $(MODULE_NAME) -v $(FW_VERSION) -r $(FW_REGION) -H $(HW_ID) \
		-i $(ONE_IMAGE_FINAL) \
		-o $(DNI_IMAGE)

	echo "Generating $(2) Satellite Firmware"
	test `cat $(BIN_DIR)/$(KERNEL_IMG_CC) |wc -c` -le $(KERNEL_SIZE_CC)
	test `cat $(BIN_DIR)/$(ROOTFS_IMG_CC) |wc -c` -le $(ROOTFS_SIZE_CC)
	rm -f $(ONE_IMAGE_CC)
	(\
		dd if=$(BIN_DIR)/$(KERNEL_IMG_CC) bs=$(KERNEL_SIZE_CC) conv=sync; \
		dd if=$(BIN_DIR)/$(ROOTFS_IMG_CC) bs=64k; \
	) > $(ONE_IMAGE_CC)
	$(STAGING_DIR_HOST)/bin/orbi $(BIN_DIR)/$(KERNEL_IMG_CC) $(BIN_DIR)/$(KERNEL_IMG_CC).normal
	dd if=$(BIN_DIR)/$(KERNEL_IMG_CC) bs=$(shell expr $(KERNEL_SIZE_CC) - 64) conv=sync of=$(BIN_DIR)/$(KERNEL_IMG_CC).final
	$(call Image/BuildKernel/MkuImage,lzma,0x40908000,0x40908000,$(BIN_DIR)/$(ROOTFS_IMG_CC),$(BIN_DIR)/$(ROOTFS_IMG_CC).uImage)
	$(STAGING_DIR_HOST)/bin/orbi $(BIN_DIR)/$(ROOTFS_IMG_CC).uImage $(BIN_DIR)/$(ROOTFS_IMG_CC).tmp
	dd if=$(BIN_DIR)/$(ROOTFS_IMG_CC).tmp bs=64 count=1 >> $(BIN_DIR)/$(KERNEL_IMG_CC).final
	(\
		dd if=$(BIN_DIR)/$(KERNEL_IMG_CC).final bs=$(KERNEL_SIZE_CC) conv=sync; \
		dd if=$(BIN_DIR)/$(ROOTFS_IMG_CC) bs=64k; \
	) > $(ONE_IMAGE_FINAL_CC)
	$(STAGING_DIR_HOST)/bin/mkdniimg \
		-B $(MODULE_NAME_CC) -v $(FW_VERSION) -r $(FW_REGION) -H $(HW_ID_CC) \
		-i $(ONE_IMAGE_FINAL_CC) \
		-o $(DNI_IMAGE_CC)
endef
endif

ifeq ($(OPENWRT_BUILD_TYPE),DNI_BUILD)
define Image/Build
	$(call Image/Build/$(1),$(1))
	dd if=$(KDIR)/root$(2).$(1) of=$(BIN_DIR)/$(IMG_PREFIX)$(2)-$(1)-root$(3).img bs=2k conv=sync
	dd if=$(KDIR)/root$(2)_cc.$(1) of=$(BIN_DIR)/$(IMG_PREFIX)$(2)-$(1)-root_cc.img bs=128k conv=sync
	$(call Image/Build/Orbi,$(1),orbi)
endef
else
define Image/Build
	$(call Image/Build/$(1),$(1))
	dd if=$(KDIR)/root$(2).$(1) of=$(BIN_DIR)/$(IMG_PREFIX)$(2)-$(1)-root$(3).img bs=2k conv=sync
	$(call Image/BuildSingleImg/$(1))
endef
endif

$(eval $(call BuildImage))
