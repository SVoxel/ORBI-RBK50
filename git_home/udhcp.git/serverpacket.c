/* serverpacket.c
 *
 * Constuct and send DHCP server packets
 *
 * Russ Dill <Russ.Dill@asu.edu> July 2001
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <time.h>

#if __GLIBC__ >=2 && __GLIBC_MINOR >= 1
#include <netpacket/packet.h>
#include <net/ethernet.h>
#else
#include <asm/types.h>
#include <linux/if_packet.h>
#ifdef UDHCP_USE_MUSL
//#include <linux/if_ether.h>
#else
#include <linux/if_ether.h>
#endif
#endif

#ifdef DHCPD_SHOW_HOSTNAME
#include <ctype.h>
#endif

#include "packet.h"
#include "debug.h"
#include "dhcpd.h"
#include "options.h"
#include "leases.h"

unsigned char g_src_addr[6] = {0};
u_int32_t latest_addr;

static int is_guest_client(u_int8_t *chaddr)
{
	int ret = 0;
	FILE *pfile;
	char cmd[128];

	sprintf(cmd, "/usr/share/udhcpc/is_guest_client %02x:%02x:%02x:%02x:%02x:%02x", chaddr[0], chaddr[1], chaddr[2], chaddr[3], chaddr[4], chaddr[5]);
	pfile = popen(cmd, "r");
	ret = fgetc(pfile);
	pclose(pfile);

	return ret == '1';
}

/* send a packet to giaddr using the kernel ip stack */
static int send_packet_to_relay(struct dhcpMessage *payload)
{
	DEBUG(LOG_INFO, "Forwarding packet to relay");

	return kernel_packet(payload, server_config.server, SERVER_PORT,
			payload->giaddr, SERVER_PORT);
}


/* send a packet to a specific arp address and ip address by creating our own ip packet */
static int send_packet_to_client(struct dhcpMessage *payload, int force_broadcast)
{
	unsigned char *chaddr;
	u_int32_t ciaddr;
	
	/*
	 * Bug 89030 - [ORD-358] [MR2.2][Ethernet BH] DHCP server does not respond under certain case.
	 * When in loop, our dhcp server seems hard to assign ip to satellite, but other open source 
	 * server can response faster. After checking, add this change to change server action.
	 * */
	 if (force_broadcast || (ntohs(payload->flags) & BROADCAST_FLAG) || !payload->ciaddr) {
		DEBUG(LOG_INFO, "broadcasting packet to client");
		ciaddr = INADDR_BROADCAST;
		chaddr = MAC_BCAST_ADDR;
	} else {
		DEBUG(LOG_INFO, "unicasting packet to client ciaddr");
		ciaddr = payload->ciaddr;
		/*
		 * Bug 22814
		 * g_src_addr is from datalink layer source mac address, which is real source address used to send reply.
		 * if 'chaddr' is behind real source address, we can't use chaddr as reply packet's destination address
		 */
		chaddr = g_src_addr;
		if(memcmp(g_src_addr, payload->chaddr, 6) != 0)
		{
			LOG(LOG_INFO,
			  "it seems %02x:%02x:%02x:%02x:%02x:%02x is behind %02x:%02x:%02x:%02x:%02x:%02x, send packet to %02x:%02x:%02x:%02x:%02x:%02x",
			  payload->chaddr[0], payload->chaddr[1], payload->chaddr[2], payload->chaddr[3], payload->chaddr[4], payload->chaddr[5],
			  g_src_addr[0], g_src_addr[1], g_src_addr[2], g_src_addr[3], g_src_addr[4], g_src_addr[5],
			  g_src_addr[0], g_src_addr[1], g_src_addr[2], g_src_addr[3], g_src_addr[4], g_src_addr[5]);
		}
	}
	return raw_packet(payload, server_config.server, SERVER_PORT, 
			ciaddr, CLIENT_PORT, chaddr, server_config.ifindex);
}


/* send a dhcp packet, if force broadcast is set, the packet will be broadcast to the client */
static int send_packet(struct dhcpMessage *payload, int force_broadcast)
{
	int ret;

	if (payload->giaddr)
		ret = send_packet_to_relay(payload);
	else ret = send_packet_to_client(payload, force_broadcast);
	return ret;
}


static void init_packet(struct dhcpMessage *packet, struct dhcpMessage *oldpacket, char type)
{
	init_header(packet, type);
	packet->xid = oldpacket->xid;
	memcpy(packet->chaddr, oldpacket->chaddr, 16);
	packet->flags = oldpacket->flags;
	packet->giaddr = oldpacket->giaddr;
	packet->ciaddr = oldpacket->ciaddr;
	add_simple_option(packet->options, DHCP_SERVER_ID, server_config.server);
}


/* add in the bootp options */
static void add_bootp_options(struct dhcpMessage *packet)
{
	packet->siaddr = server_config.siaddr;
	if (server_config.sname)
		strncpy(packet->sname, server_config.sname, sizeof(packet->sname) - 1);
	if (server_config.boot_file)
		strncpy(packet->file, server_config.boot_file, sizeof(packet->file) - 1);
}
	

/* send a DHCP OFFER to a DHCP DISCOVER */
int sendOffer(struct dhcpMessage *oldpacket)
{
	struct dhcpMessage packet;
	struct dhcpOfferedAddr *lease = NULL;
	u_int32_t req_align, lease_time_align = server_config.lease;
	unsigned char *req, *lease_time;
	struct option_set *curr;
	struct in_addr addr;
	char VIinfo[VENDOR_IDENTIFYING_INFO_LEN] = {0};

#ifdef DHCPD_STATIC_LEASE
	uint32_t static_lease_ip;
#endif
	init_packet(&packet, oldpacket, DHCPOFFER);
	
#ifdef DHCPD_STATIC_LEASE
	static_lease_ip = get_ip_by_mac(oldpacket->chaddr);
#endif

	/* ADDME: if static, short circuit */
	/* the client is in our lease/offered table */
#ifdef DHCPD_STATIC_LEASE
	if (static_lease_ip) {
                /* It is a static lease... use it */
                packet.yiaddr = static_lease_ip;
        }
	else if ((lease = find_lease_by_chaddr(oldpacket->chaddr)) && !check_ip(lease->yiaddr, NULL)) {
#else
	if ((lease = find_lease_by_chaddr(oldpacket->chaddr))) {
#endif
		if (!lease_expired(lease)) 
			lease_time_align = lease->expires - time(0);
		packet.yiaddr = lease->yiaddr;
		
	/* Or the client has a requested ip */
	} else if ((req = get_option(oldpacket, DHCP_REQUESTED_IP)) &&

		   /* Don't look here (ugly hackish thing to do) */
		   memcpy(&req_align, req, 4) &&

		   /* and the ip is in the lease range */
		   ntohl(req_align) >= ntohl(server_config.start) &&
		   ntohl(req_align) <= ntohl(server_config.end) &&
		   
#ifdef DHCPD_STATIC_LEASE
		   /* check the ip is not a reserved ip or it is a static ip at net */
                   !ip_reserved(req_align) &&
                   !check_ip(req_align, NULL) &&
#endif

		   /* and its not already taken/offered */ /* ADDME: check that its not a static lease */
		   ((!(lease = find_lease_by_yiaddr(req_align)) ||
		   
		   /* or its taken, but expired */ /* ADDME: or maybe in here */
		   lease_expired(lease)))) {
				packet.yiaddr = req_align; /* FIXME: oh my, is there a host using this IP? */

	/* otherwise, find a free IP */ /*ADDME: is it a static lease? */
	} else {
		packet.yiaddr = find_address(0);
		
		/* try for an expired lease */
		if (!packet.yiaddr) packet.yiaddr = find_address(1);
	}

        /* for Bug 31728 DHCP server is necessary to reassign the least recently assigned address. */
        if (!packet.yiaddr && 0 != latest_addr && !check_ip(latest_addr, NULL)) {
                packet.yiaddr = latest_addr;
        }
	
	if(!packet.yiaddr) {
		LOG(LOG_WARNING, "no IP addresses to give -- OFFER abandoned");
		return -1;
	}
	
	if (!add_lease(packet.chaddr, packet.yiaddr, server_config.offer_time)) {
		LOG(LOG_WARNING, "lease pool is full -- OFFER abandoned");
		return -1;
	}		
	latest_addr = packet.yiaddr; /* record the the least recently assigned address */

	if ((lease_time = get_option(oldpacket, DHCP_LEASE_TIME))) {
		memcpy(&lease_time_align, lease_time, 4);
		lease_time_align = ntohl(lease_time_align);
		if (lease_time_align > server_config.lease) 
			lease_time_align = server_config.lease;
	}

	/* Make sure we aren't just using the lease time from the previous offer */
	if (lease_time_align < server_config.min_lease) 
		lease_time_align = server_config.lease;

	if (is_guest_client(packet.chaddr))
		lease_time_align = GUEST_LEASE_TIME;

	/* ADDME: end of short circuit */		
	add_simple_option(packet.options, DHCP_LEASE_TIME, htonl(lease_time_align));

	curr = server_config.options;
	while (curr) {
		if (curr->data[OPT_CODE] != DHCP_LEASE_TIME)
			add_option_string(packet.options, curr->data);
		curr = curr->next;
	}

	add_bootp_options(&packet);
	
	/* Add for Orange France Livebox4 and WHD94 decoder: send back gateway identity */
	if ((strcmp(config_get("enable_orange"), "1") == 0)
		&& (strcmp(config_get("LB_ver"), "4") == 0))
	{
		if (createVIoption(VENDOR_IDENTIFYING_FOR_GATEWAY, VIinfo) != -1)
		{
			add_option_string(packet.options, (unsigned char *)VIinfo);
		}
	}

	addr.s_addr = packet.yiaddr;
#ifdef DHCP_PACKET_RESIZE
	DEBUG(LOG_INFO, "%d: ", __LINE__);
	/* XXX */
	if (req = get_option(oldpacket, DHCP_MAX_SIZE)) {
		unsigned short maxlen_align;
		memcpy(&maxlen_align, req, 2);
		maxlen_align = ntohs(maxlen_align);
/*
*		In RFC-2132, section 9.10
*		The code for this option is 57, and its length is 2.  The minimum
*		legal value is 576 octets.
*
*		Code   Len     Length
*		+-----+-----+-----+-----+
*		|  57 |  2  |  l1 |  l2 |
*		+-----+-----+-----+-----+
*/
		if (maxlen_align < 576) {
			DEBUG(LOG_INFO, "%d: DHCP MAX_SIZE option(57) value is smaller than 576 (without ethernet header)"
							" This value in packet is %d", __LINE__, maxlen_align);
		}
/*
*		From: Lancelot Wang
*		Sent: Wednesday, July 28, 2010 3:29 PM
*		To: Josn.Wang ...; Haohao.Li ..
*		Subject: Re: [WNDR3700U] HP wireless printer can't get IP address issue on both 3700 and 2000v3
*
*		2. If the DHCP discovery and DHCP request have Max. DHCP message size option,
*		you need to verify the DHCP message size (IP size) of DHCP offer and ACK are not
*		over this value before sending out.
*/
		if (udhcp_get_payload_len(&packet) + 8 + 20 > maxlen_align) {
			DEBUG(LOG_INFO, "%d: The packet size is larger than the value client defined", __LINE__);
			return -1;
		}
	}
#endif

	LOG(LOG_INFO, "sending OFFER of %s", inet_ntoa(addr));
	return send_packet(&packet, 0);
}


int sendNAK(struct dhcpMessage *oldpacket)
{
	struct dhcpMessage packet;

	init_packet(&packet, oldpacket, DHCPNAK);
	
	DEBUG(LOG_INFO, "sending NAK");
	return send_packet(&packet, 1);
}

#ifdef	DHCPD_SHOW_CLIENT_OPTIONS
#define CLIENTINFO_FILE "/tmp/udhcpd_clients"
#define CLIENTINFO_FILE_TMP "/tmp/udhcpd_clients.tmp"
int update_clients_info(char *file, char *mac, char *new)
{
        char buf[512], line[512];
        FILE *fp, *ft;
        int found = 0;

        if (0 != access(file, 0)) {
                if ((fp = fopen(file, "w")))
                        fclose(fp);
        }

        if (!(fp = fopen(file, "r")))
                return 0;

        if (!(ft = fopen(CLIENTINFO_FILE_TMP, "w"))) {
                fclose(fp); return 0;
        }
        while (fgets(line, sizeof(line), fp)) {
                if(strstr(line, mac)) {
                        found = 1;
                        fputs(new, ft);
                } else {
                        fputs(line, ft);
                }
        }

        if(!found)
                fputs(new, ft);

        fclose(fp);
        fclose(ft);

	copy_file(CLIENTINFO_FILE_TMP, file);
}

void strupr(char *str)
{
	for(;*str != '\0'; str++)
	{
		if(*str >= 97 && *str <= 122)
		*str = (*str)-32;
	}
}

int show_client_info(char *client_ip, char *client_mac, struct dhcpMessage *oldpacket)
{
	unsigned int i, idx, namelen;
	char *hostname = NULL, *verdor_option = NULL;
	char buf[512] = {0}, client_name[256] = "Unknown", options[128] = {0}, vendor[32] = "Unknown", up_macstr[18];

	if(!client_ip || !client_mac)
		return 0;

	if ((hostname = get_option(oldpacket, DHCP_HOST_NAME))) {
		namelen = (int) hostname[-1];
		if (namelen > MAX_HOSTNAME_LEN)
			namelen = MAX_HOSTNAME_LEN;
		for (idx = 0; idx < namelen; idx++)
			client_name[idx] = (char) toupper(hostname[idx]);
		client_name[idx] = '\0';
	}

	if ((verdor_option = get_option(oldpacket, DHCP_VENDOR))) {
		namelen = (int) verdor_option[-1];
		if (namelen > 31)
			namelen = 31;
		for (idx = 0; idx < namelen; idx++)
			vendor[idx] = (char) verdor_option[idx];
		vendor[idx] = '\0';
	}

	get_option_codes(oldpacket, options);
	strlcpy(up_macstr, client_mac, sizeof(up_macstr));
	strupr(up_macstr);
	snprintf(buf, sizeof(buf), "%s;%s;%s;%s;%s\n", up_macstr, client_ip, client_name, vendor,options);
	//snprintf(buf, 512, "%16s,%64s,%18s,%32s", client_ip, client_name, client_mac, vendor);
	update_clients_info(CLIENTINFO_FILE, up_macstr, buf);
	return 0;
}
#endif

int sendACK(struct dhcpMessage *oldpacket, u_int32_t yiaddr)
{
	struct dhcpMessage packet;
	struct option_set *curr;
	unsigned char *lease_time;
	u_int32_t lease_time_align = server_config.lease;
	struct in_addr addr;
	char VIinfo[VENDOR_IDENTIFYING_INFO_LEN] = {0};

	init_packet(&packet, oldpacket, DHCPACK);
	packet.yiaddr = yiaddr;
	
	if ((lease_time = get_option(oldpacket, DHCP_LEASE_TIME))) {
		memcpy(&lease_time_align, lease_time, 4);
		lease_time_align = ntohl(lease_time_align);
		if (lease_time_align > server_config.lease) 
			lease_time_align = server_config.lease;
		else if (lease_time_align < server_config.min_lease) 
			lease_time_align = server_config.lease;
	}
	
	if (is_guest_client(packet.chaddr))
		lease_time_align = GUEST_LEASE_TIME;

#ifdef SUPPORT_ARLO
	if ( 0 == strcmp(config_get("enable_arlo_function"), "1") ) {
	char *host_name = get_option(oldpacket, DHCP_HOST_NAME);
	char namestr[MAX_HOSTNAME_LEN] = {'\0'};
	int indx, namestrlen;
    long long int temp_ip=yiaddr;
    int ip_arry[4];
    char cmd[512];
    if(strncmp(server_config.interface,"brarlo",6) == 0) //may have arry out of range if interface is br0
    {
        if(host_name == NULL || host_name[-1] != 5 ){
              //using host_name len to identify whether this client is satellite
                lease_time_align = 0x7fffffff;
                ip_arry[0]=temp_ip%256;temp_ip/=256;
                ip_arry[1]=temp_ip%256;temp_ip/=256;
                ip_arry[2]=temp_ip%256;temp_ip/=256;
                ip_arry[3]=temp_ip%256;

                sprintf(cmd,"/usr/sbin/sync_arlo_arp \"%02x:%02x:%02x:%02x:%02x:%02x\" \"%d.%d.%d.%d\" &", 
                oldpacket->chaddr[0],oldpacket->chaddr[1],oldpacket->chaddr[2],oldpacket->chaddr[3],oldpacket->chaddr[4],oldpacket->chaddr[5],
                ip_arry[0],ip_arry[1],ip_arry[2],ip_arry[3]);
                system(cmd);
            
        }
	}
	}
#endif

	add_simple_option(packet.options, DHCP_LEASE_TIME, htonl(lease_time_align));
	
	curr = server_config.options;
	while (curr) {
		if (curr->data[OPT_CODE] != DHCP_LEASE_TIME)
			add_option_string(packet.options, curr->data);
		curr = curr->next;
	}

	add_bootp_options(&packet);

	/* Add for Orange France Livebox4 and WHD94 decoder: send back gateway identity */
	if ((strcmp(config_get("enable_orange"), "1") == 0)
		&& (strcmp(config_get("LB_ver"), "4") == 0))
	{
		if (createVIoption(VENDOR_IDENTIFYING_FOR_GATEWAY, VIinfo) != -1)
		{
			add_option_string(packet.options, (unsigned char *)VIinfo);
		}
	}

	addr.s_addr = packet.yiaddr;

#ifdef DHCP_PACKET_RESIZE
	/* XXX */
	unsigned char *req;
	/* The same as sendOffer check behavior */
	if (req = get_option(oldpacket, DHCP_MAX_SIZE)) {
		unsigned short maxlen_align;
		memcpy(&maxlen_align, req, 2);
		maxlen_align = ntohs(maxlen_align);

		if (maxlen_align < 576) {
			DEBUG(LOG_INFO, "%d: DHCP MAX_SIZE option(57) value is smaller than 576 (without ethernet header)"
							" This value in packet is %d", __LINE__, maxlen_align);
		}
		if (udhcp_get_payload_len(&packet) + 8 + 20 > maxlen_align) {
			DEBUG(LOG_INFO, "%d: The packet size is larger than the value client defined", __LINE__);
			return -1;
		}
	}
#endif

	LOG(LOG_INFO, "sending ACK to %s", inet_ntoa(addr));

	if (send_packet(&packet, 0) < 0) 
		return -1;

	int i, n;
	char chaddr[18];
	for (i = 0, n = 0; i < 6; i++) {
		n += sprintf(chaddr + n, "%02x", packet.chaddr[i]);
		if (i != 5)
			n += sprintf(chaddr + n, ":");
	}
	syslog(6, "[DHCP IP: %s] to MAC address %s,", inet_ntoa(addr), chaddr);

	add_lease(packet.chaddr, packet.yiaddr, lease_time_align);

#ifdef	DHCPD_SHOW_CLIENT_OPTIONS
	show_client_info(inet_ntoa(addr), chaddr, oldpacket);
#endif

#ifdef DHCPD_SHOW_HOSTNAME
	int idx, namelen;
	unsigned char *hostname;
	struct dhcpOfferedAddr *clientlease;

	if ((clientlease = find_lease_by_yiaddr(yiaddr))) {
		clientlease->hostname[0] = '\0';
	
		if ((hostname = get_option(oldpacket, DHCP_HOST_NAME))) {
			namelen = (int) hostname[-1];
			if (namelen > MAX_HOSTNAME_LEN)
				namelen = MAX_HOSTNAME_LEN;
			for (idx = 0; idx < namelen; idx++)
				clientlease->hostname[idx] = (char) toupper(hostname[idx]);
			clientlease->hostname[idx] = '\0';
		}

		if (strcmp(server_config.pidfile, "/var/run/udhcpd.pid") == 0)
			show_clients_hostname();
	}
#endif

	return 0;
}


int send_inform(struct dhcpMessage *oldpacket)
{
	struct dhcpMessage packet;
	struct option_set *curr;

	init_packet(&packet, oldpacket, DHCPACK);
	
	curr = server_config.options;
	while (curr) {
		if (curr->data[OPT_CODE] != DHCP_LEASE_TIME)
			add_option_string(packet.options, curr->data);
		curr = curr->next;
	}

	add_bootp_options(&packet);

	return send_packet(&packet, 0);
}


/* return -1 on errors that are fatal for the socket, -2 for those that aren't */
int get_raw_packet(struct dhcpMessage *payload, int fd)
{
	int bytes;
	struct udp_dhcp_packet packet;
	struct sockaddr_ll srcaddr;
	u_int32_t source, dest;
	u_int16_t check;
	int socklen = sizeof(struct sockaddr_ll);
	char buf[4096];
	struct udp_dhcp_packet *p_packet;
	int copybytes = 0;

	memset(&srcaddr, 0, sizeof(struct sockaddr_ll));
	memset(&packet, 0, sizeof(struct udp_dhcp_packet));
	memset(buf, 0, sizeof(buf));
	bytes = recvfrom(fd, buf, sizeof(buf), 0, (struct sockaddr*)&srcaddr, &socklen);
	if (bytes < 0) {
		DEBUG(LOG_INFO, "couldn't read on raw listening socket -- ignoring");
		usleep(500000); /* possible down interface, looping condition */
		return -1;
	}
	
	memcpy(&packet, buf, sizeof(struct udp_dhcp_packet));
	p_packet = (struct udp_dhcp_packet *)buf;
	
	DEBUG(LOG_INFO, "========== recived packet on raw socket, dest port is %d", ntohs(packet.udp.dest));
	if (bytes < (int) (sizeof(struct iphdr) + sizeof(struct udphdr))) {
		DEBUG(LOG_INFO, "message too short, ignoring");
		return -2;
	}
	
	if (bytes < ntohs(packet.ip.tot_len)) {
		DEBUG(LOG_INFO, "Truncated packet");
		return -2;
	}
	
	/* ignore any extra garbage bytes */
	bytes = ntohs(packet.ip.tot_len);
	
	/* Make sure its the right packet for us, and that it passes sanity checks */
#ifdef UDHCP_USE_MUSL
	if (packet.ip.protocol != IPPROTO_UDP || packet.ip.version != IPVERSION ||
		packet.ip.ihl != sizeof(packet.ip) >> 2 || packet.udp.uh_dport != htons(SERVER_PORT) ||
		ntohs(packet.udp.uh_ulen) != (short) (bytes - sizeof(packet.ip))) {
#else
	if (packet.ip.protocol != IPPROTO_UDP || packet.ip.version != IPVERSION ||
	    packet.ip.ihl != sizeof(packet.ip) >> 2 || packet.udp.dest != htons(SERVER_PORT) ||
	    ntohs(packet.udp.len) != (short) (bytes - sizeof(packet.ip))) {
#endif
	    	DEBUG(LOG_INFO, "unrelated/bogus packet");
	    	return -2;
	}

	/* check IP checksum */
	check = packet.ip.check;
	packet.ip.check = 0;
	p_packet->ip.check = 0;
	if (check != checksum(&(p_packet->ip), sizeof(packet.ip))) {
		DEBUG(LOG_INFO, "bad IP header checksum, ignoring");
		return -1;
	}
	
	/* verify the UDP checksum by replacing the header with a psuedo header */
	source = packet.ip.saddr;
	dest = packet.ip.daddr;
#ifdef UDHCP_USE_MUSL
	check = packet.udp.uh_sum;
	packet.udp.uh_sum = 0;
	p_packet->udp.uh_sum = 0;
#else
	check = packet.udp.check;
	packet.udp.check = 0;
	p_packet->udp.check = 0;
#endif
	memset(&packet.ip, 0, sizeof(packet.ip));
	memset(&(p_packet->ip), 0, sizeof(packet.ip));

	packet.ip.protocol = IPPROTO_UDP;
	packet.ip.saddr = source;
	packet.ip.daddr = dest;
#ifdef UDHCP_USE_MUSL
	packet.ip.tot_len = packet.udp.uh_ulen; /* cheat on the psuedo-header */

	p_packet->ip.tot_len = packet.udp.uh_ulen; /* cheat on the psuedo-header */
#else
	packet.ip.tot_len = packet.udp.len; /* cheat on the psuedo-header */

	p_packet->ip.tot_len = packet.udp.len; /* cheat on the psuedo-header */
#endif
	p_packet->ip.protocol = IPPROTO_UDP;
	p_packet->ip.saddr = source;
	p_packet->ip.daddr = dest;

	if (check && check != checksum(p_packet, bytes)) {
		DEBUG(LOG_ERR, "packet with bad UDP checksum received, ignoring");
		return -2;
	}
	
	copybytes = bytes - (sizeof(packet.ip) + sizeof(packet.udp));
	if (copybytes > sizeof(struct dhcpMessage))
		copybytes = sizeof(struct dhcpMessage);
	memcpy(payload, &(p_packet->data), copybytes);
	
	if (ntohl(payload->cookie) != DHCP_MAGIC) {
		LOG(LOG_ERR, "received bogus message (bad magic) -- ignoring");
		return -2;
	}
	DEBUG(LOG_INFO, "oooooh!!! got some!");

	memcpy(g_src_addr, srcaddr.sll_addr, 6);
	
	return copybytes;
}

