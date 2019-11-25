/*
 * Copyright (c) 2012-2015 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef _IPQCDP_H
#define _IPQCDP_H

/*
 * Disabled for actual chip.
 * #define CONFIG_RUMI
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
/*
 * Beat the system! tools/scripts/make-asm-offsets uses
 * the following hard-coded define for both u-boot's
 * ASM offsets and platform specific ASM offsets :(
 */
#include <generated/generic-asm-offsets.h>
#ifdef __ASM_OFFSETS_H__
#undef __ASM_OFFSETS_H__
#endif
#if !defined(DO_SOC_DEPS_ONLY)
#include <generated/asm-offsets.h>
#endif
#endif /* !DO_DEPS_ONLY */

#define CONFIG_BOARD_EARLY_INIT_F

#define DNI_NAND
#define CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE
#define NETGEAR_BOARD_ID_SUPPORT

#define OPEN_SOURCE_ROUTER_SUPPORT
#define OPEN_SOURCE_ROUTER_ID  "NETGEAR"

#define FIRMWARE_RECOVER_FROM_TFTP_SERVER 1
#define CONFIG_SYS_SINGLE_FIRMWARE     1
#define CONFIG_SYS_NMRP                1
#define CHECK_DNI_FIRMWARE_INTEGRITY
#define CHECK_DNI_FIRMWARE_ROOTFS_INTEGRITY

#define CONFIG_SYS_FLASH_SECTOR_SIZE 0x20000

#ifdef FIRMWARE_RECOVER_FROM_TFTP_SERVER
#define CONFIG_SYS_IMAGE_LEN   0x2000000
#define CONFIG_SYS_IMAGE_BASE_ADDR  0x1480000
#define CONFIG_SYS_IMAGE_ADDR_BEGIN (CONFIG_SYS_IMAGE_BASE_ADDR)
#define CONFIG_SYS_IMAGE_ADDR_END   (CONFIG_SYS_IMAGE_BASE_ADDR + CONFIG_SYS_IMAGE_LEN)
#define CONFIG_SYS_FLASH_CONFIG_BASE  0x7d00000
#define CONFIG_SYS_FLASH_CONFIG_PARTITION_SIZE  0x180000
#define CONFIG_SYS_STRING_TABLE_LEN  0x40000  /* Each string table takes 256KB to save.  */
#define CONFIG_SYS_STRING_TABLE_NUMBER 10
#define CONFIG_SYS_STRING_TABLE_TOTAL_LEN  0x380000  /* Totally allocate 3584KB to save all string tables. */
#define CONFIG_SYS_STRING_TABLE_BASE_ADDR  0x7980000
#define CONFIG_SYS_STRING_TABLE_ADDR_BEGIN (CONFIG_SYS_STRING_TABLE_BASE_ADDR)
#define CONFIG_SYS_STRING_TABLE_ADDR_END   (CONFIG_SYS_STRING_TABLE_ADDR_BEGIN + CONFIG_SYS_STRING_TABLE_TOTAL_LEN)
#define CONFIG_RESERVED_LEN  0x4880000  /* blocked by "config" partition */
#endif

#define MTDIDS_DEFAULT    "nand0=msm_nand"

#define CONFIG_IPADDR 192.168.1.1
#define CONFIG_SERVERIP 192.168.1.10
#define CONFIG_LOADADDR 0x42000000

#define CONFIG_QCA_SINGLE_IMG

#define CONFIG_SYS_LONGHELP
#define CONFIG_SYS_NO_FLASH
#define CONFIG_SYS_CACHELINE_SIZE   64
#define CONFIG_IPQ806X_ENV

#define CONFIG_IPQ806X_USB
#ifdef CONFIG_IPQ806X_USB
#define CONFIG_USB_XHCI
#define CONFIG_CMD_USB
#define CONFIG_DOS_PARTITION
#define CONFIG_USB_STORAGE
#define CONFIG_SYS_USB_XHCI_MAX_ROOT_PORTS 2
#define CONFIG_USB_MAX_CONTROLLER_COUNT 2
#endif

#define CONFIG_IPQ806X_UART
#undef CONFIG_CMD_FLASH
#undef CONFIG_CMD_FPGA		        /* FPGA configuration support */
#undef CONFIG_CMD_IMI
#undef CONFIG_CMD_IMLS
#undef CONFIG_CMD_NFS		        /* NFS support */
#define CONFIG_CMD_NET		        /* network support */
#define CONFIG_CMD_DHCP
#undef CONFIG_SYS_MAX_FLASH_SECT
#define CONFIG_NR_DRAM_BANKS            1
#define CONFIG_SKIP_LOWLEVEL_INIT
#define CONFIG_CMD_PING
#define CONFIG_CMD_NMRP
#define CONFIG_CMD_DNI
#define CONFIG_CMD_MISC

#define CONFIG_BOARD_EARLY_INIT_F

#define CONFIG_HW_WATCHDOG

/* Environment */
#define CONFIG_MSM_PCOMM
#define CONFIG_ARCH_CPU_INIT

#define CONFIG_ENV_SIZE_MAX             (256 << 10) /* 256 KB */
#define CONFIG_SYS_MALLOC_LEN           (CONFIG_ENV_SIZE_MAX + (256 << 10))

/*
 * Size of malloc() pool
 */

/*
 * select serial console configuration
 */
#define CONFIG_CONS_INDEX               1

/*
 * Enable crash dump support, this will dump the memory
 * regions via TFTP in case magic word found in memory
 */
/*#define CONFIG_IPQ_APPSBL_DLOAD*/

#define CONFIG_IPQ_ATAG_PART_LIST
#define IPQ_ROOT_FS_PART_NAME		"rootfs"
#define IPQ_ROOT_FS_ALT_PART_NAME	IPQ_ROOT_FS_PART_NAME "_1"

/* allow to overwrite serial and ethaddr */
#define CONFIG_ENV_OVERWRITE
#define CONFIG_BAUDRATE                 115200
#define CONFIG_SYS_BAUDRATE_TABLE       {4800, 9600, 19200, 38400, 57600,\
								115200}

#define V_PROMPT                        "(IPQ) # "
#define CONFIG_SYS_PROMPT               V_PROMPT
#define CONFIG_SYS_CBSIZE               (256 * 2) /* Console I/O Buffer Size */

#define CONFIG_SYS_INIT_SP_ADDR         CONFIG_SYS_SDRAM_BASE + GENERATED_IPQ_RESERVE_SIZE - GENERATED_GBL_DATA_SIZE
#define CONFIG_SYS_MAXARGS              16
#define CONFIG_SYS_PBSIZE               (CONFIG_SYS_CBSIZE + \
						sizeof(CONFIG_SYS_PROMPT) + 16)

#define CONFIG_SYS_SDRAM_BASE           0x40000000
#define CONFIG_SYS_TEXT_BASE            0x41200000
#define CONFIG_SYS_SDRAM_SIZE           0x10000000
#define CONFIG_MAX_RAM_BANK_SIZE        CONFIG_SYS_SDRAM_SIZE
#define CONFIG_SYS_LOAD_ADDR            (CONFIG_SYS_SDRAM_BASE + (64 << 20))

/*
 * I2C Configs
 */
#define CONFIG_IPQ806X_I2C		1

#ifdef CONFIG_IPQ806X_I2C
#define CONFIG_CMD_I2C
#define CONFIG_SYS_I2C_SPEED		0
#endif

#define CONFIG_IPQ806X_PCI

#ifdef CONFIG_IPQ806X_PCI
#define CONFIG_PCI
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#endif
#define CONFIG_IPQ_MMC

#ifdef CONFIG_IPQ_MMC
#define CONFIG_CMD_MMC
#define CONFIG_MMC
#define CONFIG_EFI_PARTITION
#define CONFIG_GENERIC_MMC
#define CONFIG_ENV_IS_IN_MMC
#define CONFIG_SYS_MMC_ENV_DEV  0
#endif

#ifndef __ASSEMBLY__
#include <compiler.h>
#include "../../board/qcom/hw29764958p0p128p512p4x4p4x4pcascade/hw29764958p0p128p512p4x4p4x4pcascade.h"
extern loff_t board_env_offset;
extern loff_t board_env_range;
extern uint32_t flash_index;
extern uint32_t flash_chip_select;
extern uint32_t flash_block_size;
extern board_ipq806x_params_t *gboard_param;
extern int rootfs_part_avail;
#ifdef CONFIG_IPQ806X_PCI
void board_pci_deinit(void);
#endif

static uint32_t inline clk_is_dummy(void)
{
	return gboard_param->clk_dummy;
}

/*
 * XXX XXX Please do not instantiate this structure. XXX XXX
 * This is just a convenience to avoid
 *      - adding #defines for every new reservation
 *      - updating the multiple associated defines like smem base,
 *        kernel start etc...
 *      - re-calculation of the defines if the order changes or
 *        some reservations are deleted
 * For new reservations just adding a member to the structure should
 * suffice.
 * Ensure that the size of this structure matches with the definition
 * of the following IPQ806x compile time definitions
 *      PHYS_OFFSET     (linux-sources/arch/arm/mach-msm/Kconfig)
 *      zreladdr        (linux-sources/arch/arm/mach-msm/Makefile.boot)
 *      CONFIG_SYS_INIT_SP_ADDR defined above should point to the bottom.
 *      MSM_SHARED_RAM_PHYS (linux-sources/arch/arm/mach-msm/board-ipq806x.c)
 *
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
typedef struct {
	uint8_t	nss[16 * 1024 * 1024];
	uint8_t	smem[2 * 1024 * 1024];
	uint8_t	uboot[1 * 1024 * 1024];
	uint8_t	nsstcmdump[128 * 1024];
	uint8_t sbl3[384 * 1024];
	uint8_t plcfwdump[512*1024];
	uint8_t wlanfwdump[(1 * 1024 * 1024) - GENERATED_GBL_DATA_SIZE];
	uint8_t init_stack[GENERATED_GBL_DATA_SIZE];
} __attribute__ ((__packed__)) ipq_mem_reserve_t;

/* Convenience macros for the above convenience structure :-) */
#define IPQ_MEM_RESERVE_SIZE(x)		sizeof(((ipq_mem_reserve_t *)0)->x)
#define IPQ_MEM_RESERVE_BASE(x)		\
	(CONFIG_SYS_SDRAM_BASE + \
	 ((uint32_t)&(((ipq_mem_reserve_t *)0)->x)))
#endif

#define CONFIG_IPQ_SMEM_BASE		IPQ_MEM_RESERVE_BASE(smem)
#define IPQ_KERNEL_START_ADDR	\
	(CONFIG_SYS_SDRAM_BASE + GENERATED_IPQ_RESERVE_SIZE)

#define IPQ_DRAM_KERNEL_SIZE	\
	(CONFIG_SYS_SDRAM_SIZE - GENERATED_IPQ_RESERVE_SIZE)

#define IPQ_BOOT_PARAMS_ADDR		(IPQ_KERNEL_START_ADDR + 0x100)

#define IPQ_NSSTCM_DUMP_ADDR		(IPQ_MEM_RESERVE_BASE(nsstcmdump))

#define IPQ_TEMP_DUMP_ADDR		(IPQ_MEM_RESERVE_BASE(nsstcmdump))

#endif /* __ASSEMBLY__ */

#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_MEMTEST_START        CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END          CONFIG_SYS_MEMTEST_START + 0x100

#define CONFIG_CMDLINE_TAG	 1	/* enable passing of ATAGs */
#define CONFIG_SETUP_MEMORY_TAGS 1

#define CONFIG_CMD_IMI

#define CONFIG_CMD_SOURCE   1
#define CONFIG_INITRD_TAG   1

#define CONFIG_FIT
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_NULLDEV
#define CONFIG_CMD_XIMG

/*Support for Compressed DTB image*/
#ifdef CONFIG_FIT
#define CONFIG_DTB_COMPRESSION
#define CONFIG_DTB_LOAD_MAXLEN 0x100000
#endif

/*
 * SPI Flash Configs
 */

#define CONFIG_IPQ_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_SPANSION
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SPI_FLASH_WINBOND
#define CONFIG_SYS_HZ                   1000

#define CONFIG_SF_DEFAULT_BUS 0
#define CONFIG_SF_DEFAULT_CS 0
#define CONFIG_SF_DEFAULT_MODE SPI_MODE_0

/*
 * NAND Flash Configs
 */

#define CONFIG_IPQ_NAND
#define CONFIG_CMD_NAND
#define CONFIG_CMD_NAND_YAFFS
#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_NAND_SELF_INIT
#define CONFIG_SYS_NAND_ONFI_DETECTION

#define CONFIG_IPQ_MAX_SPI_DEVICE	0
#define CONFIG_IPQ_MAX_NAND_DEVICE	1

#define CONFIG_IPQ_NAND_NAND_INFO_IDX	0
#define CONFIG_IPQ_SPI_NAND_INFO_IDX	1

#define CONFIG_FDT_FIXUP_PARTITIONS

/*
 * Expose SPI driver as a pseudo NAND driver to make use
 * of U-Boot's MTD framework.
 */
#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
					 CONFIG_IPQ_MAX_SPI_DEVICE)

/*
 * U-Boot Env Configs
 */
#define CONFIG_ENV_IS_IN_NAND
#define CONFIG_CMD_SAVEENV
#define CONFIG_BOARD_LATE_INIT

#define CONFIG_OF_LIBFDT	1
#define CONFIG_OF_BOARD_SETUP	1

#if defined(CONFIG_ENV_IS_IN_NAND) || defined(CONFIG_ENV_IS_IN_MMC)

#define CONFIG_ENV_SPI_CS               flash_chip_select
#define CONFIG_ENV_SPI_MODE             SPI_MODE_0
#define CONFIG_ENV_OFFSET               board_env_offset
#define CONFIG_ENV_SECT_SIZE            flash_block_size
#define CONFIG_ENV_SPI_BUS              flash_index
#define CONFIG_ENV_RANGE		board_env_range
#define CONFIG_ENV_SIZE                 CONFIG_ENV_RANGE
#else

#error "Unsupported env. type, should be NAND (even for SPI Flash)."

#endif

/* NSS firmware loaded using bootm */
#define CONFIG_IPQ_FIRMWARE
#define CONFIG_BOOTCOMMAND  "sleep 2;   nmrp;  " \
                            "if loadn_dniimg 0 0x1480000 0x44000000 && " \
                               "chk_dniimg 0x44000000; then " \
                                    "bootipq2; " \
                            "else " \
                                    "fw_recovery; " \
                            "fi"
#define CONFIG_BOOTARGS "console=ttyHSL1,115200n8"

#define CONFIG_CMD_ECHO
#define CONFIG_BOOTDELAY	2

#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_CMD_MTDPARTS

#define CONFIG_RBTREE		/* for ubi */
#define CONFIG_CMD_UBI

#define CONFIG_CMD_RUN
#define CONFIG_CMD_BOOTZ

#define CONFIG_IPQ_MDIO
#define CONFIG_MII
#define CONFIG_CMD_MII
#define CONFIG_BITBANGMII
#define CONFIG_BITBANGMII_MULTI


#define CONFIG_IPQ_SWITCH_ATHRS17

/* Add MBN header to U-Boot */
#define CONFIG_MBN_HEADER

/* Apps bootloader image type used in MBN header */
#define CONFIG_IPQ_APPSBL_IMG_TYPE      0x5

#define CONFIG_SYS_RX_ETH_BUFFER	8

#ifdef CONFIG_IPQ_APPSBL_DLOAD
#define CONFIG_CMD_TFTPPUT
/* We will be uploading very big files */
#define CONFIG_NET_RETRY_COUNT 500
#endif
/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
 * Cache flush and invalidation based on L1 cache, so the cache line
 * size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE  64
/*#define CONFIG_SYS_DCACHE_OFF*/

#define CONFIG_DISPLAY_BOARDINFO
#define CONFIG_MISC_INIT_R

/* Enabling this flag will report any L2 errors.
 * By default we are disabling it */
/*#define CONFIG_IPQ_REPORT_L2ERR*/

/*
 * GPIOs
 *
 * Please also refer to "white_led_gpio", "amber_led_gpio", and "button_gpio"
 * struct arrays in
 * board/qcom/hw29764958p0p128p512p4x4p4x4pcascade/hw29764958p0p128p512p4x4p4x4pcascade_board_param.h
 */
#define USB1_LED_GPIO		7   /* USB1 LED, white (Output Pin/Active HIGH) */
#define USB3_LED_GPIO		8   /* USB3 LED, white (Output Pin/Active HIGH) */
#define TEST_LED_GPIO		9   /* Status LED, amber (Output Pin/Active HIGH) */
#define INTERNET_LED_GPIO	22  /* Internet LED, white (Output Pin/Active HIGH) */
#define WAN_LED_GPIO		23  /* WAN LED, amber (Output Pin/Active HIGH) */
#define WPS_LED_GPIO		24  /* WPS LED, white (Output Pin/Active HIGH) */
#define SATA_LED_GPIO		26  /* E-SATA LED, white (Output Pin/Active HIGH) */
#define POWER_LED_GPIO		53  /* Power LED, white (Output Pin/Active HIGH) */
#define WIFI_ON_OFF_LED_GPIO	64  /* Wi-Fi ON/OFF LED, white (Output Pin/Active HIGH) */

#define WIFI_ON_OFF_BUTTON_GPIO	6   /* Wi-Fi ON/OFF button (Input Pin/Active LOW) */
#define RESET_BUTTON_GPIO	54  /* reset button (Input Pin/Active LOW) */
#define WPS_BUTTON_GPIO		65  /* WPS button (Input Pin/Active LOW) */

#define SW_RESET_GPIO           63  /* Switch Reset (Output Pin/Active HIGH) */

/*
 * Manufacturing Data
 */
#define BOARDCAL			0x1200000
#define BOARDCAL_LEN			0x140000

#define CONFIG_TRIPLE_MAC_ADDRESS 1

#define LAN_MAC_OFFSET			0x00
#define WAN_MAC_OFFSET			0x06
#define WLAN_MAC_OFFSET			0x0c

#define WPSPIN_OFFSET			0x12
#define WPSPIN_LENGTH			8

/* 12(lan/wan) + 6(wlan5g) + 8(wpspin) = 26 (0x1a)*/
#define SERIAL_NUMBER_OFFSET		0x1a
#define SERIAL_NUMBER_LENGTH		13

#define REGION_NUMBER_OFFSET		0x27
#define REGION_NUMBER_LENGTH		2

/*
 * R7800 hardware's PCB number is 29764958, 0MiB NOR Flash, 128MiB NAND Flash,
 * 512MiB RAM, 4Tx 4Rx 2.4GHz radio, 4Tx 4Rx 5GHz radio, with Cascade wireless
 * interfaces. It's HW_ID would be "29764958+0+128+512+4x4+4x4+cascade".
 * "(8 MSB of PCB number)+(NOR flash size)+(NAND flash size)+(SDRAM size)+
 *  (2.4GHz radio)+(5GHz radio)+(variant)", length should be 34
 */
#define BOARD_HW_ID_OFFSET          (REGION_NUMBER_OFFSET + REGION_NUMBER_LENGTH)
#define BOARD_HW_ID_LENGTH          34

/*
 * Model ID: "R7800"
 */
#define BOARD_MODEL_ID_OFFSET       (BOARD_HW_ID_OFFSET + BOARD_HW_ID_LENGTH)
#define BOARD_MODEL_ID_LENGTH       16

#define BOARD_SSID_OFFSET           (BOARD_MODEL_ID_OFFSET + BOARD_MODEL_ID_LENGTH)
#define BOARD_SSID_LENGTH           32

#define BOARD_PASSPHRASE_OFFSET     (BOARD_SSID_OFFSET + BOARD_SSID_LENGTH)
#define BOARD_PASSPHRASE_LENGTH     64

#define CONFIG_CMD_BOARD_PARAMETERS

#define WORKAROUND_QCA8337_GMAC_NMRP_HANG
#define WORKAROUND_DUPLICATE_TFTP_DATA_PACKET_BUG_OF_NMRP_SERVER

#define CONFIG_EXTRA_ENV_SETTINGS					\
	"ethact=eth1\0"							\
	"updateloader=ipq_nand linux && nand erase 0x01180000 0x00080000 && "	\
	"imgaddr=0x42000000 && source $imgaddr:script\0"	\
	""

#endif /* _IPQCDP_H */
