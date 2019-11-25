/*
 * Copyright (c) 2015 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/

#include <common.h>
#include <command.h>
#include <image.h>
#include <asm/arch-ipq806x/smem.h>
#include <asm/arch-ipq40xx/scm.h>
#include <configs/hw29765352p32p4000p512p2x2p2x2p4x4.h>
#include <configs/hw29765265p16p0p256p2x2p2x2.h>
#include <configs/hw29765285p16p0p256.h>
DECLARE_GLOBAL_DATA_PTR;

static int do_dumpqca_data(cmd_tbl_t *cmdtp, int flag, int argc,
				char *const argv[])
{
	char runcmd[128];
	char *serverip = NULL;
	/* dump to root of TFTP server if none specified */
	char *dumpdir;
	uint32_t memaddr;
	int ret;
	char buf;

	if (argc == 2) {
		serverip = argv[1];
		printf("Using given serverip %s\n", serverip);
		setenv("serverip", serverip);
	} else {
		serverip = getenv("serverip");
		if (serverip != NULL) {
			printf("Using serverip from env %s\n", serverip);
		} else {
			printf("\nServer ip not found, run dhcp or configure\n");
			return CMD_RET_FAILURE;
		}
	}

	if ((dumpdir = getenv("dumpdir")) != NULL) {
		printf("Using directory %s in TFTP server\n", dumpdir);
	} else {
		dumpdir = "";
		printf("Env 'dumpdir' not set. Using / dir in TFTP server\n");
	}

	printf("\nProcessing dumps.....\n");
	ret = scm_call(SCM_SVC_FUSE, QFPROM_IS_AUTHENTICATE_CMD,
				NULL, 0, &buf, sizeof(char));
	if (ret == 0 && buf == 1) {
		/*
		* Dumps CPU_CONTEXT_DUMP_BASE to gd->ram_size.
		*/
		memaddr = CONFIG_CPU_CONTEXT_DUMP_BASE;
		gd->ram_size = CONFIG_CPU_CONTEXT_DUMP_SIZE;
		snprintf(runcmd, sizeof(runcmd), "tftpput 0x%x 0x%x %s/%s",
			memaddr, (unsigned int)gd->ram_size,
			dumpdir, "EBICS0.bin");
	} else {
		/*
		* Dumps CONFIG_SYS_SDRAM_BASE to gd->ram_size.
		*/
		memaddr = CONFIG_SYS_SDRAM_BASE;
		snprintf(runcmd, sizeof(runcmd), "tftpput 0x%x 0x%x %s/%s",
			memaddr, (unsigned int)gd->ram_size,
			dumpdir, "EBICS0.bin");
	}

	if (run_command(runcmd, 0) != CMD_RET_SUCCESS)
		return CMD_RET_FAILURE;
	udelay(10000); /* give some delay for server */
	return CMD_RET_SUCCESS;
}

U_BOOT_CMD(dumpipq_data, 2, 0, do_dumpqca_data,
	   "dumpipq_data crashdump collection from memory",
	   "dumpipq_data [serverip] - Crashdump collection from memory vi tftp\n");
