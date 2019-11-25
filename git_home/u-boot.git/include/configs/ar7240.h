/*
 * This file contains the configuration parameters for the dbau1x00 board.
 */

#ifndef __AR7240_H
#define __AR7240_H

#define CONFIG_MIPS32		1  /* MIPS32 CPU core	*/

#define CONFIG_BOOTDELAY	4	/* autoboot after 4 seconds	*/

#define CONFIG_BAUDRATE		115200 
#define CONFIG_SYS_BAUDRATE_TABLE  { 	115200}

#define	CONFIG_TIMESTAMP		/* Print image info with timestamp */

#define CONFIG_ROOTFS_RD

#define	CONFIG_BOOTARGS_RD     "console=ttyS0,115200 root=01:00 rd_start=0x80600000 rd_size=5242880 init=/sbin/init mtdparts=ar7240-nor0:256k(u-boot),64k(u-boot-env),4096k(rootfs),2048k(uImage)"

/* XXX - putting rootfs in last partition results in jffs errors */
#define	CONFIG_BOOTARGS_FL     "console=ttyS0,115200 root=31:02 rootfstype=jffs2 init=/sbin/init mtdparts=ar7240-nor0:256k(u-boot),64k(u-boot-env),5120k(rootfs),2048k(uImage)"

#ifdef CONFIG_ROOTFS_FLASH
#define CONFIG_BOOTARGS CONFIG_BOOTARGS_FL
#else
#define CONFIG_BOOTARGS ""
#endif

/*
 * Miscellaneous configurable options
 */
#define	CONFIG_SYS_LONGHELP				/* undef to save memory      */
#define	CONFIG_SYS_PROMPT		"ar7240> "	/* Monitor Command Prompt    */
#if defined(CONFIG_AP121) || defined(CONFIG_WNR1000V4) || defined(CONFIG_HW29763847P16P64) || defined(CONFIG_WASP)
#define	CONFIG_SYS_CBSIZE		512		/* Console I/O Buffer Size   */
#else
#define	CONFIG_SYS_CBSIZE		256		/* Console I/O Buffer Size   */
#endif
#define	CONFIG_SYS_PBSIZE (CONFIG_SYS_CBSIZE+sizeof(CONFIG_SYS_PROMPT)+16)  /* Print Buffer Size */
#define	CONFIG_SYS_MAXARGS		16		/* max number of command args*/

#define CONFIG_SYS_MALLOC_LEN		128*1024

#define CONFIG_SYS_BOOTPARAMS_LEN	128*1024

#define CONFIG_SYS_SDRAM_BASE		0x80000000     /* Cached addr */
//#define CONFIG_SYS_SDRAM_BASE		0xa0000000     /* Cached addr */

#define	CONFIG_SYS_LOAD_ADDR		0x81000000     /* default load address	*/
//#define	CONFIG_SYS_LOAD_ADDR		0xa1000000     /* default load address	*/

#define CONFIG_SYS_MEMTEST_START	0x80100000
#undef CONFIG_SYS_MEMTEST_START
#define CONFIG_SYS_MEMTEST_START       0x80200000
#define CONFIG_SYS_MEMTEST_END		0x83800000

/*------------------------------------------------------------------------
 * *  * JFFS2
 */
#define CONFIG_SYS_JFFS_CUSTOM_PART            /* board defined part   */
#define CONFIG_JFFS2_CMDLINE
#define MTDIDS_DEFAULT      "nor0=ar7240-nor0"

/* default mtd partition table */
#define MTDPARTS_DEFAULT    "mtdparts=ar7240-nor0:256k(u-boot),"\
                            "384k(experi-jffs2)"

#define CONFIG_MEMSIZE_IN_BYTES

#define CONFIG_SYS_HZ          40000000

#define CONFIG_SYS_RX_ETH_BUFFER   16

/*
** PLL Config for different CPU/DDR/AHB frequencies
*/

#define CONFIG_SYS_PLL_200_200_100   0
#define CONFIG_SYS_PLL_300_300_150   1
#define CONFIG_SYS_PLL_320_320_160   2
#define CONFIG_SYS_PLL_340_340_170   3
#define CONFIG_SYS_PLL_350_350_175   4
#define CONFIG_SYS_PLL_360_360_180   5
#define CONFIG_SYS_PLL_400_400_200   6
#define CONFIG_SYS_PLL_300_300_75    7
#define CONFIG_SYS_PLL_400_400_100   8
#define CONFIG_SYS_PLL_320_320_80    9
#if defined(CONFIG_AP121) || defined(CONFIG_WNR1000V4) || defined(CONFIG_HW29763847P16P64) || defined(CONFIG_WASP)
#define CONFIG_SYS_PLL_410_400_200	0x0a
#define CONFIG_SYS_PLL_420_400_200	0x0b
#define CONFIG_SYS_PLL_80_80_40	0x0c
#define CONFIG_SYS_PLL_64_64_32	0x0d
#define CONFIG_SYS_PLL_48_48_24	0x0e
#define CONFIG_SYS_PLL_32_32_16	0x0f
#if defined(CONFIG_WASP)
#define CONFIG_SYS_PLL_333_333_166	0x10
#else
#define CONFIG_SYS_PLL_333_333_166	0x00
#endif
#define CONFIG_SYS_PLL_266_266_133	0x11
#define CONFIG_SYS_PLL_266_266_66	0x12
#define CONFIG_SYS_PLL_240_240_120	0x13
#define CONFIG_SYS_PLL_160_160_80	0x14
#define CONFIG_SYS_PLL_400_200_200	0x15
#define CONFIG_SYS_PLL_500_400_200	0x16
#define CONFIG_SYS_PLL_600_400_200	0x17
#define CONFIG_SYS_PLL_600_500_250	0x18
#define CONFIG_SYS_PLL_600_400_300	0x19
#define CONFIG_SYS_PLL_500_500_250	0x1a
#else
#define CONFIG_SYS_PLL_240_240_120   10
#define CONFIG_SYS_PLL_160_160_80    11
#define CONFIG_SYS_PLL_400_200_200   12
#endif
#if defined(CONFIG_WASP)
#define CONFIG_SYS_PLL_600_350_175		0x1b
#define CONFIG_SYS_PLL_600_300_150		0x1c
#define CONFIG_SYS_PLL_600_550_1_1G_275	0x1d
#define CONFIG_SYS_PLL_600_500_1G_250		0x1e
#define CONFIG_SYS_PLL_533_400_200		0x1f
#define CONFIG_SYS_PLL_600_450_200		0x20
#define CONFIG_SYS_PLL_533_500_250		0x21
#define CONFIG_SYS_PLL_700_400_200		0x22
#define CONFIG_SYS_PLL_650_600_300		0x23
#define CONFIG_SYS_PLL_600_600_300		0x24
#define CONFIG_SYS_PLL_600_550_275		0x25
#define CONFIG_SYS_PLL_566_475_237		0x26
#define CONFIG_SYS_PLL_566_450_225		0x27
#define CONFIG_SYS_PLL_600_332_166		0x28
#define CONFIG_SYS_PLL_600_575_287		0x29
#define CONFIG_SYS_PLL_600_525_262		0x2a
#define CONFIG_SYS_PLL_566_550_275		0x2b
#define CONFIG_SYS_PLL_566_525_262		0x2c
#define CONFIG_SYS_PLL_600_332_200		0x2d
#define CONFIG_SYS_PLL_600_266_133		0x2e
#define CONFIG_SYS_PLL_600_266_200		0x2f
#define CONFIG_SYS_PLL_600_650_325		0x30
#define CONFIG_SYS_PLL_566_400_200		0x31
#define CONFIG_SYS_PLL_566_500_250		0x32
#define CONFIG_SYS_PLL_600_1_2G_400_200	0x33
#define CONFIG_SYS_PLL_560_480_240		0x34
#endif

/*-----------------------------------------------------------------------
 * Cache Configuration
 */
#define CONFIG_SYS_DCACHE_SIZE		32768
#define CONFIG_SYS_ICACHE_SIZE		65536
#define CONFIG_SYS_CACHELINE_SIZE	32

#endif	/* __CONFIG_H */
