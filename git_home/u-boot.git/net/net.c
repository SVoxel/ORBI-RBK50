/*
 *	Copied from Linux Monitor (LiMon) - Networking.
 *
 *	Copyright 1994 - 2000 Neil Russell.
 *	(See License)
 *	Copyright 2000 Roland Borde
 *	Copyright 2000 Paolo Scaffardi
 *	Copyright 2000-2002 Wolfgang Denk, wd@denx.de
 */

/*
 * General Desription:
 *
 * The user interface supports commands for BOOTP, RARP, and TFTP.
 * Also, we support ARP internally. Depending on available data,
 * these interact as follows:
 *
 * BOOTP:
 *
 *	Prerequisites:	- own ethernet address
 *	We want:	- own IP address
 *			- TFTP server IP address
 *			- name of bootfile
 *	Next step:	ARP
 *
 * LINK_LOCAL:
 *
 *	Prerequisites:	- own ethernet address
 *	We want:	- own IP address
 *	Next step:	ARP
 *
 * RARP:
 *
 *	Prerequisites:	- own ethernet address
 *	We want:	- own IP address
 *			- TFTP server IP address
 *	Next step:	ARP
 *
 * ARP:
 *
 *	Prerequisites:	- own ethernet address
 *			- own IP address
 *			- TFTP server IP address
 *	We want:	- TFTP server ethernet address
 *	Next step:	TFTP
 *
 * DHCP:
 *
 *     Prerequisites:	- own ethernet address
 *     We want:		- IP, Netmask, ServerIP, Gateway IP
 *			- bootfilename, lease time
 *     Next step:	- TFTP
 *
 * TFTP:
 *
 *	Prerequisites:	- own ethernet address
 *			- own IP address
 *			- TFTP server IP address
 *			- TFTP server ethernet address
 *			- name of bootfile (if unknown, we use a default name
 *			  derived from our own IP address)
 *	We want:	- load the boot file
 *	Next step:	none
 *
 * NFS:
 *
 *	Prerequisites:	- own ethernet address
 *			- own IP address
 *			- name of bootfile (if unknown, we use a default name
 *			  derived from our own IP address)
 *	We want:	- load the boot file
 *	Next step:	none
 *
 * SNTP:
 *
 *	Prerequisites:	- own ethernet address
 *			- own IP address
 *	We want:	- network time
 *	Next step:	none
 */


#include <common.h>
#include <command.h>
#include <net.h>
#if defined(CONFIG_STATUS_LED)
#include <miiphy.h>
#include <status_led.h>
#endif
#include <watchdog.h>
#include <linux/compiler.h>
#include "arp.h"
#include "bootp.h"
#include "cdp.h"
#if defined(CONFIG_CMD_DNS)
#include "dns.h"
#endif
#include "link_local.h"
#include "nfs.h"
#include "nmrp.h"
#include "ping.h"
#include "rarp.h"
#if defined(CONFIG_CMD_SNTP)
#include "sntp.h"
#endif
#include "tftp.h"
#include <errno.h>

DECLARE_GLOBAL_DATA_PTR;

/** BOOTP EXTENTIONS **/

/* Our subnet mask (0=unknown) */
IPaddr_t	NetOurSubnetMask;
/* Our gateways IP address */
IPaddr_t	NetOurGatewayIP;
/* Our DNS IP address */
IPaddr_t	NetOurDNSIP;
#if defined(CONFIG_BOOTP_DNS2)
/* Our 2nd DNS IP address */
IPaddr_t	NetOurDNS2IP;
#endif
/* Our NIS domain */
char		NetOurNISDomain[32] = {0,};
/* Our hostname */
char		NetOurHostName[32] = {0,};
/* Our bootpath */
char		NetOurRootPath[64] = {0,};
/* Our bootfile size in blocks */
ushort		NetBootFileSize;

#ifdef CONFIG_MCAST_TFTP	/* Multicast TFTP */
IPaddr_t Mcast_addr;
#endif

/** END OF BOOTP EXTENTIONS **/

/* The actual transferred size of the bootfile (in bytes) */
ulong		NetBootFileXferSize;
/* Our ethernet address */
uchar		NetOurEther[6];
/* Boot server enet address */
uchar		NetServerEther[6];
/* Our IP addr (0 = unknown) */
IPaddr_t	NetOurIP;
/* Server IP addr (0 = unknown) */
IPaddr_t	NetServerIP;
/* Current receive packet */
uchar *NetRxPacket;
/* Current rx packet length */
int		NetRxPacketLen;
/* IP packet ID */
unsigned	NetIPID;
/* Ethernet bcast address */
uchar		NetBcastAddr[6] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
uchar		NetEtherNullAddr[6];
#ifdef CONFIG_API
void		(*push_packet)(void *, int len) = 0;
#endif
/* Network loop state */
enum net_loop_state net_state;
/* Tried all network devices */
int		NetRestartWrap;
/* Network loop restarted */
static int	NetRestarted;
/* At least one device configured */
static int	NetDevExists;

/* XXX in both little & big endian machines 0xFFFF == ntohs(-1) */
/* default is without VLAN */
ushort		NetOurVLAN = 0xFFFF;
/* ditto */
ushort		NetOurNativeVLAN = 0xFFFF;

uchar NetOurTftpIP[4] = { 192, 168, 1, 1 };
int NetRunTftpServer = 0;
uchar TftpClientEther[6] = { 0, 0, 0, 0, 0, 0};
IPaddr_t TftpClientIP = 0;
#ifdef DNI_NAND
#include <nand.h>
#else
#ifndef CONFIG_SYS_NO_FLASH
extern flash_info_t flash_info[];
#endif
#endif
#include <dni_common.h>

/* Boot File name */
char		BootFile[128];

#if defined(CONFIG_CMD_SNTP)
/* NTP server IP address */
IPaddr_t	NetNtpServerIP;
/* offset time from UTC */
int		NetTimeOffset;
#endif

uchar PktBuf[(PKTBUFSRX+1) * PKTSIZE_ALIGN + PKTALIGN];

/* Receive packet */
uchar *NetRxPackets[PKTBUFSRX];

/* Current UDP RX packet handler */
static rxhand_f *udp_packet_handler;
/* Current ARP RX packet handler */
static rxhand_f *arp_packet_handler;
#ifdef CONFIG_CMD_TFTPPUT
/* Current ICMP rx handler */
static rxhand_icmp_f *packet_icmp_handler;
#endif
/* Current timeout handler */
thand_f *timeHandler;
/* Time base value */
ulong	timeStart;
/* Current timeout value */
ulong	timeDelta;
/* THE transmit packet */
uchar *NetTxPacket;

static int net_check_prereq(enum proto_t protocol);

static int NetTryCount;

/**********************************************************************/

/*
 * Check if autoload is enabled. If so, use either NFS or TFTP to download
 * the boot file.
 */
void net_auto_load(void)
{
	const char *s = getenv("autoload");

	if (s != NULL) {
		if (*s == 'n') {
			/*
			 * Just use BOOTP/RARP to configure system;
			 * Do not use TFTP to load the bootfile.
			 */
			net_set_state(NETLOOP_SUCCESS);
			return;
		}
#if defined(CONFIG_CMD_NFS)
		if (strcmp(s, "NFS") == 0) {
			/*
			 * Use NFS to load the bootfile.
			 */
			NfsStart();
			return;
		}
#endif
	}
	TftpStart(TFTPGET);
}

static void NetInitLoop(void)
{
	static int env_changed_id;
	int env_id = get_env_id();

	/* update only when the environment has changed */
	if (env_changed_id != env_id) {
		NetOurIP = getenv_IPaddr("ipaddr");
		NetOurGatewayIP = getenv_IPaddr("gatewayip");
		NetOurSubnetMask = getenv_IPaddr("netmask");
		NetServerIP = getenv_IPaddr("serverip");
		NetOurNativeVLAN = getenv_VLAN("nvlan");
		NetOurVLAN = getenv_VLAN("vlan");
#if defined(CONFIG_CMD_DNS)
		NetOurDNSIP = getenv_IPaddr("dnsip");
#endif
		env_changed_id = env_id;
	}
	memcpy(NetOurEther, eth_get_dev()->enetaddr, 6);

	return;
}

static void net_clear_handlers(void)
{
	net_set_udp_handler(NULL);
	net_set_arp_handler(NULL);
	NetSetTimeout(0, NULL);
}

static void net_cleanup_loop(void)
{
	net_clear_handlers();
}

void net_init(void)
{
	static int first_call = 1;

	if (first_call) {
		/*
		 *	Setup packet buffers, aligned correctly.
		 */
		int i;

		NetTxPacket = &PktBuf[0] + (PKTALIGN - 1);
		NetTxPacket -= (ulong)NetTxPacket % PKTALIGN;
		for (i = 0; i < PKTBUFSRX; i++)
			NetRxPackets[i] = NetTxPacket + (i + 1) * PKTSIZE_ALIGN;

		ArpInit();
		net_clear_handlers();

		/* Only need to setup buffer pointers once. */
		first_call = 0;
	}

	NetInitLoop();
}

/**********************************************************************/
/*
 *	Main network processing loop.
 */

int NetLoop(enum proto_t protocol)
{
	bd_t *bd = gd->bd;
	int ret = -1;

	NetRestarted = 0;
	NetDevExists = 0;
	NetTryCount = 1;
	debug_cond(DEBUG_INT_STATE, "--- NetLoop Entry\n");

	bootstage_mark_name(BOOTSTAGE_ID_ETH_START, "eth_start");
	net_init();
	eth_halt();
#if defined(CONFIG_HW29764958P0P128P512P3X3P4X4) || \
    defined(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) || \
    defined(CONFIG_HW29765257P0P128P256P3X3P4X4) || \
    defined(CONFIG_HW29764958P0P128P512P4X4P4X4PXDSL)
        setenv("ethact", "eth1");
#else
	/* Set eth0 as primary ethernet interface to LAN interface*/
        setenv("ethact", "eth0");
#endif
	eth_set_current();
	if (eth_init(bd) < 0) {
		eth_halt();
		return -1;
	}

restart:
	net_set_state(NETLOOP_CONTINUE);

	/*
	 *	Start the ball rolling with the given start function.  From
	 *	here on, this code is a state machine driven by received
	 *	packets and timer events.
	 */
	debug_cond(DEBUG_INT_STATE, "--- NetLoop Init\n");
	NetInitLoop();

	switch (net_check_prereq(protocol)) {
	case 1:
		/* network not configured */
		eth_halt();
		return -1;

	case 2:
		/* network device not configured */
		break;

	case 0:
		NetDevExists = 1;
		NetBootFileXferSize = 0;
		switch (protocol) {
		case TFTPGET:
#ifdef CONFIG_CMD_TFTPPUT
		case TFTPPUT:
#endif
			/* always use ARP to get server ethernet address */
			if(NetRunTftpServer)
			{
				if (NmrpState != 0) {
					NetServerIP = 1;
					NetCopyIP(&NetOurIP, NetOurTftpIP);
					NetOurGatewayIP = 0;
				}
				TftpServerStart();
			}
			else
			TftpStart(protocol);
			break;
		case NMRP:
			NmrpStart();
			break;

#ifdef CONFIG_CMD_TFTPSRV
		case TFTPSRV:
			TftpStartServer();
			break;
#endif
#if defined(CONFIG_CMD_DHCP)
		case DHCP:
			BootpTry = 0;
			NetOurIP = 0;
			DhcpRequest();		/* Basically same as BOOTP */
			break;
#endif

		case BOOTP:
			BootpTry = 0;
			NetOurIP = 0;
			BootpRequest();
			break;

#if defined(CONFIG_CMD_RARP)
		case RARP:
			RarpTry = 0;
			NetOurIP = 0;
			RarpRequest();
			break;
#endif
#if defined(CONFIG_CMD_PING)
		case PING:
			ping_start();
			break;
#endif
#if defined(CONFIG_CMD_NFS)
		case NFS:
			NfsStart();
			break;
#endif
#if defined(CONFIG_CMD_CDP)
		case CDP:
			CDPStart();
			break;
#endif
#ifdef CONFIG_NETCONSOLE
		case NETCONS:
			NcStart();
			break;
#endif
#if defined(CONFIG_CMD_SNTP)
		case SNTP:
			SntpStart();
			break;
#endif
#if defined(CONFIG_CMD_DNS)
		case DNS:
			DnsStart();
			break;
#endif
#if defined(CONFIG_CMD_LINK_LOCAL)
		case LINKLOCAL:
			link_local_start();
			break;
#endif
		default:
			break;
		}

		break;
	}

#if defined(CONFIG_MII) || defined(CONFIG_CMD_MII)
#if	defined(CONFIG_SYS_FAULT_ECHO_LINK_DOWN)	&& \
	defined(CONFIG_STATUS_LED)			&& \
	defined(STATUS_LED_RED)
	/*
	 * Echo the inverted link state to the fault LED.
	 */
	if (miiphy_link(eth_get_dev()->name, CONFIG_SYS_FAULT_MII_ADDR))
		status_led_set(STATUS_LED_RED, STATUS_LED_OFF);
	else
		status_led_set(STATUS_LED_RED, STATUS_LED_ON);
#endif /* CONFIG_SYS_FAULT_ECHO_LINK_DOWN, ... */
#endif /* CONFIG_MII, ... */

	/*
	 *	Main packet reception loop.  Loop receiving packets until
	 *	someone sets `net_state' to a state that terminates.
	 */
skip_netloop:
	for (;;) {
		WATCHDOG_RESET();
#ifdef CONFIG_SHOW_ACTIVITY
		show_activity(1);
#endif
		/*
		 *	Check the ethernet for a new packet.  The ethernet
		 *	receive routine will process it.
		 */
		eth_rx();

		/*
		 *	Abort if ctrl-c was pressed.
		 */
		if (ctrlc()) {
			/* cancel any ARP that may not have completed */
			NetArpWaitPacketIP = 0;

			net_cleanup_loop();
			eth_halt();
			puts("\nAbort\n");
			/* include a debug print as well incase the debug
			   messages are directed to stderr */
			debug_cond(DEBUG_INT_STATE, "--- NetLoop Abort!\n");
			goto done;
		}

		ArpTimeoutCheck();

		/*
		 *	Check for a timeout, and run the timeout handler
		 *	if we have one.
		 */
		if (timeHandler && ((get_timer(0) - timeStart) > timeDelta)) {
			thand_f *x;

#if defined(CONFIG_MII) || defined(CONFIG_CMD_MII)
#if	defined(CONFIG_SYS_FAULT_ECHO_LINK_DOWN)	&& \
	defined(CONFIG_STATUS_LED)			&& \
	defined(STATUS_LED_RED)
			/*
			 * Echo the inverted link state to the fault LED.
			 */
			if (miiphy_link(eth_get_dev()->name,
				       CONFIG_SYS_FAULT_MII_ADDR)) {
				status_led_set(STATUS_LED_RED, STATUS_LED_OFF);
			} else {
				status_led_set(STATUS_LED_RED, STATUS_LED_ON);
			}
#endif /* CONFIG_SYS_FAULT_ECHO_LINK_DOWN, ... */
#endif /* CONFIG_MII, ... */
			debug_cond(DEBUG_INT_STATE, "--- NetLoop timeout\n");
			x = timeHandler;
			timeHandler = (thand_f *)0;
			(*x)();
		}


		switch (net_state) {

		case NETLOOP_RESTART:
			NetRestarted = 1;
			goto restart;

		case NETLOOP_SUCCESS:
			if (NmrpState == STATE_CLOSING)
				goto skip_netloop;
			net_cleanup_loop();
			if (NetBootFileXferSize > 0) {
				char buf[20];
				printf("Bytes transferred = %ld (%lx hex)\n",
					NetBootFileXferSize,
					NetBootFileXferSize);
				sprintf(buf, "%lX", NetBootFileXferSize);
				setenv("filesize", buf);

				sprintf(buf, "%lX", (unsigned long)load_addr);
				setenv("fileaddr", buf);
			}
#if !defined(CONFIG_HW29764958P0P128P512P3X3P4X4) && \
    !defined(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) && \
    !defined(CONFIG_HW29765257P0P128P256P3X3P4X4) && \
    !defined(CONFIG_HW29764958P0P128P512P4X4P4X4PXDSL)
			eth_halt();
#endif
			ret = NetBootFileXferSize;
			debug_cond(DEBUG_INT_STATE, "--- NetLoop Success!\n");
			goto done;

		case NETLOOP_FAIL:
			net_cleanup_loop();
			debug_cond(DEBUG_INT_STATE, "--- NetLoop Fail!\n");
			goto done;

		case NETLOOP_CONTINUE:
			continue;
		}
	}

done:
#ifdef CONFIG_CMD_TFTPPUT
	/* Clear out the handlers */
	net_set_udp_handler(NULL);
	net_set_icmp_handler(NULL);
#endif
	return ret;
}

/**********************************************************************/

static void
startAgainTimeout(void)
{
	net_set_state(NETLOOP_RESTART);
}

void NetStartAgain(void)
{
	char *nretry;
	int retry_forever = 0;
	unsigned long retrycnt = 0;

	nretry = getenv("netretry");
	if (nretry) {
		if (!strcmp(nretry, "yes"))
			retry_forever = 1;
		else if (!strcmp(nretry, "no"))
			retrycnt = 0;
		else if (!strcmp(nretry, "once"))
			retrycnt = 1;
		else
			retrycnt = simple_strtoul(nretry, NULL, 0);
	} else
		retry_forever = 1;

	if ((!retry_forever) && (NetTryCount >= retrycnt)) {
		eth_halt();
		net_set_state(NETLOOP_FAIL);
		return;
	}

	NetTryCount++;

	eth_halt();
#if !defined(CONFIG_NET_DO_NOT_TRY_ANOTHER)
	eth_try_another(!NetRestarted);
#endif
	eth_init(gd->bd);
	if (NetRestartWrap) {
		NetRestartWrap = 0;
		if (NetDevExists) {
			NetSetTimeout(10000UL, startAgainTimeout);
			net_set_udp_handler(NULL);
		} else {
			net_set_state(NETLOOP_FAIL);
		}
	} else {
		net_set_state(NETLOOP_RESTART);
	}
}

/**********************************************************************/
/*
 *	Miscelaneous bits.
 */

static void dummy_handler(uchar *pkt, unsigned dport,
			IPaddr_t sip, unsigned sport,
			unsigned len)
{
}

rxhand_f *net_get_udp_handler(void)
{
	return udp_packet_handler;
}

void net_set_udp_handler(rxhand_f *f)
{
	debug_cond(DEBUG_INT_STATE, "--- NetLoop UDP handler set (%p)\n", f);
	if (f == NULL)
		udp_packet_handler = dummy_handler;
	else
		udp_packet_handler = f;
}

rxhand_f *net_get_arp_handler(void)
{
	return arp_packet_handler;
}

void net_set_arp_handler(rxhand_f *f)
{
	debug_cond(DEBUG_INT_STATE, "--- NetLoop ARP handler set (%p)\n", f);
	if (f == NULL)
		arp_packet_handler = dummy_handler;
	else
		arp_packet_handler = f;
}

#ifdef CONFIG_CMD_TFTPPUT
void net_set_icmp_handler(rxhand_icmp_f *f)
{
	packet_icmp_handler = f;
}
#endif

void
NetSetTimeout(ulong iv, thand_f *f)
{
	if (iv == 0) {
		debug_cond(DEBUG_INT_STATE,
			"--- NetLoop timeout handler cancelled\n");
		timeHandler = (thand_f *)0;
	} else {
		debug_cond(DEBUG_INT_STATE,
			"--- NetLoop timeout handler set (%p)\n", f);
		timeHandler = f;
		timeStart = get_timer(0);
		timeDelta = iv;
	}
}

int NetSendUDPPacket(uchar *ether, IPaddr_t dest, int dport, int sport,
		int payload_len)
{
	uchar *pkt;
	int eth_hdr_size;
	int pkt_hdr_size;

	/* make sure the NetTxPacket is initialized (NetInit() was called) */
	assert(NetTxPacket != NULL);
	if (NetTxPacket == NULL)
		return -1;

	/* convert to new style broadcast */
	if (dest == 0)
		dest = 0xFFFFFFFF;

	/* if broadcast, make the ether address a broadcast and don't do ARP */
	if (dest == 0xFFFFFFFF)
		ether = NetBcastAddr;

	pkt = (uchar *)NetTxPacket;

	eth_hdr_size = NetSetEther(pkt, ether, PROT_IP);
	pkt += eth_hdr_size;
	net_set_udp_header(pkt, dest, dport, sport, payload_len);
	pkt_hdr_size = eth_hdr_size + IP_UDP_HDR_SIZE;

	/* if MAC address was not discovered yet, do an ARP request */
	if (memcmp(ether, NetEtherNullAddr, 6) == 0) {
		debug_cond(DEBUG_DEV_PKT, "sending ARP for %pI4\n", &dest);

		/* save the ip and eth addr for the packet to send after arp */
		NetArpWaitPacketIP = dest;
		NetArpWaitPacketMAC = ether;

		/* size of the waiting packet */
		NetArpWaitTxPacketSize = pkt_hdr_size + payload_len;

		/* and do the ARP request */
		NetArpWaitTry = 1;
		NetArpWaitTimerStart = get_timer(0);
		ArpRequest();
		return 1;	/* waiting */
	} else {
		debug_cond(DEBUG_DEV_PKT, "sending UDP to %pI4/%pM\n",
			&dest, ether);
		NetSendPacket(NetTxPacket, pkt_hdr_size + payload_len);
		return 0;	/* transmitted */
	}
}

#ifdef CONFIG_IP_DEFRAG
/*
 * This function collects fragments in a single packet, according
 * to the algorithm in RFC815. It returns NULL or the pointer to
 * a complete packet, in static storage
 */
#ifndef CONFIG_NET_MAXDEFRAG
#define CONFIG_NET_MAXDEFRAG 16384
#endif
/*
 * MAXDEFRAG, above, is chosen in the config file and  is real data
 * so we need to add the NFS overhead, which is more than TFTP.
 * To use sizeof in the internal unnamed structures, we need a real
 * instance (can't do "sizeof(struct rpc_t.u.reply))", unfortunately).
 * The compiler doesn't complain nor allocates the actual structure
 */
static struct rpc_t rpc_specimen;
#define IP_PKTSIZE (CONFIG_NET_MAXDEFRAG + sizeof(rpc_specimen.u.reply))

#define IP_MAXUDP (IP_PKTSIZE - IP_HDR_SIZE)

/*
 * this is the packet being assembled, either data or frag control.
 * Fragments go by 8 bytes, so this union must be 8 bytes long
 */
struct hole {
	/* first_byte is address of this structure */
	u16 last_byte;	/* last byte in this hole + 1 (begin of next hole) */
	u16 next_hole;	/* index of next (in 8-b blocks), 0 == none */
	u16 prev_hole;	/* index of prev, 0 == none */
	u16 unused;
};

static struct ip_udp_hdr *__NetDefragment(struct ip_udp_hdr *ip, int *lenp)
{
	static uchar pkt_buff[IP_PKTSIZE] __aligned(PKTALIGN);
	static u16 first_hole, total_len;
	struct hole *payload, *thisfrag, *h, *newh;
	struct ip_udp_hdr *localip = (struct ip_udp_hdr *)pkt_buff;
	uchar *indata = (uchar *)ip;
	int offset8, start, len, done = 0;
	u16 ip_off = ntohs(ip->ip_off);

	/* payload starts after IP header, this fragment is in there */
	payload = (struct hole *)(pkt_buff + IP_HDR_SIZE);
	offset8 =  (ip_off & IP_OFFS);
	thisfrag = payload + offset8;
	start = offset8 * 8;
	len = ntohs(ip->ip_len) - IP_HDR_SIZE;

	if (start + len > IP_MAXUDP) /* fragment extends too far */
		return NULL;

	if (!total_len || localip->ip_id != ip->ip_id) {
		/* new (or different) packet, reset structs */
		total_len = 0xffff;
		payload[0].last_byte = ~0;
		payload[0].next_hole = 0;
		payload[0].prev_hole = 0;
		first_hole = 0;
		/* any IP header will work, copy the first we received */
		memcpy(localip, ip, IP_HDR_SIZE);
	}

	/*
	 * What follows is the reassembly algorithm. We use the payload
	 * array as a linked list of hole descriptors, as each hole starts
	 * at a multiple of 8 bytes. However, last byte can be whatever value,
	 * so it is represented as byte count, not as 8-byte blocks.
	 */

	h = payload + first_hole;
	while (h->last_byte < start) {
		if (!h->next_hole) {
			/* no hole that far away */
			return NULL;
		}
		h = payload + h->next_hole;
	}

	/* last fragment may be 1..7 bytes, the "+7" forces acceptance */
	if (offset8 + ((len + 7) / 8) <= h - payload) {
		/* no overlap with holes (dup fragment?) */
		return NULL;
	}

	if (!(ip_off & IP_FLAGS_MFRAG)) {
		/* no more fragmentss: truncate this (last) hole */
		total_len = start + len;
		h->last_byte = start + len;
	}

	/*
	 * There is some overlap: fix the hole list. This code doesn't
	 * deal with a fragment that overlaps with two different holes
	 * (thus being a superset of a previously-received fragment).
	 */

	if ((h >= thisfrag) && (h->last_byte <= start + len)) {
		/* complete overlap with hole: remove hole */
		if (!h->prev_hole && !h->next_hole) {
			/* last remaining hole */
			done = 1;
		} else if (!h->prev_hole) {
			/* first hole */
			first_hole = h->next_hole;
			payload[h->next_hole].prev_hole = 0;
		} else if (!h->next_hole) {
			/* last hole */
			payload[h->prev_hole].next_hole = 0;
		} else {
			/* in the middle of the list */
			payload[h->next_hole].prev_hole = h->prev_hole;
			payload[h->prev_hole].next_hole = h->next_hole;
		}

	} else if (h->last_byte <= start + len) {
		/* overlaps with final part of the hole: shorten this hole */
		h->last_byte = start;

	} else if (h >= thisfrag) {
		/* overlaps with initial part of the hole: move this hole */
		newh = thisfrag + (len / 8);
		*newh = *h;
		h = newh;
		if (h->next_hole)
			payload[h->next_hole].prev_hole = (h - payload);
		if (h->prev_hole)
			payload[h->prev_hole].next_hole = (h - payload);
		else
			first_hole = (h - payload);

	} else {
		/* fragment sits in the middle: split the hole */
		newh = thisfrag + (len / 8);
		*newh = *h;
		h->last_byte = start;
		h->next_hole = (newh - payload);
		newh->prev_hole = (h - payload);
		if (newh->next_hole)
			payload[newh->next_hole].prev_hole = (newh - payload);
	}

	/* finally copy this fragment and possibly return whole packet */
	memcpy((uchar *)thisfrag, indata + IP_HDR_SIZE, len);
	if (!done)
		return NULL;

	localip->ip_len = htons(total_len);
	*lenp = total_len + IP_HDR_SIZE;
	return localip;
}

static inline struct ip_udp_hdr *NetDefragment(struct ip_udp_hdr *ip, int *lenp)
{
	u16 ip_off = ntohs(ip->ip_off);
	if (!(ip_off & (IP_OFFS | IP_FLAGS_MFRAG)))
		return ip; /* not a fragment */
	return __NetDefragment(ip, lenp);
}

#else /* !CONFIG_IP_DEFRAG */

static inline struct ip_udp_hdr *NetDefragment(struct ip_udp_hdr *ip, int *lenp)
{
	u16 ip_off = ntohs(ip->ip_off);
	if (!(ip_off & (IP_OFFS | IP_FLAGS_MFRAG)))
		return ip; /* not a fragment */
	return NULL;
}
#endif

/**
 * Receive an ICMP packet. We deal with REDIRECT and PING here, and silently
 * drop others.
 *
 * @parma ip	IP packet containing the ICMP
 */
static void receive_icmp(struct ip_udp_hdr *ip, int len,
			IPaddr_t src_ip, struct ethernet_hdr *et)
{
	struct icmp_hdr *icmph = (struct icmp_hdr *)&ip->udp_src;

	switch (icmph->type) {
	case ICMP_REDIRECT:
		if (icmph->code != ICMP_REDIR_HOST)
			return;
		printf(" ICMP Host Redirect to %pI4 ",
			&icmph->un.gateway);
		break;
	default:
#if defined(CONFIG_CMD_PING)
		ping_receive(et, ip, len);
#endif
#ifdef CONFIG_CMD_TFTPPUT
		if (packet_icmp_handler)
			packet_icmp_handler(icmph->type, icmph->code,
				ntohs(ip->udp_dst), src_ip, ntohs(ip->udp_src),
				icmph->un.data, ntohs(ip->udp_len));
#endif
		break;
	}
}

void
NetReceive(uchar *inpkt, int len)
{
	struct ethernet_hdr *et;
	struct ip_udp_hdr *ip;
	IPaddr_t dst_ip;
	IPaddr_t src_ip;
	int eth_proto;
#if defined(CONFIG_CMD_CDP)
	int iscdp;
#endif
	ushort cti = 0, vlanid = VLAN_NONE, myvlanid, mynvlanid;

	debug_cond(DEBUG_NET_PKT, "packet received\n");

	NetRxPacket = inpkt;
	NetRxPacketLen = len;
	et = (struct ethernet_hdr *)inpkt;

	/* too small packet? */
	if (len < ETHER_HDR_SIZE)
		return;

#ifdef CONFIG_API
	if (push_packet) {
		(*push_packet)(inpkt, len);
		return;
	}
#endif

#if defined(CONFIG_CMD_CDP)
	/* keep track if packet is CDP */
	iscdp = is_cdp_packet(et->et_dest);
#endif

	myvlanid = ntohs(NetOurVLAN);
	if (myvlanid == (ushort)-1)
		myvlanid = VLAN_NONE;
	mynvlanid = ntohs(NetOurNativeVLAN);
	if (mynvlanid == (ushort)-1)
		mynvlanid = VLAN_NONE;

	eth_proto = ntohs(et->et_protlen);

	if (eth_proto < 1514) {
		struct e802_hdr *et802 = (struct e802_hdr *)et;
		/*
		 *	Got a 802.2 packet.  Check the other protocol field.
		 *	XXX VLAN over 802.2+SNAP not implemented!
		 */
		eth_proto = ntohs(et802->et_prot);

		ip = (struct ip_udp_hdr *)(inpkt + E802_HDR_SIZE);
		len -= E802_HDR_SIZE;

	} else if (eth_proto != PROT_VLAN) {	/* normal packet */
		ip = (struct ip_udp_hdr *)(inpkt + ETHER_HDR_SIZE);
		len -= ETHER_HDR_SIZE;

	} else {			/* VLAN packet */
		struct vlan_ethernet_hdr *vet =
			(struct vlan_ethernet_hdr *)et;

		debug_cond(DEBUG_NET_PKT, "VLAN packet received\n");

		/* too small packet? */
		if (len < VLAN_ETHER_HDR_SIZE)
			return;

		/* if no VLAN active */
		if ((ntohs(NetOurVLAN) & VLAN_IDMASK) == VLAN_NONE
#if defined(CONFIG_CMD_CDP)
				&& iscdp == 0
#endif
				)
			return;

		cti = ntohs(vet->vet_tag);
		vlanid = cti & VLAN_IDMASK;
		eth_proto = ntohs(vet->vet_type);

		ip = (struct ip_udp_hdr *)(inpkt + VLAN_ETHER_HDR_SIZE);
		len -= VLAN_ETHER_HDR_SIZE;
	}

	debug_cond(DEBUG_NET_PKT, "Receive from protocol 0x%x\n", eth_proto);

#if defined(CONFIG_CMD_CDP)
	if (iscdp) {
		cdp_receive((uchar *)ip, len);
		return;
	}
#endif

	if ((myvlanid & VLAN_IDMASK) != VLAN_NONE) {
		if (vlanid == VLAN_NONE)
			vlanid = (mynvlanid & VLAN_IDMASK);
		/* not matched? */
		if (vlanid != (myvlanid & VLAN_IDMASK))
			return;
	}

	switch (eth_proto) {

		case PROT_NMRP:
			if(len <= MIN_ETHER_NMRP_LEN){
				printf("bad packet len@!\n");
				return;
			}
			memcpy(NmrpServerEther,et->et_src,6);
			(*udp_packet_handler)((uchar *)ip, 0, 0, 0, PROT_NMRP);
			break;
	case PROT_ARP:
		ArpReceive(et, ip, len);
		break;

#ifdef CONFIG_CMD_RARP
	case PROT_RARP:

		if(NetRunTftpServer == 1 )
		{
			debug("Got RARP\n");
			return;
		}
		rarp_receive(ip, len);
		break;
#endif
	case PROT_IP:
		debug_cond(DEBUG_NET_PKT, "Got IP\n");
		/* Before we start poking the header, make sure it is there */
		if (len < IP_UDP_HDR_SIZE) {
			debug("len bad %d < %lu\n", len,
				(ulong)IP_UDP_HDR_SIZE);
			return;
		}
		/* Check the packet length */
		if (len < ntohs(ip->ip_len)) {
			debug("len bad %d < %d\n", len, ntohs(ip->ip_len));
			return;
		}
		len = ntohs(ip->ip_len);
		debug_cond(DEBUG_NET_PKT, "len=%d, v=%02x\n",
			len, ip->ip_hl_v & 0xff);

		/* Can't deal with anything except IPv4 */
		if ((ip->ip_hl_v & 0xf0) != 0x40)
			return;
		/* Can't deal with IP options (headers != 20 bytes) */
		if ((ip->ip_hl_v & 0x0f) > 0x05)
			return;
		/* Check the Checksum of the header */
		if (!NetCksumOk((uchar *)ip, IP_HDR_SIZE / 2)) {
			debug("checksum bad\n");
			return;
		}
		/* If it is not for us, ignore it */
		dst_ip = NetReadIP(&ip->ip_dst);
		if (NetOurIP && dst_ip != NetOurIP && dst_ip != 0xFFFFFFFF) {
#ifdef CONFIG_MCAST_TFTP
			if (Mcast_addr != dst_ip)
#endif
				return;
		}
		/* Read source IP address for later use */
		src_ip = NetReadIP(&ip->ip_src);
		/*
		 * The function returns the unchanged packet if it's not
		 * a fragment, and either the complete packet or NULL if
		 * it is a fragment (if !CONFIG_IP_DEFRAG, it returns NULL)
		 */
		ip = NetDefragment(ip, &len);
		if (!ip)
			return;
		/*
		 * watch for ICMP host redirects
		 *
		 * There is no real handler code (yet). We just watch
		 * for ICMP host redirect messages. In case anybody
		 * sees these messages: please contact me
		 * (wd@denx.de), or - even better - send me the
		 * necessary fixes :-)
		 *
		 * Note: in all cases where I have seen this so far
		 * it was a problem with the router configuration,
		 * for instance when a router was configured in the
		 * BOOTP reply, but the TFTP server was on the same
		 * subnet. So this is probably a warning that your
		 * configuration might be wrong. But I'm not really
		 * sure if there aren't any other situations.
		 *
		 * Simon Glass <sjg@chromium.org>: We get an ICMP when
		 * we send a tftp packet to a dead connection, or when
		 * there is no server at the other end.
		 */
		if (ip->ip_p == IPPROTO_ICMP) {
			receive_icmp(ip, len, src_ip, et);
			return;
		} else if (ip->ip_p != IPPROTO_UDP) {	/* Only UDP packets */
			return;
		}
		/* Saved the Client IP address anyway for future use */
		TftpClientIP = NetReadIP(&ip->ip_src);

		debug_cond(DEBUG_DEV_PKT,
			"received UDP (to=%pI4, from=%pI4, len=%d)\n",
			&dst_ip, &src_ip, len);

#ifdef CONFIG_UDP_CHECKSUM
		if (ip->udp_xsum != 0) {
			ulong   xsum;
			ushort *sumptr;
			ushort  sumlen;

			xsum  = ip->ip_p;
			xsum += (ntohs(ip->udp_len));
			xsum += (ntohl(ip->ip_src) >> 16) & 0x0000ffff;
			xsum += (ntohl(ip->ip_src) >>  0) & 0x0000ffff;
			xsum += (ntohl(ip->ip_dst) >> 16) & 0x0000ffff;
			xsum += (ntohl(ip->ip_dst) >>  0) & 0x0000ffff;

			sumlen = ntohs(ip->udp_len);
			sumptr = (ushort *) &(ip->udp_src);

			while (sumlen > 1) {
				ushort sumdata;

				sumdata = *sumptr++;
				xsum += ntohs(sumdata);
				sumlen -= 2;
			}
			if (sumlen > 0) {
				ushort sumdata;

				sumdata = *(unsigned char *) sumptr;
				sumdata = (sumdata << 8) & 0xff00;
				xsum += sumdata;
			}
			while ((xsum >> 16) != 0) {
				xsum = (xsum & 0x0000ffff) +
				       ((xsum >> 16) & 0x0000ffff);
			}
			if ((xsum != 0x00000000) && (xsum != 0x0000ffff)) {
				printf(" UDP wrong checksum %08lx %08x\n",
					xsum, ntohs(ip->udp_xsum));
				return;
			}
		}
#endif


#ifdef CONFIG_NETCONSOLE
		nc_input_packet((uchar *)ip + IP_UDP_HDR_SIZE,
					ntohs(ip->udp_dst),
					ntohs(ip->udp_src),
					ntohs(ip->udp_len) - UDP_HDR_SIZE);
#endif
		/*
		 *	IP header OK.  Pass the packet to the current handler.
		 */
		(*udp_packet_handler)((uchar *)ip + IP_UDP_HDR_SIZE,
				ntohs(ip->udp_dst),
				src_ip,
				ntohs(ip->udp_src),
				ntohs(ip->udp_len) - UDP_HDR_SIZE);
		break;
	}
}


/**********************************************************************/

static int net_check_prereq(enum proto_t protocol)
{
	switch (protocol) {
		/* Fall through */
#if defined(CONFIG_CMD_PING)
	case PING:
		if (NetPingIP == 0) {
			puts("*** ERROR: ping address not given\n");
			return 1;
		}
		goto common;
#endif
#if defined(CONFIG_CMD_SNTP)
	case SNTP:
		if (NetNtpServerIP == 0) {
			puts("*** ERROR: NTP server address not given\n");
			return 1;
		}
		goto common;
#endif
#if defined(CONFIG_CMD_DNS)
	case DNS:
		if (NetOurDNSIP == 0) {
			puts("*** ERROR: DNS server address not given\n");
			return 1;
		}
		goto common;
#endif
#if defined(CONFIG_CMD_NFS)
	case NFS:
#endif
	case TFTPGET:
	case TFTPPUT:
		if (NetServerIP == 0) {
			puts("*** ERROR: `serverip' not set\n");
			return 1;
		}
#if	defined(CONFIG_CMD_PING) || defined(CONFIG_CMD_SNTP) || \
	defined(CONFIG_CMD_DNS)
common:
#endif
		/* Fall through */

	case NETCONS:
	case TFTPSRV:
		if (NetOurIP == 0) {
			puts("*** ERROR: `ipaddr' not set\n");
			return 1;
		}
		/* Fall through */

#ifdef CONFIG_CMD_RARP
	case RARP:
#endif
	case BOOTP:
	case CDP:
	case DHCP:
	case LINKLOCAL:
		if (memcmp(NetOurEther, "\0\0\0\0\0\0", 6) == 0) {
			int num = eth_get_dev_index();

			switch (num) {
			case -1:
				puts("*** ERROR: No ethernet found.\n");
				return 1;
			case 0:
				puts("*** ERROR: `ethaddr' not set\n");
				break;
			default:
				printf("*** ERROR: `eth%daddr' not set\n",
					num);
				break;
			}

			NetStartAgain();
			return 2;
		}
		/* Fall through */
	default:
		return 0;
	}
	return 0;		/* OK */
}
/**********************************************************************/

int
NetCksumOk(uchar *ptr, int len)
{
	return !((NetCksum(ptr, len) + 1) & 0xfffe);
}


unsigned
NetCksum(uchar *ptr, int len)
{
	ulong	xsum;
	ushort *p = (ushort *)ptr;

	xsum = 0;
	while (len-- > 0)
		xsum += *p++;
	xsum = (xsum & 0xffff) + (xsum >> 16);
	xsum = (xsum & 0xffff) + (xsum >> 16);
	return xsum & 0xffff;
}

int
NetEthHdrSize(void)
{
	ushort myvlanid;

	myvlanid = ntohs(NetOurVLAN);
	if (myvlanid == (ushort)-1)
		myvlanid = VLAN_NONE;

	return ((myvlanid & VLAN_IDMASK) == VLAN_NONE) ? ETHER_HDR_SIZE :
		VLAN_ETHER_HDR_SIZE;
}

int
NetSetEther(uchar *xet, uchar * addr, uint prot)
{
	struct ethernet_hdr *et = (struct ethernet_hdr *)xet;
	ushort myvlanid;

	myvlanid = ntohs(NetOurVLAN);
	if (myvlanid == (ushort)-1)
		myvlanid = VLAN_NONE;

	memcpy(et->et_dest, addr, 6);
	memcpy(et->et_src, NetOurEther, 6);
	if ((myvlanid & VLAN_IDMASK) == VLAN_NONE) {
		et->et_protlen = htons(prot);
		return ETHER_HDR_SIZE;
	} else {
		struct vlan_ethernet_hdr *vet =
			(struct vlan_ethernet_hdr *)xet;

		vet->vet_vlan_type = htons(PROT_VLAN);
		vet->vet_tag = htons((0 << 5) | (myvlanid & VLAN_IDMASK));
		vet->vet_type = htons(prot);
		return VLAN_ETHER_HDR_SIZE;
	}
}

int net_update_ether(struct ethernet_hdr *et, uchar *addr, uint prot)
{
	ushort protlen;

	memcpy(et->et_dest, addr, 6);
	memcpy(et->et_src, NetOurEther, 6);
	protlen = ntohs(et->et_protlen);
	if (protlen == PROT_VLAN) {
		struct vlan_ethernet_hdr *vet =
			(struct vlan_ethernet_hdr *)et;
		vet->vet_type = htons(prot);
		return VLAN_ETHER_HDR_SIZE;
	} else if (protlen > 1514) {
		et->et_protlen = htons(prot);
		return ETHER_HDR_SIZE;
	} else {
		/* 802.2 + SNAP */
		struct e802_hdr *et802 = (struct e802_hdr *)et;
		et802->et_prot = htons(prot);
		return E802_HDR_SIZE;
	}
}

void net_set_ip_header(uchar *pkt, IPaddr_t dest, IPaddr_t source)
{
	struct ip_udp_hdr *ip = (struct ip_udp_hdr *)pkt;

	/*
	 *	Construct an IP header.
	 */
	/* IP_HDR_SIZE / 4 (not including UDP) */
	ip->ip_hl_v  = 0x45;
	ip->ip_tos   = 0;
	ip->ip_len   = htons(IP_HDR_SIZE);
	ip->ip_id    = htons(NetIPID++);
	ip->ip_off   = htons(IP_FLAGS_DFRAG);	/* Don't fragment */
	ip->ip_ttl   = 255;
	ip->ip_sum   = 0;
	/* already in network byte order */
	NetCopyIP((void *)&ip->ip_src, &source);
	/* already in network byte order */
	NetCopyIP((void *)&ip->ip_dst, &dest);
}

void net_set_udp_header(uchar *pkt, IPaddr_t dest, int dport, int sport,
			int len)
{
	struct ip_udp_hdr *ip = (struct ip_udp_hdr *)pkt;

	/*
	 *	If the data is an odd number of bytes, zero the
	 *	byte after the last byte so that the checksum
	 *	will work.
	 */
	if (len & 1)
		pkt[IP_UDP_HDR_SIZE + len] = 0;

	net_set_ip_header(pkt, dest, NetOurIP);
	ip->ip_len   = htons(IP_UDP_HDR_SIZE + len);
	ip->ip_p     = IPPROTO_UDP;
	ip->ip_sum   = ~NetCksum((uchar *)ip, IP_HDR_SIZE >> 1);

	ip->udp_src  = htons(sport);
	ip->udp_dst  = htons(dport);
	ip->udp_len  = htons(UDP_HDR_SIZE + len);
	ip->udp_xsum = 0;
}

void copy_filename(char *dst, const char *src, int size)
{
	if (*src && (*src == '"')) {
		++src;
		--size;
	}

	while ((--size > 0) && *src && (*src != '"'))
		*dst++ = *src++;
	*dst = '\0';
}

#if	defined(CONFIG_CMD_NFS)		|| \
	defined(CONFIG_CMD_SNTP)	|| \
	defined(CONFIG_CMD_DNS)
/*
 * make port a little random (1024-17407)
 * This keeps the math somewhat trivial to compute, and seems to work with
 * all supported protocols/clients/servers
 */
unsigned int random_port(void)
{
	return 1024 + (get_timer(0) % 0x4000);
}
#endif

void ip_to_string(IPaddr_t x, char *s)
{
	x = ntohl(x);
	sprintf(s, "%d.%d.%d.%d",
		(int) ((x >> 24) & 0xff),
		(int) ((x >> 16) & 0xff),
		(int) ((x >> 8) & 0xff), (int) ((x >> 0) & 0xff)
	);
}

void VLAN_to_string(ushort x, char *s)
{
	x = ntohs(x);

	if (x == (ushort)-1)
		x = VLAN_NONE;

	if (x == VLAN_NONE)
		strcpy(s, "none");
	else
		sprintf(s, "%d", x & VLAN_IDMASK);
}

ushort string_to_VLAN(const char *s)
{
	ushort id;

	if (s == NULL)
		return htons(VLAN_NONE);

	if (*s < '0' || *s > '9')
		id = VLAN_NONE;
	else
		id = (ushort)simple_strtoul(s, NULL, 10);

	return htons(id);
}

ushort getenv_VLAN(char *var)
{
	return string_to_VLAN(getenv(var));
}

extern int flash_sect_erase (ulong, ulong);

/* Check if Alive-timer expires? */
void CheckNmrpAliveTimerExpire(int send_nmrp_alive)
{
	ulong passed;

	passed = get_timer(NmrpAliveTimerStart);
	if ((passed / CONFIG_SYS_HZ) + NmrpAliveTimerBase > NMRP_TIMEOUT_ACTIVE) {
		printf("Active-timer expires\n");
		if (send_nmrp_alive) NmrpSend();
		NmrpAliveTimerBase = NMRP_TIMEOUT_ACTIVE / 4;
		NmrpAliveTimerStart = get_timer(0);
	} else {
		printf("Alive-timer %u\n", (passed / CONFIG_SYS_HZ) + NmrpAliveTimerBase);
		/* If passed 1/4 NMRP_TIMEOUT_ACTIVE,
		 * add 1/4 NMRP_TIMEOUT_ACTIVE to NmrpAliveTimerBase.
		 * This is for avoiding "passed" overflow.
		 */
		if ((passed / CONFIG_SYS_HZ) >= (NMRP_TIMEOUT_ACTIVE / 4)) {
			NmrpAliveTimerBase += NMRP_TIMEOUT_ACTIVE / 4;
			NmrpAliveTimerStart = get_timer(0);
			printf("NmrpAliveTimerBase %u\n", NmrpAliveTimerBase);
		}
	}
}

#ifdef DNI_NAND
/**
 * handle_nand_modify_error:
 *
 * Handle erase or write error occured in a NAND erase block.
 *
 * For now, following method is adopted:
 *
 *     * Read the block again. If error, mark the block as bad and reset
 *       board.
 *
 *     * Optionally, if original data which is supposed to be written into the
 *       block is provided, compare read data with it. If 2 data are
 *       different, mark the block as bad and reset board.
 *
 *     * "mark the block as bad and reset board" above takes effect only when
 *       markbad function is implemented in NAND flash driver. If markbad is
 *       not implemented, nothing happens so that behaviors in old version of
 *       code are preserved.
 *
 * @param nand       NAND device
 * @param offset     offset in flash
 * @param orig_data  buffer containing data before being written.
 *                   pass NULL if you do not want to verify written data.
 * @return           never return if block is being tried to be marked as bad
 */
static void handle_nand_modify_error(nand_info_t *nand, ulong offset,
                                     uchar *orig_data)
{
	int rval;
	size_t read_length = CONFIG_SYS_FLASH_SECTOR_SIZE;
	uchar buffer[CONFIG_SYS_FLASH_SECTOR_SIZE];

	printf("Try to read block 0x%lx ... ", offset);
	rval = nand_read(nand, offset, &read_length, buffer);

	/* ECC-correctable block */
	if (rval == -EUCLEAN) {
		rval = 0;
	}
	printf("%s\n", rval ? "ERROR" : "OK");

	if (rval == 0 && orig_data != NULL) {
		puts("Compare written data with original data ... ");
		rval = memcmp(orig_data, buffer,
		              CONFIG_SYS_FLASH_SECTOR_SIZE);
		printf("%s\n", rval ? "DIFFERENT" : "SAME");
	}

	if (rval && nand->block_markbad != NULL) {
		printf("Marking block 0x%lx as bad block ... ", offset);
		rval = nand->block_markbad(nand, offset);
		printf("%s\n", rval ? "FAILED" : "SUCCESS");

		do_reset(NULL, 0, 0, NULL);
	}
}

void update_data(ulong addr, int data_size, ulong target_addr_begin, size_t target_addr_len, int send_nmrp_alive, int mark_bad_reset)
{
	int offset_num;
	uchar *src_addr;
	ulong target_addr;

	if (data_size <= 1) {
		printf("Incorrect data size\n");
		return;
	}

	target_addr = target_addr_begin;
	for (offset_num = 0;
	     offset_num < (((data_size - 1) / CONFIG_SYS_FLASH_SECTOR_SIZE) + 1);
	     offset_num++) {
		nand_erase_options_t nand_erase_options;
		size_t write_size;
		int ret = 0;

		/* erase 64K */
		while (nand_block_isbad(&nand_info[0], target_addr)) {
			printf("Skipping erasing bad block at 0x%08lx\n", target_addr);
			target_addr += CONFIG_SYS_FLASH_SECTOR_SIZE;
		}
		if (target_addr >= target_addr_begin + target_addr_len)
			goto bad_nand;

		printf("Erasing: off %x, size %x\n", target_addr, CONFIG_SYS_FLASH_SECTOR_SIZE);
		memset(&nand_erase_options, 0, sizeof(nand_erase_options));
		nand_erase_options.length = CONFIG_SYS_FLASH_SECTOR_SIZE;
		nand_erase_options.quiet = 0;
		nand_erase_options.jffs2 = 1;
		nand_erase_options.scrub = 0;
		nand_erase_options.offset = target_addr;
		ret = nand_erase_opts(&nand_info[0], &nand_erase_options);
		printf("%s\n", ret ? "ERROR" : "OK");

		if (mark_bad_reset && ret) {
			handle_nand_modify_error(
				&nand_info[0], target_addr, NULL);
		}

		src_addr = addr + offset_num * CONFIG_SYS_FLASH_SECTOR_SIZE;

		printf("Writing: from RAM addr %x, to NAND off %x, size %x\n", src_addr, target_addr, CONFIG_SYS_FLASH_SECTOR_SIZE);
		write_size = CONFIG_SYS_FLASH_SECTOR_SIZE;
		ret = nand_write_skip_bad(&nand_info[0], target_addr, &write_size, (u_char *)src_addr, 0);
		printf(" %zu bytes written: %s\n", write_size,
		       ret ? "ERROR" : "OK");

		if (mark_bad_reset && ret) {
			handle_nand_modify_error(
				&nand_info[0], target_addr, src_addr);
		}

		CheckNmrpAliveTimerExpire(send_nmrp_alive);
		target_addr += CONFIG_SYS_FLASH_SECTOR_SIZE;
	}
	return;
bad_nand:
	printf("** FAIL !! too many bad blocks, no enough space for data.\n");
}

void update_firmware(ulong addr, int firmware_size)
{
	if (get_len_incl_bad(&nand_info[0], (loff_t)CONFIG_SYS_IMAGE_ADDR_BEGIN,
	    (size_t)firmware_size) > ((size_t)CONFIG_SYS_IMAGE_LEN +
	                              (size_t)board_image_reserved_length()))
	{
		printf("** FAIL !! too many bad blocks, no enough space for firmware image.\n");
		return;
	}

#if defined(CONFIG_HW29764958P0P128P512P3X3P4X4) || \
    defined(CONFIG_HW29764958P0P128P512P4X4P4X4PCASCADE) || \
    defined(CONFIG_HW29765257P0P128P256P3X3P4X4) || \
    defined(CONFIG_HW29764958P0P128P512P4X4P4X4PXDSL)
	run_command("ipq_nand linux", 0);
#endif
	update_data(addr, firmware_size, CONFIG_SYS_IMAGE_ADDR_BEGIN,
	            CONFIG_SYS_IMAGE_LEN +
		    (size_t)board_image_reserved_length(), 1, 1);

	if(NmrpState != 0)
		return;
	printf ("Done\nRebooting...\n");

	do_reset(NULL,0,0,NULL);
}
#endif

#ifdef CONFIG_FUNC_MMC
void update_firmware(ulong addr, int firmware_size)
{
	if (firmware_size <= 0) {
		printf("Incorrect firmware size\n");
		return;
	}
	uchar *src_addr;
	ulong target_addr;
	ulong target_cnt;

	target_addr = IMAGE_BASE_BLOCK;
	target_cnt = firmware_size/0x200 + 1;

	char runcmd[256];

	printf ("mmc erase 0x%lx 0x%lx\n",target_addr, target_cnt);
	snprintf(runcmd, sizeof(runcmd), "mmc erase 0x%lx 0x%lx", target_addr, target_cnt);
	run_command(runcmd, 0);
	CheckNmrpAliveTimerExpire(1);

	printf ("Copy image to Flash... ");

	printf ("mmc write 0x%lx 0x%lx 0x%lx\n", addr, target_addr, target_cnt);
	snprintf(runcmd, sizeof(runcmd), "mmc write 0x%lx 0x%lx 0x%lx", addr, target_addr, target_cnt);
	run_command(runcmd, 0);

#ifdef CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4	
	printf ("boot_partition_set 1\n");
	snprintf(runcmd, sizeof(runcmd), "boot_partition_set 1");
	run_command(runcmd, 0);
#endif
	CheckNmrpAliveTimerExpire(1);
	
	if(NmrpState != 0)
		return;
	printf ("Done\nRebooting...\n");

	do_reset(NULL,0,0,NULL);
}
#endif

#ifdef CONFIG_FUNC_MMC
void update_firmware_second(ulong addr, int firmware_size)
{
	if (firmware_size <= 0) {
		printf("Incorrect firmware size\n");
		return;
	}
	uchar *src_addr;
	ulong target_addr;
	ulong target_cnt;

	target_addr = IMAGE_BASE_BLOCK_SECOND_FW;
	target_cnt = firmware_size/0x200 + 1;

	char runcmd[256];

	printf ("mmc erase 0x%lx 0x%lx\n",target_addr, target_cnt);
	snprintf(runcmd, sizeof(runcmd), "mmc erase 0x%lx 0x%lx", target_addr, target_cnt);
	run_command(runcmd, 0);
	CheckNmrpAliveTimerExpire(1);

	printf ("Copy image to Flash... ");

	printf ("mmc write 0x%lx 0x%lx 0x%lx\n", addr, target_addr, target_cnt);
	snprintf(runcmd, sizeof(runcmd), "mmc write 0x%lx 0x%lx 0x%lx", addr, target_addr, target_cnt);
	run_command(runcmd, 0);

#ifdef CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4	
	printf ("boot_partition_set 2\n");
	snprintf(runcmd, sizeof(runcmd), "boot_partition_set 2");
	run_command(runcmd, 0);
#endif
	CheckNmrpAliveTimerExpire(1);
	
	if(NmrpState != 0)
		return;
	printf ("Done\nRebooting...\n");

	do_reset(NULL,0,0,NULL);
}
#endif

#ifndef DNI_NAND
#ifndef CONFIG_FUNC_MMC
void update_firmware(ulong addr, int firmware_size)
{
	if (firmware_size <= 0) {
		printf("Incorrect firmware size\n");
		return;
	}
	int offset_num;
	uchar *src_addr;
	ulong target_addr;

	target_addr = CONFIG_SYS_IMAGE_ADDR_BEGIN;
	for (offset_num = 0;
	     offset_num < ((firmware_size / CONFIG_SYS_FLASH_SECTOR_SIZE) + 1);
	     offset_num++) {

		/* erase 64K */
		flash_sect_erase(CONFIG_SYS_IMAGE_ADDR_BEGIN +
				 offset_num * CONFIG_SYS_FLASH_SECTOR_SIZE,
				 CONFIG_SYS_IMAGE_ADDR_BEGIN +
				 ((offset_num + 1) * CONFIG_SYS_FLASH_SECTOR_SIZE) - 1);

		CheckNmrpAliveTimerExpire(1);
		target_addr += CONFIG_SYS_FLASH_SECTOR_SIZE;
	}
	printf ("Copy image to Flash... ");
	target_addr = CONFIG_SYS_IMAGE_ADDR_BEGIN;
	for (offset_num = 0;
	     offset_num < ((firmware_size / CONFIG_SYS_FLASH_SECTOR_SIZE) + 1);
	     offset_num++) {

		src_addr = addr + offset_num * CONFIG_SYS_FLASH_SECTOR_SIZE;
		flash_write(src_addr, target_addr, CONFIG_SYS_FLASH_SECTOR_SIZE);

		CheckNmrpAliveTimerExpire(1);
		target_addr += CONFIG_SYS_FLASH_SECTOR_SIZE;
	}
	if(NmrpState != 0)
		return;
	printf ("Done\nRebooting...\n");

	do_reset(NULL,0,0,NULL);
}
#endif
#endif

void StartTftpServerToRecoveFirmware (void)
{
	NetRunTftpServer = 1;
	ulong addr;
	image_header_t *hdr;
	int file_size;
	char *s;

	/* pre-set load_addr from CONFIG_SYS_LOAD_ADDR */
	load_addr = CONFIG_SYS_LOAD_ADDR;

	/* pre-set load_addr from $loadaddr */
	if ((s = getenv("loadaddr")) != NULL) {
		load_addr = simple_strtoul(s, NULL, 16);
	}

tftpstart:
	addr = load_addr;
	file_size = NetLoop(TFTPGET);
	if (file_size < 1)
	{
		printf ("\nFirmware recovering from TFTP server is stopped or failed! :( \n");
		NetRunTftpServer = 0;
		return;
	}

	//  copy Image to flash

	if (NmrpState == STATE_CLOSED)
		return;
	else if ( NmrpState !=0 )
		NmrpState = STATE_CLOSING;
	hdr = (image_header_t *)(addr + HEADER_LEN);
#ifndef CONFIG_FIT
	if (!board_model_id_match_open_source_id() &&
	    !image_match_open_source_fw_id(addr) &&
	    ntohl(hdr->ih_magic) != IH_MAGIC) {
		puts ("Bad Magic Number,it is forbidden to be written to flash!!\n");
		ResetTftpServer();
		goto tftpstart;
	}
#endif
#ifdef NETGEAR_BOARD_ID_SUPPORT
	if (!board_match_image_hw_id(addr)) {
		puts ("Board HW ID mismatch,it is forbidden to be written to flash!!\n");
		ResetTftpServer();
		goto tftpstart;
	}
	if (!board_model_id_match_open_source_id() &&
	    (!board_match_image_model_id(addr) &&
	     !image_match_open_source_fw_id(addr))) {
		puts ("Board MODEL ID mismatch,it is forbidden to be written to flash!!\n");
		ResetTftpServer();
		goto tftpstart;
	}
	if (!board_match_image_model_id(addr)) {
		printf("board model id mismatch with image id, updating board ID\n");
		board_update_image_model_id(addr);
	}
#endif

	update_firmware(addr + HEADER_LEN, file_size - HEADER_LEN);
	if (NmrpState == STATE_CLOSING)
	{
		net_set_udp_handler(NmrpHandler);
		NmrpSend();
	}
	/*
	 *  It indicates that tftp server would leave running state when
	 *  this function returns.
	 */
	NetRunTftpServer = 0;
}

int do_fw_recovery (cmd_tbl_t *cmdtp, int flag, int argc, char *argv[])
{
	StartTftpServerToRecoveFirmware();
	return 0;
}

U_BOOT_CMD(
	fw_recovery,	1,	0,	do_fw_recovery,
	"start tftp server to recovery dni firmware image.",
	"- start tftp server to recovery dni firmware image."
);

#ifdef CONFIG_HW29765352P32P4000P512P2X2P2X2P4X4
void StartTftpServerToRecoveFirmware_second (void)
{
	NetRunTftpServer = 1;
	ulong addr;
	image_header_t *hdr;
	int file_size;
	char *s;

	/* pre-set load_addr from CONFIG_SYS_LOAD_ADDR */
	load_addr = CONFIG_SYS_LOAD_ADDR;

	/* pre-set load_addr from $loadaddr */
	if ((s = getenv("loadaddr")) != NULL) {
		load_addr = simple_strtoul(s, NULL, 16);
	}

tftpstart:
	addr = load_addr;
	file_size = NetLoop(TFTPGET);
	if (file_size < 1)
	{
		printf ("\nFirmware recovering from TFTP server is stopped or failed! :( \n");
		NetRunTftpServer = 0;
		return;
	}

	//  copy Image to flash

	if (NmrpState == STATE_CLOSED)
		return;
	else if ( NmrpState !=0 )
		NmrpState = STATE_CLOSING;
	hdr = (image_header_t *)(addr + HEADER_LEN);
#ifndef CONFIG_FIT
	if (!board_model_id_match_open_source_id() &&
	    !image_match_open_source_fw_id(addr) &&
	    ntohl(hdr->ih_magic) != IH_MAGIC) {
		puts ("Bad Magic Number,it is forbidden to be written to flash!!\n");
		ResetTftpServer();
		goto tftpstart;
	}
#endif
#ifdef NETGEAR_BOARD_ID_SUPPORT
	if (!board_match_image_hw_id(addr)) {
		puts ("Board HW ID mismatch,it is forbidden to be written to flash!!\n");
		ResetTftpServer();
		goto tftpstart;
	}
	if (!board_model_id_match_open_source_id() &&
	    (!board_match_image_model_id(addr) &&
	     !image_match_open_source_fw_id(addr))) {
		puts ("Board MODEL ID mismatch,it is forbidden to be written to flash!!\n");
		ResetTftpServer();
		goto tftpstart;
	}
	if (!board_match_image_model_id(addr)) {
		printf("board model id mismatch with image id, updating board ID\n");
		board_update_image_model_id(addr);
	}
#endif

	update_firmware_second(addr + HEADER_LEN, file_size - HEADER_LEN);
	if (NmrpState == STATE_CLOSING)
	{
		net_set_udp_handler(NmrpHandler);
		NmrpSend();
	}
	/*
	 *  It indicates that tftp server would leave running state when
	 *  this function returns.
	 */
	NetRunTftpServer = 0;
}

int do_fw_recovery_second (cmd_tbl_t *cmdtp, int flag, int argc, char *argv[])
{
	StartTftpServerToRecoveFirmware_second();
	return 0;
}

U_BOOT_CMD(
	fw_recovery_second,	1,	0,	do_fw_recovery_second,
	"start tftp server to recovery dni firmware image.",
	"- start tftp server to recovery dni firmware image."
);
#endif

void UpgradeFirmwareFromNmrpServer(void)
{
	NetRunTftpServer = 1;
	ulong addr;
	image_header_t *hdr;
	int file_size;
	char *s;

	/* pre-set load_addr from CONFIG_SYS_LOAD_ADDR */
	load_addr = CONFIG_SYS_LOAD_ADDR;

	/* pre-set load_addr from $loadaddr */
	if ((s = getenv("loadaddr")) != NULL) {
		load_addr = simple_strtoul(s, NULL, 16);
	}

	addr = load_addr;
	file_size = NetLoop(TFTPGET);
	if (file_size < 1)
	{
		printf ("\nFirmware recovering from TFTP server is stopped or failed! :( \n");
		NetRunTftpServer = 0;
		return;
	}

	NmrpState = STATE_TFTPUPLOADING;
	net_set_udp_handler(NmrpHandler);
	NmrpSend();

	printf("Ignore Magic number checking when upgrade via NMRP,Magic number is %x!\n", IH_MAGIC);
	//  copy Image to flash
#ifdef NETGEAR_BOARD_ID_SUPPORT
	if (board_match_image_hw_id(addr)) {
		update_firmware(addr + HEADER_LEN, file_size - HEADER_LEN);
		board_update_image_model_id(addr);
	}
	else {
		puts ("Board HW ID mismatch,it is forbidden to be written to flash!!\n");
	}
#else
	update_firmware(addr + HEADER_LEN, file_size - HEADER_LEN);
#endif

	/* firmware write to flash done */
	NmrpFwUPOption = 0;
	if (NmrpSTUPOption == 1) {
		NmrpState = STATE_CONFIGING;
	} else {
		NmrpState = STATE_CLOSING;
	}
	net_set_udp_handler(NmrpHandler);
	NmrpSend();
	NetRunTftpServer = 0;
}

void UpgradeStringTableFromNmrpServer(int table_num)
{
	NetRunTftpServer = 1;
	ulong addr;
	image_header_t *hdr;
	int file_size;
	char *s;

	/* pre-set load_addr from CONFIG_SYS_LOAD_ADDR */
	load_addr = CONFIG_SYS_LOAD_ADDR;

	/* pre-set load_addr from $loadaddr */
	if ((s = getenv("loadaddr")) != NULL) {
		load_addr = simple_strtoul(s, NULL, 16);
	}

	addr = load_addr;
	memset(addr, 0, CONFIG_SYS_STRING_TABLE_LEN);
	file_size = NetLoop(TFTPGET);
	if (file_size < 1)
	{
		printf ("\nUpdating string table %d from TFTP server \
			is stopped or failed! :( \n", table_num);
		NetRunTftpServer = 0;
		return;
	}

	/* TFTP Uploading done */
	NmrpState = STATE_TFTPUPLOADING;
	net_set_udp_handler(NmrpHandler);
	NmrpSend();

	/* Write String Table to flash */
	board_upgrade_string_table((uchar *)addr, table_num, file_size);

	/* upgrade string table done, check if more files */
	NmrpStringTableUpdateIndex++;
	if (NmrpStringTableUpdateIndex == NmrpStringTableUpdateCount)
		NmrpSTUPOption = 0;
	if (NmrpFwUPOption == 0 && NmrpSTUPOption == 0) {
		workaround_qca8337_gmac_nmrp_hang_action();
		workaround_ipq40xx_gmac_nmrp_hang_action();
		printf("Upgrading all done\n");
		NmrpState = STATE_CLOSING;
		net_set_udp_handler(NmrpHandler);
		NmrpSend();
	} else {
		printf("More files to be upgrading\n");
		workaround_qca8337_gmac_nmrp_hang_action();
		workaround_ipq40xx_gmac_nmrp_hang_action();
		NmrpState = STATE_CONFIGING;
		net_set_udp_handler(NmrpHandler);
		NmrpSend();
	}
	NetRunTftpServer = 0;
}

void ResetTftpServer(void)
{
	timeHandler = 0;
	if(NmrpState != 0)
	{
		NmrpState = STATE_CONFIGING;
		NmrpSend();
	}
	else
	net_set_state(NETLOOP_RESTART);
}
void StartNmrpClient(void)
{
        if( NetLoop(NMRP) < 1)
        {
                printf("\n nmrp server is stopped or failed !\n");
                return;
        }
}
void ResetBootup_usual(void)
{
        timeHandler = 0;
        net_set_state(NETLOOP_SUCCESS);
}

int do_nmrp (cmd_tbl_t *cmdtp, int flag, int argc, char *argv[])
{
	StartNmrpClient();
	return 0;
}

U_BOOT_CMD(
	nmrp,	1,	0,	do_nmrp,
	"start nmrp mechanism to upgrade firmware-image or string-table.",
	"- start nmrp mechanism to upgrade firmware-image or string-table."
);
