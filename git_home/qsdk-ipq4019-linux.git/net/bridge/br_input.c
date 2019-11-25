/*
 *	Handle incoming frames
 *	Linux ethernet bridge
 *
 *	Authors:
 *	Lennert Buytenhek		<buytenh@gnu.org>
 *
 *	This program is free software; you can redistribute it and/or
 *	modify it under the terms of the GNU General Public License
 *	as published by the Free Software Foundation; either version
 *	2 of the License, or (at your option) any later version.
 */

#include <linux/slab.h>
#include <linux/kernel.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/netfilter_bridge.h>
#include <linux/neighbour.h>
#include <net/arp.h>
#include <linux/export.h>
#include <linux/rculist.h>
#include "br_private.h"
#include <linux/ipv6.h>

#ifdef CONFIG_DNI_MCAST_TO_UNICAST
#include <linux/ip.h>
#include <linux/igmp.h>

static inline void
add_mac_cache(struct sk_buff *skb)
{
      unsigned char i, num = 0xff;
      unsigned char *src, check = 1;
      struct iphdr *iph;
      struct ethhdr *ethernet=(struct ethhdr *)skb->mac_header;

      iph = (struct iphdr *)skb->network_header;
      src = ethernet->h_source;

      for (i = 0; i < MCAST_ENTRY_SIZE; i++)
      {
              if (mac_cache[i].valid)
                      if ((++mac_cache[i].count) == MAX_CLEAN_COUNT)
                              mac_cache[i].valid = 0;
      }

      for (i = 0; i < MCAST_ENTRY_SIZE; i++)
      {
              if (mac_cache[i].valid)
              {
                      if (mac_cache[i].sip==iph->saddr)
                      {
                              num = i;
                              break;
                      }
              }
              else if (check)
              {
                      num=i;
                      check = 0;
              }
      }

      if (num < MCAST_ENTRY_SIZE)
      {
              mac_cache[num].valid = mac_cache[num].count = 1;
              memcpy(mac_cache[num].mac, src, 6);
              mac_cache[num].sip = iph->saddr;
              mac_cache[num].dev = skb->dev;
      }
}

#endif

/* Hook for brouter */
br_should_route_hook_t __rcu *br_should_route_hook __read_mostly;
EXPORT_SYMBOL(br_should_route_hook);

/* Hook for external Multicast handler */
br_multicast_handle_hook_t __rcu *br_multicast_handle_hook __read_mostly;
EXPORT_SYMBOL_GPL(br_multicast_handle_hook);

/* Hook for external forwarding logic */
br_get_dst_hook_t __rcu *br_get_dst_hook __read_mostly;
EXPORT_SYMBOL_GPL(br_get_dst_hook);

int br_pass_frame_up(struct sk_buff *skb)
{
	struct net_device *indev, *brdev = BR_INPUT_SKB_CB(skb)->brdev;
	struct net_bridge *br = netdev_priv(brdev);
	struct pcpu_sw_netstats *brstats = this_cpu_ptr(br->stats);
	struct net_port_vlans *pv;

#ifdef CONFIG_DNI_MCAST_TO_UNICAST
      unsigned char *dest;
      struct iphdr *iph;
      unsigned char proto=0;
      struct ethhdr *ethernet=(struct ethhdr *)skb->mac_header;

      // if skb come from wireless interface, ex. ath0, ath1, ath2...
      if (skb->dev->name[0] == 'a')
      {
              iph = (struct iphdr *)skb->network_header;
              proto =  iph->protocol;
              dest = ethernet->h_dest;
              if ( igmp_snoop_enable && MULTICAST_MAC(dest)
                       && (ethernet->h_proto == ETH_P_IP))
              {
                      if (proto == IPPROTO_IGMP)
                              add_mac_cache(skb);
              }
      }
#endif
#ifdef CONFIG_BRIDGE_NETGEAR_ACL
      if (!br_acl_should_pass(br, skb, ACL_CHECK_SRC)) {
              br->dev->stats.rx_dropped++;
              kfree_skb(skb);
			  return NET_RX_DROP;
      }
#endif
	u64_stats_update_begin(&brstats->syncp);
	brstats->rx_packets++;
	brstats->rx_bytes += skb->len;
	u64_stats_update_end(&brstats->syncp);

	/* Bridge is just like any other port.  Make sure the
	 * packet is allowed except in promisc modue when someone
	 * may be running packet capture.
	 */
	pv = br_get_vlan_info(br);
	if (!(brdev->flags & IFF_PROMISC) &&
	    !br_allowed_egress(br, pv, skb)) {
		kfree_skb(skb);
		return NET_RX_DROP;
	}

	indev = skb->dev;
	skb->dev = brdev;
	skb = br_handle_vlan(br, pv, skb);
	if (!skb)
		return NET_RX_DROP;

	return BR_HOOK(NFPROTO_BRIDGE, NF_BR_LOCAL_IN, skb, indev, NULL,
		       netif_receive_skb);
}
EXPORT_SYMBOL_GPL(br_pass_frame_up);


#ifdef CONFIG_DNI_DNS_HIJACK
#include <linux/udp.h>
extern struct sock *dnsnl;
int sysctl_dns_hijack = 0;
int sysctl_is_satelite = 0;
int sysctl_block_dhcp;
typedef struct dns_nl_packet_msg {
       size_t data_len;
       char saddr[6];
       unsigned char data[0]
} dns_nl_packet_msg_t;

/* Return value:
 *  1	:Found
 *  0	:Not Found
 */
static int findstring(char * source, char * dest,int length,int urllen)
{
        if(source == NULL || dest == NULL )
                return 0;
 	char *s1,*d1;
        int i =0 ;
		s1 = source;
		d1 = dest;
        while ( i < (length - urllen))
        {
                if ( memcmp(s1,d1,urllen) == 0)
		{
                        return 1;
		}
                s1 = ++source;
                i++;
        }
        return 0;
}
static char *pass_domains[] = {
"captive.apple.com",
"appleiphonecell.com",
"apple.com",
"itools.info",
"ibook.info",
"airport.us",
"thinkdifferent.us",
"clients1.google.com",
"clients3.google.com",
"connectivitycheck.gstatic.com",
NULL
};
#define MAX_URL_NUM 32
char *newurl[MAX_URL_NUM];
int url_num=0;
int init=0;
char * replaceall(char * src,char oldchar,char newchar1,char newchar2){
	char *head=src;
	int j=0;
	while(*src!='\0'){
		if(*src==oldchar)
			if (j==0){
				*src=newchar1;
				j++;
			}else{
				*src=newchar2;
			}
		src++;
	}
	return head;
}
int br_dns_netgear(struct sk_buff *skb)
{
        struct ethhdr                   *eth = (struct ethhdr *)skb_mac_header(skb);
        struct iphdr                    *iph;
        struct ipv6hdr                  *ipv6h;
        struct udphdr                   *udph;
	struct udphdr                   _udph;
	int protoff;
	char *oriurl;
	int i;
		struct sk_buff	*skbnew = NULL;
        if (eth->h_proto != htons(ETH_P_IP) && eth->h_proto != htons(ETH_P_IPV6))
                return 1;
        /* Check for possible (maliciously) malformed IP frame (thanks Dave) */
        if(eth->h_proto == htons(ETH_P_IP))
        {
                iph = ip_hdr(skb);
		protoff = iph->ihl * 4;
                if(iph->protocol != 17)
                        return 1;
        	udph = skb_header_pointer(skb, protoff, sizeof(_udph), &_udph);
		if (udph == NULL)
			return 1;
	}
        else if(eth->h_proto == htons(ETH_P_IPV6))
        {
                ipv6h = (struct ipv6hdr *) skb->data;
                if(ipv6h->nexthdr != 17)
                        return 1;
                udph = (struct udphdr *)((unsigned char *)ipv6h + sizeof(struct ipv6hdr));//ipv6 header's fixed-lenght is 40
        }

	if (init == 0) { //only init one time
		for(i=0;i<MAX_URL_NUM;i++){
			oriurl=pass_domains[i];
			if (oriurl){
				if(strstr(oriurl,"captive"))
					newurl[i]=replaceall(oriurl,'.',0x05,0x03);
				else if(strstr(oriurl,"gstatic"))
					newurl[i]=replaceall(oriurl,'.',0x07,0x03);
				else if(strstr(oriurl,"google"))
					newurl[i]=replaceall(oriurl,'.',0x06,0x03);
				else if(strstr(oriurl,"com"))
					newurl[i]=replaceall(oriurl,'.',0x03,0x03);
				else if(strstr(oriurl,"info"))
					newurl[i]=replaceall(oriurl,'.',0x04,0x03);
				else if(strstr(oriurl,"us"))
					newurl[i]=replaceall(oriurl,'.',0x02,0x03);
				else
					newurl[i]=replaceall(oriurl,'.',0x03,0x03);
				url_num++;
			} 
			else{
				newurl[i]=NULL;
				break;
			}
		}
		init++;
	}
	if( udph->dest == ntohs(53))
	{
		if( sysctl_dns_hijack )
		{
			for(i=0;i<url_num;i++){
				if (findstring((unsigned char *)((unsigned char *)udph + 12),newurl[i],htons(udph->len) - 12, strlen(newurl[i]))){
					return 1;
				}
                	}
                        dns_nl_packet_msg_t *pm;
                        struct nlmsghdr *nlh;
                        size_t size, copy_len;
                        copy_len = skb->len;
                        size = NLMSG_SPACE(sizeof(*pm)+copy_len);
                        skbnew =  alloc_skb(4096, GFP_ATOMIC);
                        if(!skbnew)
                        {
                                printk(KERN_ERR "boxlogin: can't alloc whole buffer " "of size %ub!\n", 4096);
                                skbnew = alloc_skb(size, GFP_ATOMIC);
                                if(!skbnew)
                                {
                                        printk(KERN_ERR "boxlogin: can't alloc buffer " "of size %ub!\n", size);
                                        return 1;
                                }
						}
						nlh = nlmsg_put(skbnew, 0, 0, 0, (size - NLMSG_ALIGN(sizeof(*nlh))),0);
						if( NULL == nlh)
							goto nlmsg_failure;
                        nlh->nlmsg_len = sizeof(*pm)+skb->len;
                        pm = NLMSG_DATA(nlh);
                        pm->data_len = skb->len;
                        memcpy(pm->saddr,eth->h_source,6);
                        skb_copy_bits(skb, 0, pm->data, skb->len);
                        NETLINK_CB(skbnew).dst_group = 5;
                        netlink_broadcast(dnsnl, skbnew, 0, 5, GFP_ATOMIC);
                        return 0;
                }
        }
        if (sysctl_block_dhcp != 0 && udph->dest == htons(68))
        {
                /* block dhcp offer,ack packet from ath1 in ap mode */
                if (sysctl_block_dhcp == 1 && skb && (!strncmp(skb->dev->name, "ath11",5) || !strncmp(skb->dev->name, "ath01",5)))
                        return 0;
                else if  (sysctl_block_dhcp == 2 && skb && skb->dev->name[0] == 'e')
                        return 0;
        }
        return 1;
nlmsg_failure:
       printk(KERN_CRIT "dns net link: error during NLMSG_PUT. This should "
              "not happen, please report to author.\n");
	   kfree_skb( skbnew);
	   return 1;
}
#endif

#ifdef CONFIG_DNI_CHECK_STAVAP_PACKET
int sysctl_stavap_packet = 0;
#endif

static void br_do_proxy_arp(struct sk_buff *skb, struct net_bridge *br,
			    u16 vid, struct net_bridge_port *p)
{
	struct net_device *dev = br->dev;
	struct neighbour *n;
	struct arphdr *parp;
	u8 *arpptr, *sha;
	__be32 sip, tip;

	BR_INPUT_SKB_CB(skb)->proxyarp_replied = false;

	if (dev->flags & IFF_NOARP)
		return;

	if (!pskb_may_pull(skb, arp_hdr_len(dev))) {
		dev->stats.tx_dropped++;
		return;
	}
	parp = arp_hdr(skb);

	if (parp->ar_pro != htons(ETH_P_IP) ||
	    parp->ar_op != htons(ARPOP_REQUEST) ||
	    parp->ar_hln != dev->addr_len ||
	    parp->ar_pln != 4)
		return;

	arpptr = (u8 *)parp + sizeof(struct arphdr);
	sha = arpptr;
	arpptr += dev->addr_len;	/* sha */
	memcpy(&sip, arpptr, sizeof(sip));
	arpptr += sizeof(sip);
	arpptr += dev->addr_len;	/* tha */
	memcpy(&tip, arpptr, sizeof(tip));

	if (ipv4_is_loopback(tip) ||
	    ipv4_is_multicast(tip))
		return;

	n = neigh_lookup(&arp_tbl, &tip, dev);
	if (n) {
		struct net_bridge_fdb_entry *f;

		if (!(n->nud_state & NUD_VALID)) {
			neigh_release(n);
			return;
		}

		f = __br_fdb_get(br, n->ha, vid);
		if (f && ((p->flags & BR_PROXYARP) ||
			  (f->dst && (f->dst->flags & BR_PROXYARP_WIFI)))) {
			arp_send(ARPOP_REPLY, ETH_P_ARP, sip, skb->dev, tip,
				 sha, n->ha, sha);
			BR_INPUT_SKB_CB(skb)->proxyarp_replied = true;
		}

		neigh_release(n);
	}
}

/* note: already called with rcu_read_lock */
int br_handle_frame_finish(struct sk_buff *skb)
{
	const unsigned char *dest = eth_hdr(skb)->h_dest;
	struct net_bridge_port *p = br_port_get_rcu(skb->dev);
	struct net_bridge *br;
	struct net_bridge_fdb_entry *dst;
	struct net_bridge_mdb_entry *mdst;
	struct sk_buff *skb2;
	struct net_bridge_port *pdst = NULL;
	br_get_dst_hook_t *get_dst_hook = rcu_dereference(br_get_dst_hook);
	bool unicast = true;
	u16 vid = 0;

	if (!p || p->state == BR_STATE_DISABLED)
		goto drop;

	if (!br_allowed_ingress(p->br, nbp_get_vlan_info(p), skb, &vid))
		goto out;

	/* insert into forwarding database after filtering to avoid spoofing */
	br = p->br;
	if (p->flags & BR_LEARNING)
		br_fdb_update(br, p, eth_hdr(skb)->h_source, vid, false);

	if (!is_broadcast_ether_addr(dest) && is_multicast_ether_addr(dest) &&
	    br_multicast_rcv(br, p, skb, vid))
		goto drop;

	if ((p->state == BR_STATE_LEARNING) && skb->protocol != htons(ETH_P_PAE))
		goto drop;

	BR_INPUT_SKB_CB(skb)->brdev = br->dev;

	/* The packet skb2 goes to the local host (NULL to skip). */
	skb2 = NULL;

	if (br->dev->flags & IFF_PROMISC)
		skb2 = skb;

	dst = NULL;

	if (IS_ENABLED(CONFIG_INET) && skb->protocol == htons(ETH_P_ARP))
		br_do_proxy_arp(skb, br, vid, p);

	if (is_broadcast_ether_addr(dest)) {
		skb2 = skb;
		unicast = false;
	} else if (is_multicast_ether_addr(dest)
#ifdef CONFIG_DNI_IPV6_PASSTHROUGH
			|| (skb->protocol == __constant_htons(ETH_P_IPV6))
#endif
			) {
		br_multicast_handle_hook_t *multicast_handle_hook =
			rcu_dereference(br_multicast_handle_hook);
		if (!__br_get(multicast_handle_hook, true, p, skb))
			goto out;

		mdst = br_mdb_get(br, skb, vid);
		if ((mdst || BR_INPUT_SKB_CB_MROUTERS_ONLY(skb)) &&
		    br_multicast_querier_exists(br, eth_hdr(skb))) {
			if ((mdst && mdst->mglist) ||
			    br_multicast_is_router(br))
				skb2 = skb;
			br_multicast_forward(mdst, skb, skb2);
			skb = NULL;
			if (!skb2)
				goto out;
		} else
			skb2 = skb;

		unicast = false;
		br->dev->stats.multicast++;
	} else if ((pdst = __br_get(get_dst_hook, NULL, p, &skb))) {
		if (!skb)
			goto out;
	} else if ((p->flags & BR_ISOLATE_MODE) ||
		   ((dst = __br_fdb_get(br, dest, vid)) && dst->is_local)) {
		skb2 = skb;
		/* Do not forward the packet since it's local. */
		skb = NULL;
	}

	if (skb) {
		if (dst) {
			dst->used = jiffies;
			pdst = dst->dst;
		}

		if (pdst)
			br_forward(pdst, skb, skb2);
		else
			br_flood_forward(br, skb, skb2, unicast);
	}

	if (skb2)
		return br_pass_frame_up(skb2);

out:
	return 0;
drop:
	kfree_skb(skb);
	goto out;
}

/* note: already called with rcu_read_lock */
static int br_handle_local_finish(struct sk_buff *skb)
{
	struct net_bridge_port *p = br_port_get_rcu(skb->dev);
	if (p->state != BR_STATE_DISABLED) {
		u16 vid = 0;
		/* check if vlan is allowed, to avoid spoofing */
		if (p->flags & BR_LEARNING && br_should_learn(p, skb, &vid))
			br_fdb_update(p->br, p, eth_hdr(skb)->h_source, vid, false);
	}
	return 0;	 /* process further */
}

/*
 * Return NULL if skb is handled
 * note: already called with rcu_read_lock
 */
rx_handler_result_t br_handle_frame(struct sk_buff **pskb)
{
	struct net_bridge_port *p;
	struct sk_buff *skb = *pskb;
	const unsigned char *dest = eth_hdr(skb)->h_dest;
	br_should_route_hook_t *rhook;

	if (unlikely(skb->pkt_type == PACKET_LOOPBACK))
		return RX_HANDLER_PASS;

	if (!is_valid_ether_addr(eth_hdr(skb)->h_source))
		goto drop;

	skb = skb_share_check(skb, GFP_ATOMIC);
	if (!skb)
		return RX_HANDLER_CONSUMED;

	p = br_port_get_rcu(skb->dev);
#ifdef CONFIG_DNI_CHECK_STAVAP_PACKET
	if (skb && (!strncmp(skb->dev->name, "ath11", 5) || !strncmp(skb->dev->name, "ath01", 5))) {
		sysctl_stavap_packet++;
		if (sysctl_stavap_packet == 32767)
			sysctl_stavap_packet = 0;
	}
#endif
	if (unlikely(is_link_local_ether_addr(dest))) {
		/*
		 * See IEEE 802.1D Table 7-10 Reserved addresses
		 *
		 * Assignment		 		Value
		 * Bridge Group Address		01-80-C2-00-00-00
		 * (MAC Control) 802.3		01-80-C2-00-00-01
		 * (Link Aggregation) 802.3	01-80-C2-00-00-02
		 * 802.1X PAE address		01-80-C2-00-00-03
		 *
		 * 802.1AB LLDP 		01-80-C2-00-00-0E
		 *
		 * Others reserved for future standardization
		 */
		switch (dest[5]) {
		case 0x00:	/* Bridge Group Address */
			/* If STP is turned off,
			   then must forward to keep loop detection */
			if (p->br->stp_enabled == BR_NO_STP)
				goto forward;
			break;

		case 0x01:	/* IEEE MAC (Pause) */
			goto drop;

		default:
			/* Allow selective forwarding for most other protocols */
			if (p->br->group_fwd_mask & (1u << dest[5]))
				goto forward;
		}

		/* Deliver packet to local host only */
		if (BR_HOOK(NFPROTO_BRIDGE, NF_BR_LOCAL_IN, skb, skb->dev,
			    NULL, br_handle_local_finish)) {
			return RX_HANDLER_CONSUMED; /* consumed by filter */
		} else {
			*pskb = skb;
			return RX_HANDLER_PASS;	/* continue processing */
		}
	}

forward:
	switch (p->state) {
	case BR_STATE_DISABLED:
		if (skb->protocol == htons(ETH_P_PAE)) {
			if (ether_addr_equal(p->br->dev->dev_addr, dest))
				skb->pkt_type = PACKET_HOST;

			if (NF_HOOK(NFPROTO_BRIDGE, NF_BR_PRE_ROUTING, skb, skb->dev,
				    NULL, br_handle_local_finish))
				break;

			BR_INPUT_SKB_CB(skb)->brdev = p->br->dev;
			br_pass_frame_up(skb);
			break;
		}
		goto drop;
	case BR_STATE_FORWARDING:
#ifdef CONFIG_DNI_DNS_HIJACK
		if((sysctl_is_satelite == 1) && (br_dns_netgear(skb) == 0)) {
			kfree_skb(skb);
			return RX_HANDLER_CONSUMED;
		}
#endif
		rhook = rcu_dereference(br_should_route_hook);
		if (rhook) {
			if ((*rhook)(skb)) {
				*pskb = skb;
				return RX_HANDLER_PASS;
			}
			dest = eth_hdr(skb)->h_dest;
		}
		/* fall through */
	case BR_STATE_LEARNING:
		if (ether_addr_equal(p->br->dev->dev_addr, dest))
			skb->pkt_type = PACKET_HOST;

		BR_HOOK(NFPROTO_BRIDGE, NF_BR_PRE_ROUTING, skb, skb->dev, NULL,
			br_handle_frame_finish);
		break;
	default:
drop:
		kfree_skb(skb);
	}
	return RX_HANDLER_CONSUMED;
}
