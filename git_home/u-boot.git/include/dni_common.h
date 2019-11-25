/*
 * (C) Copyright 2000-2004
 * Wolfgang Denk, DENX Software Engineering, wd@denx.de.
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#ifndef __DNI_COMMON_H_
#define __DNI_COMMON_H_	1

#ifdef DNI_NAND
#include <nand.h>

void update_data(ulong, int, ulong, size_t, int, int);
size_t get_len_incl_bad (nand_info_t *, loff_t, const size_t);
#endif

void get_board_data(int offset, int len, u8* buf);
int set_board_data(int offset, int len, u8 *buf);

#ifdef NETGEAR_BOARD_ID_SUPPORT
int board_match_image_hw_id(ulong);
int board_match_image_model_id(ulong);
void board_update_image_model_id(ulong);
#endif

#if defined(NETGEAR_BOARD_ID_SUPPORT) && \
    defined(OPEN_SOURCE_ROUTER_SUPPORT) && defined(OPEN_SOURCE_ROUTER_ID)
extern int board_model_id_match_open_source_id(void);
extern int image_match_open_source_fw_id(ulong);
extern int board_image_reserved_length(void);
#else
static inline int board_model_id_match_open_source_id(void)
{
	return 0;
}
static inline int image_match_open_source_fw_id(ulong fw_image_addr)
{
	return 0;
}
static inline int board_image_reserved_length(void)
{
	return 0;
}
#endif  /* NETGEAR_BOARD_ID_SUPPORT && OPEN_SOURCE_ROUTER */

#if defined(WORKAROUND_QCA8337_GMAC_NMRP_HANG)
#define workaround_qca8337_gmac_nmrp_hang_action()  do {  \
	DECLARE_GLOBAL_DATA_PTR;  \
	eth_halt();  \
	eth_init(gd->bd);  \
} while (0)
#else
#define workaround_qca8337_gmac_nmrp_hang_action()  do {} while (0)
#endif

#if defined(WORKAROUND_DUPLICATE_TFTP_DATA_PACKET_BUG_OF_NMRP_SERVER)
#define workaround_duplicate_tftp_data_packet_bug_of_nmrp_server()  do {  \
	timeout = 1000UL;  \
} while (0)
#else
#define workaround_duplicate_tftp_data_packet_bug_of_nmrp_server()  do {  \
} while (0)
#endif

#if defined(WORKAROUND_IPQ40XX_GMAC_NMRP_HANG)
#define workaround_ipq40xx_gmac_nmrp_hang_action()  do {  \
	DECLARE_GLOBAL_DATA_PTR;  \
	eth_halt();  \
	eth_init(gd->bd);  \
} while (0)
#else
#define workaround_ipq40xx_gmac_nmrp_hang_action()  do {} while (0)
#endif

#endif	/* __DNI_COMMON_H_ */
