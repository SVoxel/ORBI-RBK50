/*
 *
 * Copyright (c) 2015, The Linux Foundation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of The Linux Foundation nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _HW29765285P16P0P256_H
#define _HW29765285P16P0P256_H

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

#define CONFIG_IPQ40XX
#define CONFIG_BOARD_EARLY_INIT_F
#define CONFIG_SYS_NO_FLASH
#define CONFIG_SYS_CACHELINE_SIZE	64
#define CONFIG_SKIP_LOWLEVEL_INIT
#define CONFIG_SYS_HZ			1000

#define CONFIG_IPQ40XX_USB
#ifdef CONFIG_IPQ40XX_USB
#define CONFIG_USB_XHCI
#define CONFIG_CMD_USB
#define CONFIG_DOS_PARTITION
#define CONFIG_USB_STORAGE
#define CONFIG_SYS_USB_XHCI_MAX_ROOT_PORTS	2
#define CONFIG_USB_MAX_CONTROLLER_COUNT		2
#endif

#define CONFIG_QCOM_UART
#define CONFIG_CONS_INDEX		1
#define CONFIG_QCOM_BAM			1
#define CONFIG_CMD_DNI

#define CONFIG_ENV_OVERWRITE
#define CONFIG_BAUDRATE			115200
#define CONFIG_SYS_BAUDRATE_TABLE	{4800, 9600, 19200, 38400, 57600,\
								115200}
#define V_PROMPT			"(IPQ40xx) # "
#define CONFIG_SYS_PROMPT		V_PROMPT
#define CONFIG_SYS_CBSIZE		(256 * 2) /* Console I/O Buffer Size */
#define CONFIG_SYS_MAXARGS		16
#define CONFIG_SYS_PBSIZE		(CONFIG_SYS_CBSIZE + \
						sizeof(CONFIG_SYS_PROMPT) + 16)

#define CONFIG_CPU_CONTEXT_DUMP_BASE   0x87B00000
#define CONFIG_CPU_CONTEXT_DUMP_SIZE   0x80000

#define CONFIG_SYS_SDRAM_BASE		0x80000000
#define CONFIG_SYS_TEXT_BASE		0x87300000
#define CONFIG_SYS_SDRAM_SIZE		0x10000000
#define CONFIG_SYS_INIT_SP_ADDR		(CONFIG_SYS_TEXT_BASE + 0x100000 - GENERATED_GBL_DATA_SIZE)
#define CONFIG_MAX_RAM_BANK_SIZE	CONFIG_SYS_SDRAM_SIZE
#define CONFIG_SYS_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (64 << 20))
#define CONFIG_DTB_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (96 << 20))
#define CONFIG_NR_DRAM_BANKS		1
#define CONFIG_OF_LIBFDT		1
#define CONFIG_OF_BOARD_SETUP		1

#define CONFIG_IPQ40XX_I2C
#ifdef CONFIG_IPQ40XX_I2C
#define CONFIG_CMD_I2C
#define CONFIG_SYS_I2C_SPEED	0
#endif

#define CONFIG_IPQ40XX_PCI
#ifdef CONFIG_IPQ40XX_PCI
#define CONFIG_PCI
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#endif

#ifndef __ASSEMBLY__
#include <compiler.h>
extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;

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
 * of the following IPQ40xx compile time definitions
 *      PHYS_OFFSET     (linux-sources/arch/arm/mach-msm/Kconfig)
 *      zreladdr        (linux-sources/arch/arm/mach-msm/Makefile.boot)
 *      CONFIG_SYS_INIT_SP_ADDR defined above should point to the bottom.
 *      MSM_SHARED_RAM_PHYS (linux-sources/arch/arm/mach-msm/board-ipq40xx.c)
 *
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
typedef struct {
	uint8_t uboot[1024 * 1024 - GENERATED_GBL_DATA_SIZE];	/* ~1MB */
	uint8_t init_stack[GENERATED_GBL_DATA_SIZE];
	uint8_t sbl[1024 * 1024];				/* 1 MB */
	uint8_t cnss_debug[6 * 1024 * 1024];			/* 6 MB */
	uint8_t tz_apps[3 * 1024 * 1024];			/* 3 MB */
	uint8_t smem[512 * 1024];				/* 512 KB */
	uint8_t tz[1536 * 1024];				/* 1.5 MB */
} __attribute__ ((__packed__)) qca_mem_reserve_t;

#define QCA_MEM_RESERVE_SIZE(x)		sizeof(((qca_mem_reserve_t *)0)->x)
#define QCA_MEM_RESERVE_BASE(x)		\
	(CONFIG_SYS_TEXT_BASE + \
	 ((uint32_t)&(((qca_mem_reserve_t *)0)->x)))
#endif

#define CONFIG_QCA_SMEM_BASE		0x87e00000
#define QCA_KERNEL_START_ADDR	\
	(CONFIG_SYS_SDRAM_BASE + GENERATED_QCA_RESERVE_SIZE)

#define QCA_DRAM_KERNEL_SIZE	\
	(CONFIG_SYS_SDRAM_SIZE - GENERATED_QCA_RESERVE_SIZE)

#define QCA_BOOT_PARAMS_ADDR	(QCA_KERNEL_START_ADDR + 0x100)
#endif

#define IPQ_ROOT_FS_PART_NAME		"rootfs"

/* Environment */
#define CONFIG_IPQ40XX_ENV
#define CONFIG_ARCH_CPU_INIT
#define CONFIG_ENV_IS_IN_NAND
#define CONFIG_CMD_SAVEENV
#define CONFIG_BOARD_LATE_INIT
#define CONFIG_ENV_OFFSET		board_env_offset
#define CONFIG_ENV_SIZE_MAX		(256 << 10) /* 256 KB */
#define CONFIG_ENV_RANGE		board_env_size
#define CONFIG_ENV_SIZE			board_env_range
#define CONFIG_SYS_MALLOC_LEN		(CONFIG_ENV_SIZE_MAX + (512 << 10))

#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_MEMTEST_START	CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END		CONFIG_SYS_MEMTEST_START + 0x100
#define CONFIG_CMD_SOURCE		1
#define CONFIG_INITRD_TAG		1
#define CONFIG_FIT
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_NULLDEV
#define CONFIG_CMD_XIMG
#define CONFIG_CMD_NET

/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
 * Cache flush and invalidation based on L1 cache, so the cache line
 * size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE	64

/* CMDS */
#define	CONFIG_CMD_RUN

/*
 * NAND Flash Configs
 */

/* CONFIG_QPIC_NAND: QPIC NAND in BAM mode
 * CONFIG_IPQ_NAND: QPIC NAND in FIFO/block mode.
 * BAM is enabled by default.
 */
#define CONFIG_QPIC_NAND
#define CONFIG_CMD_NAND
#define CONFIG_CMD_NAND_YAFFS
#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_NAND_SELF_INIT
#define CONFIG_SYS_NAND_ONFI_DETECTION

/*
 * Expose SPI driver as a pseudo NAND driver to make use
 * of U-Boot's MTD framework.
 */
#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
					CONFIG_IPQ_MAX_SPI_DEVICE)

#define CONFIG_IPQ_MAX_SPI_DEVICE	2
#define CONFIG_IPQ_MAX_NAND_DEVICE	1

#define CONFIG_IPQ_NAND_NAND_INFO_IDX	0
#define CONFIG_QPIC_NAND_NAND_INFO_IDX	0
#define CONFIG_IPQ_SPI_NAND_INFO_IDX	1
#define CONFIG_IPQ_SPI_NOR_INFO_IDX	2

#define CONFIG_FDT_FIXUP_PARTITIONS

/*
 * SPI Flash Configs
 */

#define CONFIG_QCA_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_WINBOND
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SPI_FLASH_GIGA
#define CONFIG_SPI_NOR_GENERIC
#define CONFIG_IPQ40XX_SPI

#define CONFIG_SF_DEFAULT_BUS 0
#define CONFIG_SF_DEFAULT_CS 0
#define CONFIG_SF_SPI_NAND_CS 1
#define CONFIG_SF_DEFAULT_MODE SPI_MODE_0
#define CONFIG_IPQ40XX_XIP	1

#define CONFIG_QUP_SPI_USE_DMA 1

#define CONFIG_SPI_NAND_GIGA 1
#define CONFIG_SPI_NAND_ATO
#define CONFIG_SPI_NAND_MACRONIX
#define CONFIG_SPI_NAND_WINBOND
/*
 * ESS Configs
 */
#define CONFIG_CMD_PING
#define CONFIG_CMD_DHCP
#define CONFIG_IPQ40XX_ESS	1
#define CONFIG_IPQ40XX_EDMA	1
#define CONFIG_NET_RETRY_COUNT		5
#define CONFIG_SYS_RX_ETH_BUFFER	16
#define CONFIG_IPQ40XX_MDIO	1
#define CONFIG_QCA8075_PHY	1
#define CONFIG_QCA8033_PHY	1
#define CONFIG_MII
#define CONFIG_CMD_MII
#define CONFIG_IPADDR	192.168.1.1
#define CONFIG_SERVERIP		192.168.1.10
#define CONFIG_LOADADDR		  0x84000000
#define CONFIG_IPQ_NO_MACS	2
/*
 * CRASH DUMP ENABLE
 */

//#define CONFIG_QCA_APPSBL_DLOAD	1

#ifdef CONFIG_QCA_APPSBL_DLOAD
#define CONFIG_CMD_TFTPPUT
/* We will be uploading very big files */
#undef CONFIG_NET_RETRY_COUNT
#define CONFIG_NET_RETRY_COUNT 500
#endif
#define CONFIG_CMD_ECHO

/*
 * Expose SPI driver as a pseudo NAND driver to make use
 * of U-Boot's MTD framework.
 */
#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
					 CONFIG_IPQ_MAX_SPI_DEVICE)

#define CONFIG_QCA_MMC

#ifdef CONFIG_QCA_MMC
#define CONFIG_CMD_MMC
#define CONFIG_MMC
#define CONFIG_EFI_PARTITION
#define CONFIG_GENERIC_MMC
#define CONFIG_ENV_IS_IN_MMC
#define CONFIG_SYS_MMC_ENV_DEV  0
#endif


#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_CMD_MTDPARTS

//#define CONFIG_RBTREE		/* for ubi */
//#define CONFIG_CMD_UBI
#define CONFIG_BOOTCOMMAND	"sleep 1; nmrp; check_dni_image; bootipq2"
#define CONFIG_BOOTDELAY	2
#define CONFIG_IPQ_FDT_HIGH	0x87000000
#define CONFIG_SYS_LONGHELP
#define CONFIG_DISPLAY_BOARDINFO

#define CONFIG_QCA_SINGLE_IMG 
#define CONFIG_HW29765285P16P0P256

#define CONFIG_SYS_FLASH_SECTOR_SIZE (0x10000)
#define CFG_IMAGE_LEN 0xe10000
#define CFG_IMAGE_BASE_ADDR 0x1b0000
#define CONFIG_SYS_IMAGE_ADDR_BEGIN (CFG_IMAGE_BASE_ADDR)
#define CFG_IMAGE_ADDR_END   (CFG_IMAGE_BASE_ADDR + CFG_IMAGE_LEN)
#define CFG_FLASH_CONFIG_BASE               0x180000
#define CFG_FLASH_CONFIG_PARTITION_SIZE     0x10000
#define CONFIG_SYS_STRING_TABLE_LEN 0x10000
#define CFG_STRING_TABLE_NUMBER 4
#define CFG_STRING_TABLE_TOTAL_LEN 0x40000 /* Totally allocate 1024K to save all string tables */
#define CFG_STRING_TABLE_BASE_ADDR (0xfc0000)
#define CFG_STRING_TABLE_ADDR_BEGIN (CFG_STRING_TABLE_BASE_ADDR)
#define CFG_STRING_TABLE_ADDR_END   (CFG_STRING_TABLE_ADDR_BEGIN + CFG_STRING_TABLE_TOTAL_LEN)

#define WORKAROUND_IPQ40XX_GMAC_NMRP_HANG 1

/*
 * Manufacturing Data
 */
#define BOARDCAL            	0x1a0000
#define BOARDCAL_LEN            0x10000
#define CAL_SECTOR				(23)

#define CONFIG_TRIPLE_MAC_ADDRESS 1

#define LAN_MAC_OFFSET          0x00
#define WAN_MAC_OFFSET          0x06
#define WLAN_MAC_OFFSET         0x0c

#define WPSPIN_OFFSET           0x12
#define WPSPIN_LENGTH           8

/* 12(lan/wan) + 6(wlan5g) + 8(wpspin) = 26 (0x1a)*/
#define SERIAL_NUMBER_OFFSET        0x1a
#define SERIAL_NUMBER_LENGTH        13

#define REGION_NUMBER_OFFSET        0x27
#define REGION_NUMBER_LENGTH        2

#define BOARD_HW_ID_OFFSET          (REGION_NUMBER_OFFSET + REGION_NUMBER_LENGTH)
#define BOARD_HW_ID_LENGTH          26

#define BOARD_MODEL_ID_OFFSET       (BOARD_HW_ID_OFFSET + BOARD_HW_ID_LENGTH)
#define BOARD_MODEL_ID_LENGTH       16

#define BOARD_SSID_OFFSET           (BOARD_MODEL_ID_OFFSET + BOARD_MODEL_ID_LENGTH)
#define BOARD_SSID_LENGTH           32

#define BOARD_PASSPHRASE_OFFSET     (BOARD_SSID_OFFSET + BOARD_SSID_LENGTH)
#define BOARD_PASSPHRASE_LENGTH     64

#define NETGEAR_BOARD_ID_SUPPORT 1

#define CONFIG_CMD_IMI

#define CONFIG_EXTRA_ENV_SETTINGS					\
	"delenv=sf probe && sf erase 0x000e0000 +0x10000\0"					\
	""

#define CONFIG_MISC_INIT_R

#define CONFIG_CMD_MISC

/*
 * GPIO
 */

/* for SIPO (Serial-In Parallel-Out) shift register LED controller */
#define LED_CLK_GPIO    5       /* SIPO shift register clock (Output pin/POSITIVE Edge triggered) */
#define LED_DATA_GPIO   4       /* SIPO shift register input (Output pin) */
#define LED_CLR_GPIO    2
#define RESET_BUTTON    63
#define WPS_BUTTON              0

#define ALL_LED_SIPO_GPIO_MASK         \
               (1 << LED_CLK_GPIO)     \
               | (1 << LED_DATA_GPIO)

/* delay before LED_CLK triggers LEDs. Unit: micro second */
#define LED_CLK_DELAY_USEC              1
#define LED_NUM                         8

/*
 * LEDs definition. Lower number, earlier input into SIPO shift register LED
 * controller.
 */
#define ROUTER_LED_RED          7
#define ROUTER_LED_GREEN        6
#define CLIENT_LED_RED          5
#define CLIENT_LED_GREEN        4
#define LEFT_LED_BLUE           3
#define RIGHT_LED_BLUE          2
#define POWER_LED_AMBER         0
#define POWER_LED_GREEN         1

#define CONFIG_CMD_BOARD_PARAMETERS 1

#endif
