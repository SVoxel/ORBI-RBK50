/*
 *     Copyright (C) 2008 Delta Networks Inc.
 */
#include <common.h>
#include <command.h>
#include <net.h>
#include "tftp.h"
#include "bootp.h"
#include "nmrp.h"
#include <dni_common.h>

typedef void nmrp_thand_f(void);
ulong NmrpOuripaddr;
ulong NmrpOuripSubnetMask;
ulong NmrpFwOption;
int NmrpFwUPOption = 0;
int NmrpSTUPOption = 0;
int NmrpStringTableUpdateCount = 0;
int NmrpStringTableUpdateIndex = 0;
int NmrpState = 0;
ulong Nmrp_active_start=0;
static ulong NmrpBlock;
static ulong NmrpLastBlock = 0;
int Nmrp_Listen_TimeoutCount = 0;
int Nmrp_REQ_TimeoutCount = 0;
static ulong NmrptimeStart;
static ulong NmrptimeDelta;
static nmrp_thand_f *NmrptimeHandler;
static uchar Nmrpproto;
static int Nmrp_Closing_TimeoutCount = 0;
IPaddr_t NmrpClientIP = 0;
uchar NmrpClientEther[6] = { 0, 0, 0, 0, 0, 0 };
uchar NmrpServerEther[6] = { 0, 0, 0, 0, 0, 0 };
static u16 NmrpDevRegionOption = 0;
static uchar NmrpFirmwareFilename[FIRMWARE_FILENAME_LEN] = FIRMWARE_FILENAME;
static u32 NmrpStringTableBitmask = 0;
static uchar NmrpStringTableFilename[STRING_TABLE_FILENAME_LEN] = {0};
static int NmrpStringTableUpdateList[STRING_TABLE_NUMBER_MAX] = {0};
ulong NmrpAliveTimerStart = 0;
ulong NmrpAliveTimerBase = 0;
int NmrpAliveTimerTimeout = NMRP_TIMEOUT_ACTIVE;
int NmrpAliveWaitACK = 0;

static void Nmrp_Listen_Timeout(void);
void NmrpSend(void);

void NmrpStart(void);

void NmrpSetTimeout(unchar, ulong, nmrp_thand_f *);

void Nmrp_Led_Flashing_Timeout();

static int MyNetSetEther(volatile uchar * xet, uchar * addr, uint prot)
{
	struct ethernet_hdr *et = (struct ethernet_hdr *) xet;
	ushort myvlanid;
	myvlanid = ntohs(NetOurVLAN);
	if (myvlanid == (ushort) - 1)
		myvlanid = VLAN_NONE;
	memcpy(et->et_dest, addr, 6);
	memcpy(et->et_src, NetOurEther, 6);
	if ((myvlanid & VLAN_IDMASK) == VLAN_NONE) {
		et->et_protlen = htons(prot);
		return ETHER_HDR_SIZE;
	} else {
		struct vlan_ethernet_hdr *vet =
				(struct vlan_ethernet_hdr *) xet;
		vet->vet_vlan_type = htons(PROT_VLAN);
		vet->vet_tag = htons((0 << 5) | (myvlanid & VLAN_IDMASK));
		vet->vet_type = htons(prot);
		return VLAN_ETHER_HDR_SIZE;
	}

	return ETHER_HDR_SIZE;
}

static void Nmrp_Conf_Timeout(void)
{
	if (++Nmrp_REQ_TimeoutCount > NMRP_MAX_RETRY_CONF) {
		puts("\n retry conf count exceeded;\n");
		Nmrp_REQ_TimeoutCount = 0;
		NmrpStart();
	} else {
		puts("T");
		NmrpSetTimeout(NMRP_CODE_CONF_ACK,
			       (NMRP_TIMEOUT_REQ * CONFIG_SYS_HZ) / 2,
			       Nmrp_Conf_Timeout);
		NmrpSend();
	}
}

void Nmrp_Closing_Timeout()
{

	if (++Nmrp_Closing_TimeoutCount > NMRP_MAX_RETRY_CLOSE) {
		puts("\n close retry count exceed;stay idle and blink\n");
		Nmrp_Closing_TimeoutCount = 0;
		board_reset_default();

		puts("\nNMRP is complete. Please switch OFF power.\n");

		Nmrp_Led_Flashing_Timeout();
		/* Unreachable */

		ctrlc();
		console_assign(stdout, "nulldev");
		console_assign(stderr, "nulldev");
		NmrpState = STATE_CLOSED;
		net_set_state(NETLOOP_SUCCESS);
	} else {
		puts("T");
		NmrpSetTimeout(NMRP_CODE_CLOSE_ACK,
			       (CONFIG_SYS_HZ * NMRP_TIMEOUT_REQ) / 2,
			       Nmrp_Closing_Timeout);
		NmrpSend();
	}
}

void Nmrp_Led_Flashing_Timeout()
{
	static int NmrpLedCount = 0;
	while (1) {
		NmrpLedCount++;
		if ((NmrpLedCount % 2) == 1) {
			board_test_led(0);
			udelay(500000);
		} else {
			board_test_led(1);
			udelay(500000);
		}
	}
	/* Unreachable */

	/*press ctl+c, turn on test led,then normally boot*/
	board_test_led(0);
}

extern void NmrpSend(void)
{
	volatile u8 *pkt;
	volatile u8 *xp;
	int len = 0;
	int eth_len = 0;
	pkt = (u8 *) NetTxPacket;
	pkt += MyNetSetEther(pkt, NmrpServerEther, PROT_NMRP);
	eth_len = pkt - NetTxPacket;

	switch (NmrpState) {
	case STATE_LISTENING:
		xp = pkt;
		*((u16 *) pkt) = 0;
		pkt += 2;
		*((u8 *) pkt) = (NMRP_CODE_CONF_REQ);
		pkt++;
		*((u8 *) pkt) = 0;
		pkt++;
		*((u16 *) pkt) = htons(6);
		pkt += 2;

		len = pkt - xp;
		(void)NetSendPacket((u8 *) NetTxPacket, eth_len + len);
		NetSetTimeout((NMRP_TIMEOUT_REQ * CONFIG_SYS_HZ) / 2,
			      Nmrp_Conf_Timeout);
		NmrpSetTimeout(NMRP_CODE_CONF_ACK,
			       (NMRP_TIMEOUT_REQ * CONFIG_SYS_HZ) / 2,
			       Nmrp_Conf_Timeout);
		break;
	case STATE_CONFIGING:
		xp = pkt;
		*((u16 *) pkt) = 0;
		pkt += 2;
		*((u8 *) pkt) = (NMRP_CODE_TFTP_UL_REQ);
		pkt++;
		*((u8 *) pkt) = 0;
		pkt++;
		/* Recv ST-UP option, upgrade string table.
		 * add FILE-NAME option to TFTP-UL-REQ
		 * value of FILE-NAME would like "string table 01"*/
		if (NmrpSTUPOption == 1) {
			/* Append the total length to packet
			 * NMRP_HEADER_LEN for the length of "Reserved", "Code", "Identifier", "Length"
			 * STRING_TABLE_FILENAME_OPT_LEN for the length of "Options". */
			*((u16 *) pkt) = htons((NMRP_HEADER_LEN + STRING_TABLE_FILENAME_OPT_LEN));
			pkt += 2;

			/* Append NMRP option type FILE-NAME */
			*((u16 *) pkt) = htons(NMRP_OPT_FILE_NAME);
			pkt += 2;

			/* Append the total length of NMRP option FILE-NAME */
			*((u16 *) pkt) = htons(STRING_TABLE_FILENAME_OPT_LEN);
			pkt += 2;

			/* Append the string table filename to FILE-NAME option value */
			int i;
			sprintf(NmrpStringTableFilename, "%s%02d", STRING_TABLE_FILENAME_PREFIX,\
				NmrpStringTableUpdateList[NmrpStringTableUpdateIndex]);
			for (i = 0; i < STRING_TABLE_FILENAME_LEN; i++) {
				*((u8 *) pkt) = NmrpStringTableFilename[i];
				pkt++;
			}
			printf("\nReq %s\n", NmrpStringTableFilename);
		/* No string table updates, or all string table updates finished.
		 * And received FW-UP option, upgrading firmware,
		 * add FILE-NAME option to TFTP-UL-REQ */
		} else {
			/* Append the total length to packet
			 * NMRP_HEADER_LEN for the length of "Reserved", "Code", "Identifier", "Length"
			 * STRING_TABLE_FILENAME_OPT_LEN for the length of "Options". */
			*((u16 *) pkt) = htons((NMRP_HEADER_LEN + FIRMWARE_FILENAME_OPT_LEN));
			pkt += 2;

			/* Append NMRP option type FILE-NAME */
			*((u16 *) pkt) = htons(NMRP_OPT_FILE_NAME);
			pkt += 2;

			/* Append the total length of NMRP option FILE-NAME for firmware*/
			*((u16 *) pkt) = htons(FIRMWARE_FILENAME_OPT_LEN);
			pkt += 2;

			/* Append the firmware filename to FILE-NAME option value */
			sprintf(NmrpFirmwareFilename, "%s\n", FIRMWARE_FILENAME);
			int i;
			for (i = 0; i < FIRMWARE_FILENAME_LEN; i++) {
				*((u8 *) pkt) = NmrpFirmwareFilename[i];
				pkt++;
			}
		}
		len = pkt - xp;
		(void)NetSendPacket((u8 *) NetTxPacket, eth_len + len);
		int update_table_num = NmrpStringTableUpdateList[NmrpStringTableUpdateIndex];
		if (NmrpSTUPOption == 1)
			UpgradeStringTableFromNmrpServer(update_table_num);
		else
			UpgradeFirmwareFromNmrpServer();
		break;
	case STATE_TFTPUPLOADING:
		printf("TFTP upload done\n");
		NmrpAliveTimerStart = get_timer(0);
		NmrpAliveTimerBase = NMRP_TIMEOUT_ACTIVE / 4;
		NmrpState = STATE_KEEP_ALIVE;
		break;
	case STATE_KEEP_ALIVE:
		printf("NMRP Send Keep alive REQ\n");
		workaround_ipq40xx_gmac_nmrp_hang_action();
		xp = pkt;
		*((u16 *) pkt) = 0;
		pkt += 2;
		*((u8 *) pkt) = (NMRP_CODE_KEEP_ALIVE_REQ);
		pkt++;
		*((u8 *) pkt) = 0;
		pkt++;
		*((u16 *) pkt) = htons(6);
		pkt += 2;
		len = pkt - xp;
		(void)NetSendPacket((u8 *) NetTxPacket, eth_len + len);
		NmrpAliveWaitACK = 1;
		break;
	case STATE_CLOSING:
		printf("NMRP Send Closing REQ\n");
		workaround_qca8337_gmac_nmrp_hang_action();
		workaround_ipq40xx_gmac_nmrp_hang_action();
		xp = pkt;
		*((u16 *) pkt) = 0;
		pkt += 2;
		*((u8 *) pkt) = (NMRP_CODE_CLOSE_REQ);
		pkt++;
		*((u8 *) pkt) = 0;
		pkt++;
		*((u16 *) pkt) = htons(6);
		pkt += 2;
		len = pkt - xp;
		NmrpSetTimeout(NMRP_CODE_CLOSE_ACK, (1 * CONFIG_SYS_HZ),
			       Nmrp_Closing_Timeout);
		(void)NetSendPacket((u8 *) NetTxPacket, eth_len + len);
		break;

	case STATE_CLOSED:
		board_reset_default();
#ifdef CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4
		char runcmd[256];
		printf ("boot_partition_set 1\n");
		snprintf(runcmd, sizeof(runcmd), "boot_partition_set 1");
		run_command(runcmd, 0);
#endif
		NmrptimeHandler=NULL;
		puts("\nNMRP is complete. Please switch OFF power.\n");

		Nmrp_Led_Flashing_Timeout();
		/* Unreachable */

		ctrlc();
		console_assign(stdout, "nulldev");
		console_assign(stderr, "nulldev");
		net_set_state(NETLOOP_SUCCESS);
		break;
	default:
		break;

	}

}

static void Nmrp_Listen_Timeout(void)
{
	if (++Nmrp_Listen_TimeoutCount > NMRP_TIMEOUT_LISTEN) {
		puts("\nRetry count exceeded; boot the image as usual\n");
		Nmrp_Listen_TimeoutCount = 0;
		ResetBootup_usual();
	} else {
		puts("T");
		NetSetTimeout(CONFIG_SYS_HZ, Nmrp_Listen_Timeout);
	}
}

static NMRP_PARSED_OPT *Nmrp_Parse(uchar * pkt, ushort optType)
{
	NMRP_PARSED_MSG *msg = (NMRP_PARSED_MSG *) pkt;
	NMRP_PARSED_OPT *opt, *optEnd;
	optEnd = &msg->options[msg->numOptions];
	for (opt = msg->options; opt != optEnd; opt++)
		if (opt->type == ntohs(optType))
			break;
	return msg->numOptions == 0 ? NULL : (opt == optEnd ? NULL : opt);
}

void NmrpSetTimeout(unchar proto, ulong iv, nmrp_thand_f * f)
{
	if (iv == 0) {
		NmrptimeHandler = (nmrp_thand_f *) 0;
		Nmrpproto = 0;
	} else {

		NmrptimeHandler = f;
		NmrptimeStart = get_timer(0);
		NmrptimeDelta = iv;
		Nmrpproto = proto;
	}
}
/*
  Function to parse the NMRP options inside packet.
  If all options are parsed correctly, it returns 0.
 */
static int Nmrp_Parse_Opts(uchar *pkt, NMRP_PARSED_MSG *nmrp_parsed)
{
	nmrp_t *nmrphdr= (nmrp_t*) pkt;
	NMRP_OPT *nmrp_opt;
	int remain_len, opt_index = 0;

	nmrp_parsed->reserved = nmrphdr->reserved;
	nmrp_parsed->code     = nmrphdr->code;
	nmrp_parsed->id       = nmrphdr->id;
	nmrp_parsed->length   = nmrphdr->length;

	remain_len = ntohs(nmrphdr->length) - NMRP_HDR_LEN;

	nmrp_opt = &nmrphdr->opt;
	while (remain_len > 0){
		memcpy(&nmrp_parsed->options[opt_index], nmrp_opt, ntohs(nmrp_opt->len));
		remain_len -= ntohs(nmrp_opt->len);
		nmrp_opt = ((uchar *)nmrp_opt) + ntohs(nmrp_opt->len);
		opt_index++;
	}
	nmrp_parsed->numOptions=opt_index;
	return remain_len;
}

void string_table_bitmask_check()
{
	int update_bit;

	/* find string tables need to be update, begin with smallest bit */
	for (update_bit = 0; update_bit < STRING_TABLE_BITMASK_LEN; update_bit++) {
		if ((NmrpStringTableBitmask & (1 << update_bit)) != 0) {
			//if bit 0 is set, update ST 1, ... etc
			NmrpStringTableUpdateList[NmrpStringTableUpdateCount] = update_bit + 1;
			NmrpStringTableUpdateCount++;
		}
	}
}

void NmrpHandler(uchar * pkt, unsigned dest, IPaddr_t src_ip, unsigned src,
                 unsigned type)
{
	nmrp_t *nmrphdr= (nmrp_t*) pkt;
	uchar proto;
	unchar *xp = pkt;
	int fwUpgrade;
	NMRP_PARSED_MSG nmrp_parsed;
	NMRP_PARSED_OPT *opt;
	proto = nmrphdr->code;

	if (type!=PROT_NMRP)
		return;

	/* check for timeout,and run the timeout handler
	   if we have one
	 */

	if (NmrptimeHandler && ((get_timer(0) - NmrptimeStart) > NmrptimeDelta)
	    && (proto != Nmrpproto)) {
		nmrp_thand_f *x;
		x = NmrptimeHandler;
		NmrptimeHandler = (nmrp_thand_f *) 0;
		(*x) ();
	}

	/*
	   Check if Reserved field is zero. Per the specification, the reserved
	   must be all zero in a valid NMRP packet.
	 */
	if (nmrphdr->reserved != 0){
		return;
	}
	memset(&nmrp_parsed, 0, sizeof(NMRP_PARSED_MSG));

	/*
	   Parse the options inside the packet and save it into nmrp_parsed for
	   future reference.
	 */
	if (Nmrp_Parse_Opts(pkt, &nmrp_parsed) != 0){
		/* Some wrong inside the packet, just discard it */
		return;
	}

	NmrpBlock = proto;

	// ignore same packet
	if (NmrpBlock == NmrpLastBlock)
		return;
	NmrpLastBlock = NmrpBlock;

	switch (proto) {
	case NMRP_CODE_ADVERTISE:	/*listening state * */
		if (NmrpState == 0) {
			/*
			   Check if we get the MAGIC-NO option and the content is match
			   with the MAGICNO.
			 */
			if ((opt = Nmrp_Parse(&nmrp_parsed, NMRP_OPT_MAGIC_NO)) != NULL){
				int opt_hdr_len = sizeof(opt->type) + sizeof(opt->len);
				if (memcmp(opt->value.magicno, MAGICNO, ntohs(opt->len) - opt_hdr_len) == 0){
					NmrpState = STATE_LISTENING;
					board_test_led(0);
					printf("\nNMRP CONFIGING");
					NmrpSend();
				}
			}
		}
		break;
	case NMRP_CODE_CONF_ACK:
		if (NmrpState == STATE_LISTENING) {
			/*
			   If there is no DEV-IP option inside the packet, it must be
			   something wrong in the packet, so just ignore this packet
			   without any action taken.
			 */
			if ((opt = Nmrp_Parse(&nmrp_parsed, NMRP_OPT_DEV_IP)) != NULL){
				memcpy(NetOurTftpIP, opt->value.ip.addr,IP_ADDR_LEN);
				/* Do we need the subnet mask? */
				memcpy(&NmrpOuripSubnetMask, opt->value.ip.mask,IP_ADDR_LEN);
				/*
				   FW-UP option is optional for CONF-ACK and it has no effect no
				   matter what is the content of this option, so we just skip the
				   process of this option for now, and will add it back when
				   this option is defined as mandatory.
				   The process for FW-UP would be similar as the action taken for
				   DEV-IP and MAGIC-NO.
				 */

#if defined(REGION_NUMBER_OFFSET) && defined(REGION_NUMBER_LENGTH)
				/*When NMRP Client get CONF-ACK with DEV-REGION option*/
				if ((opt = Nmrp_Parse(&nmrp_parsed, NMRP_OPT_DEV_REGION)) != NULL) {
					/* Save DEV-REGION value to board */
					printf("Get DEV-REGION option, value:0x%04x\n", opt->value.region);
					NmrpDevRegionOption = ntohs(opt->value.region);
					printf("Write Region Number 0x%04x to board\n", NmrpDevRegionOption);
					set_region(NmrpDevRegionOption);
				}
#endif
				/*Check if NMRP Client get CONF-ACK with FW-UP option*/
				if ((opt = Nmrp_Parse(&nmrp_parsed, NMRP_OPT_FW_UP)) != NULL) {
					printf("\nRecv FW-UP option\n");
					NmrpFwUPOption = 1;
				} else {
					printf("\nNo FW-UP option\n");
					NmrpFwUPOption = 0;
				}

				/*When NMRP Client get CONF-ACK with ST-UP option*/
				if ((opt = Nmrp_Parse(&nmrp_parsed, NMRP_OPT_ST_UP)) != NULL) {
					printf("\nRecv ST-UP option\n");
					NmrpSTUPOption = 1;
					/* Reset string tables' update related variables. */
					NmrpStringTableUpdateCount = 0;
					NmrpStringTableUpdateIndex = 0;
					memset(NmrpStringTableUpdateList, 0,\
						sizeof(NmrpStringTableUpdateList));

					/* Save from network byte-order to host byte-order. */
					NmrpStringTableBitmask = ntohl(opt->value.string_table_bitmask);

					string_table_bitmask_check();
					printf("\nTotal %d String Table need updating\n",\
						NmrpStringTableUpdateCount);
				} else {
					printf("\nNo ST-UP option\n");
					NmrpSTUPOption = 0;
				}
				if (NmrpFwUPOption == 0 && NmrpSTUPOption == 0) {
					NmrpState = STATE_CLOSING;
					printf("\nNo firmware update, nor string table update\n");
					NmrpSend();
				} else {
					NmrpState = STATE_CONFIGING;
					printf("\nNMRP WAITING FOR UPLOAD FIRMWARE or STRING TABLES!\n");
					NmrpSend();
				}
			}else
				break;
		}
		break;
	case NMRP_CODE_KEEP_ALIVE_ACK:
		if (NmrpState == STATE_KEEP_ALIVE) {
			if (NmrpAliveWaitACK == 1) {
				NmrpAliveTimerBase += NMRP_TIMEOUT_ACTIVE / 4;
				NmrpAliveWaitACK = 0;
			}
		}
		break;
	case NMRP_CODE_CLOSE_ACK:
		if (NmrpState == STATE_CLOSING) {
			NmrpState = STATE_CLOSED;
			printf("\nNMRP CLOSED");
			NmrpSend();
		}
		break;
	default:
		break;
	}

}

void NmrpStart(void)
{
	printf("\n Client starts...[Listening] for ADVERTISE...");

	NetSetTimeout(CONFIG_SYS_HZ / 10, Nmrp_Listen_Timeout);
	net_set_udp_handler(NmrpHandler);

	NmrpState = 0;
	Nmrp_Listen_TimeoutCount = 0;
	memset(NmrpClientEther, 0, 6);
	NmrpClientIP = 0;
}
