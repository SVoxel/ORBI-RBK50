#ifndef __CONFIG_H_
#define __CONFIG_H_

#define POT_FILENAME		"/tmp/pot_value"

#define POT_MAX_VALUE	4320		/* 4320 minutes */
#define POT_RESOLUTION	1		/* minute */
#define POT_PORT	3333		/* potval listen this port */

#define TOTAL_BLOCK_COUNT	8
#define NAND_FLASH_BLOCKSIZE	(128 * 1024)	/* bytes, 128KB */
#define NAND_FLASH_PAGESIZE	(2 * 1024)	/* bytes, 2KB */
#define POT_MTD_SIZE	(512 * 1024)	/* bytes, POT partition is 512KB(4 blocks) by default */
#define FIRST_NTP_TIME_OFFSET	(2 * NAND_FLASH_BLOCKSIZE)
#define FIRST_WIFISTATION_MAC_OFFSET	(FIRST_NTP_TIME_OFFSET + NAND_FLASH_PAGESIZE)
#define NTPTIME_POSTION_BYINT (2048/4)
#define SUPPORT_DNITOOLBOX 1
#define NTPTIME_POSTION 2048
#define STAMAC_POSTION (2048 + 4)

#endif
#define SUPPORT_NAND_TYPE 0
#define SUPPORT_NOR_TYPE 0
#define SUPPORT_EMMC_TYPE 1
