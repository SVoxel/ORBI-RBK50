/*
 *	ACL database
 *	Linux ethernet bridge
 *
 *	Authors:
 *	Josn Wang		<Josn.Wang@Deltaww.com.cn>
 *
 *	This program is free software; you can redistribute it and/or
 *	modify it under the terms of the GNU General Public License
 *	as published by the Free Software Foundation; either version
 *	2 of the License, or (at your option) any later version.
 */

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/spinlock.h>
#include <linux/times.h>
#include <linux/netdevice.h>
#include <linux/inetdevice.h>
#include <linux/etherdevice.h>
#include <linux/jhash.h>
#include <asm/atomic.h>
#include <linux/ip.h>
#include <linux/in.h>
#include <linux/rtnetlink.h>
#include "br_private.h"

#define QUANTENNA_IP 0x01010102

char sysctl_2gbhapifname[16] = "ath";
char sysctl_2gbhstaifname[16] = "ath";
char sysctl_5gbhapifname[16] = "ath";
char sysctl_5gbhstaifname[16] = "ath";

#if support_guestportal_function
int acl_on = 0;
int gp_on = 0;
int (*redirect_handler)(struct sk_buff *skb) = NULL;
int (*redirect_handler2)(struct sk_buff *skb) = NULL;
EXPORT_SYMBOL(acl_on);
EXPORT_SYMBOL(gp_on);
EXPORT_SYMBOL(redirect_handler);
EXPORT_SYMBOL(redirect_handler2);
#endif

static inline unsigned compare_ether_addr(const u8 *addr1, const u8 *addr2)
{
        const u16 *a = (const u16 *) addr1;
        const u16 *b = (const u16 *) addr2;

        BUILD_BUG_ON(ETH_ALEN != 6);
        return ((a[0] ^ b[0]) | (a[1] ^ b[1]) | (a[2] ^ b[2])) != 0;
}

struct tcpudphdr {
	uint16_t src;
	uint16_t dst;
};

struct dns_nl_packet_msg
{
	size_t data_len;
	char saddr[6];
	unsigned char data[0];
};

static struct sock *dnsnl = NULL;

static struct kmem_cache *br_acl_cache __read_mostly;
struct net_bridge_acl_entry
{
	struct hlist_node	hlist;

	struct rcu_head		rcu;
	mac_addr		addr;
};

void __init br_acl_init(void)
{
	struct netlink_kernel_cfg dns_nl_cfg = {
		.groups		=	0,
	};

	br_acl_cache = kmem_cache_create("bridge_acl_cache",
					 sizeof(struct net_bridge_acl_entry),
					 0,
					 SLAB_HWCACHE_ALIGN, NULL);
	dnsnl = netlink_kernel_create(&init_net, NETLINK_USERSOCK, &dns_nl_cfg);
}

void __exit br_acl_fini(void)
{
	kmem_cache_destroy(br_acl_cache);
	if (dnsnl)
		netlink_kernel_release(dnsnl);
}

static __inline__ int br_mac_hash(const unsigned char *mac)
{
	return jhash(mac, ETH_ALEN, 0) & (BR_ACL_HASH_SIZE - 1);
}

static void acl_free(struct rcu_head *head)
{
	struct net_bridge_acl_entry *ent
		= container_of(head, struct net_bridge_acl_entry, rcu);
	kmem_cache_free(br_acl_cache, ent);
}

static __inline__ void acl_delete(struct net_bridge_acl_entry *f)
{
	hlist_del_rcu(&f->hlist);
	acl_free(&f->rcu);
}

void br_acl_cleanup(struct net_bridge *br)
{
	int i;

	spin_lock_bh(&br->acl_hash_lock);
	for (i = 0; i < BR_ACL_HASH_SIZE; i++) {
		struct net_bridge_acl_entry *acl;
		struct hlist_node *h, *n;

		hlist_for_each_entry_safe(acl, n, &br->acl_hash[i], hlist)
			acl_delete(acl);
	}
	spin_unlock_bh(&br->acl_hash_lock);
}

#ifndef ETHERTYPE_PAE
#define	ETHERTYPE_PAE	0x888e		/* EAPOL PAE/802.1x */
#endif

int br_acl_should_pass(struct net_bridge *br, struct sk_buff *skb, int type)
{
	struct ethhdr *eth_h;
	struct iphdr *ip_h;
	struct iphdr ip_data;
	struct tcpudphdr *tcpudp_h;
	struct tcpudphdr tcpudp_data;
	struct hlist_node *h;
	struct net_bridge_acl_entry *acl;
	unsigned char *src, *dst;
	int src_allow = 1;
	int dst_allow = 1;
	int src_block = 0;
	int dst_block = 0;
	int drop = 0;
	struct in_device * in_dev;

//	eth_h = (struct ethhdr *)skb->mac_header;
//	ip_h = (struct iphdr *)(skb->mac_header + sizeof(struct ethhdr));
//	tcpudp_h = (struct tcpudphdr *)(skb->mac_header + sizeof(struct ethhdr) + sizeof(struct iphdr));

	if (!br->acl_enabled)
		return 1;

	eth_h = (struct ethhdr *)eth_hdr(skb);
	src = eth_h->h_source;
	dst = eth_h->h_dest;

	if(eth_h->h_proto == __constant_htons(ETH_P_IP)) {
		ip_h = (struct iphdr *)skb_header_pointer(skb, 0, sizeof(ip_data), &ip_data);
		if(ip_h != NULL && (ip_h->protocol == IPPROTO_TCP || ip_h->protocol == IPPROTO_UDP)) {
			tcpudp_h = (struct tcpudphdr *)skb_header_pointer(skb, ip_h->ihl*4, sizeof(tcpudp_data), &tcpudp_data);
		}
	}

	if (eth_h->h_proto == __constant_htons(ETH_P_ARP))
		return 1;

	/* For wireless client authentication */
	if (eth_h->h_proto == __constant_htons(ETHERTYPE_PAE))
		return 1;

	if (ip_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) &&  (ip_h->saddr == __constant_htonl(QUANTENNA_IP) || ip_h->daddr == __constant_htonl(QUANTENNA_IP))) 
		return 1;

	if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_UDP && (tcpudp_h->dst == __constant_htons(67) || tcpudp_h->dst == __constant_htons(68))) {
		return 1;
	}
    /*for hyd packet from wired or wireless should always pass*/
    if (eth_h->h_proto == __constant_htons(0x893A)) {
        if (br->acl_debug)
            printk("interface is %s, Hyd packet always pass\n", skb->dev->name);
        return 1;
    }

	/* For the connection between RBR50 and RBS50 */
	if(strcmp(skb->dev->name, sysctl_2gbhapifname) == 0 || strcmp(skb->dev->name, sysctl_2gbhstaifname) == 0 || strcmp(skb->dev->name, sysctl_5gbhapifname) == 0 || strcmp(skb->dev->name, sysctl_5gbhstaifname) == 0){
		if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_UDP && tcpudp_h->dst == __constant_htons(53) && dnsnl) {
			if (br->acl_debug) 
				printk("dns packets interface  is %s\n", skb->dev->name);
		}
		else
		{
			if (br->acl_debug) 
				printk("interface  is %s\n", skb->dev->name);
			if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_TCP) {
				in_dev = (struct in_device *)br->dev->ip_ptr;
				if (in_dev && in_dev->ifa_list && inet_ifa_match(ip_h->daddr, in_dev->ifa_list))
					return 1;
			}
			else return 1;
		}
	}
   
	if (type & ACL_CHECK_SRC) {
		src_allow = 0;
		hlist_for_each_entry_rcu(acl, &br->acl_hash[br_mac_hash(src)], hlist) {
			if (!compare_ether_addr(acl->addr.addr, src)) {
				src_allow = 1;
				src_block = 1;
				break;
			}
		}
	}

	if ((type & ACL_CHECK_DST) && !(dst[0] & 1)) {
		dst_allow = 0;
		hlist_for_each_entry_rcu(acl, &br->acl_hash[br_mac_hash(dst)], hlist) {
			if (!compare_ether_addr(acl->addr.addr, dst)) {
				dst_allow = 1;
				dst_block = 1;
				break;
			}
		}
	}

	if (br->acl_type == 1) {
		/* just block the device in acl_hash */
		if (src_block == 1 || dst_block == 1)
			drop = 1;
	}
	else {
		/* just allow the device in acl_hash */
		if (src_allow == 0 || dst_allow == 0)
			drop = 1;
	}

	if (drop) {
		/* pass through the http packet to/from DUT */
#if support_guestportal_function
		if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_TCP &&
				(tcpudp_h->dst ==__constant_htons(80) || tcpudp_h->src == __constant_htons(80) ||
				 tcpudp_h->dst ==__constant_htons(443) || tcpudp_h->src == __constant_htons(443) ||
				 tcpudp_h->dst ==__constant_htons(13000) || tcpudp_h->src == __constant_htons(13000) ||
				 tcpudp_h->dst ==__constant_htons(12000) || tcpudp_h->src == __constant_htons(12000))) {
			if(unlikely(redirect_handler != NULL)) {
				if(redirect_handler(skb) != NF_ACCEPT)
					return 0;
				else
					return 1;
			} else if(unlikely(redirect_handler2 != NULL)) {
				if(redirect_handler2(skb) != NF_ACCEPT)
					return 0;
				else
					return 1;
			} else
#else
		if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_TCP && (tcpudp_h->dst ==__constant_htons(80) || tcpudp_h->src == __constant_htons(80) || tcpudp_h->dst ==__constant_htons(443) || tcpudp_h->src ==__constant_htons(443))) {
		//Fix satelliet attached device don't display block page,and base attached device access satelliet br0 don't display too.
		in_dev = (struct in_device *)br->dev->ip_ptr;
		if (in_dev && in_dev->ifa_list && (in_dev->ifa_list->ifa_local == ip_h->saddr || in_dev->ifa_list->ifa_local == ip_h->daddr || inet_ifa_match(ip_h->daddr, in_dev->ifa_list)))
#endif	
				return 1;
		}

		/* hijack the DNS */
		if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_UDP && tcpudp_h->src == __constant_htons(53)) {
			return 1;
		}
		if (ip_h != NULL && tcpudp_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP) && ip_h->protocol == IPPROTO_UDP && tcpudp_h->dst == __constant_htons(53) && dnsnl) {
			struct dns_nl_packet_msg *pm;
			struct nlmsghdr *nlh;
			size_t size, copy_len;
			struct sk_buff *skbnew;
			copy_len = skb->len;
			size = NLMSG_SPACE(sizeof(*pm) + copy_len);
			skbnew = alloc_skb(4096, GFP_ATOMIC);
			if (!skbnew) {
				skbnew = alloc_skb(size, GFP_ATOMIC);
				if (!skbnew) {
					return 0;
				}
			}
//			if (unlikely(skb_tailroom(skbnew) < (int)NLMSG_SPACE(size - NLMSG_ALIGN(sizeof(*nlh)))))
//				goto nlmsg_failure;
//			__nlmsg_put(skbnew, 0, 0, 0, (size - NLMSG_ALIGN(sizeof(*nlh))), 0);
			nlh = nlmsg_put(skbnew, 0, 0, 0, (size - NLMSG_ALIGN(sizeof(*nlh))),0);
			nlh->nlmsg_len = sizeof(*pm) + skb->len;
			pm = NLMSG_DATA(nlh);
			pm->data_len = skb->len;
			memcpy(pm->saddr, src, 6);
			skb_copy_bits(skb, 0, pm->data, skb->len);
			NETLINK_CB(skbnew).dst_group = 1;
			netlink_broadcast(dnsnl, skbnew, 0, 1, GFP_ATOMIC);
nlmsg_failure:
			return 0;
		}

		if (br->acl_debug) {
			char msg[1024];
			sprintf(msg, "ACL: drop packet to %s, src: %02x:%02x:%02x:%02x:%02x:%02x, dst: %02x:%02x:%02x:%02x:%02x:%02x, protocol 0x%04x",
				(type == ACL_CHECK_SRC) ? br->dev->name : skb->dev->name,
				src[0], src[1], src[2], src[3], src[4], src[5],
				dst[0], dst[1], dst[2], dst[3], dst[4], dst[5],
				eth_h->h_proto);
			if (ip_h != NULL && eth_h->h_proto == __constant_htons(ETH_P_IP)) {
				sprintf(msg + strlen(msg), ", IP protocol %d", ip_h->protocol);
				if (ip_h != NULL && tcpudp_h != NULL && ip_h->protocol == IPPROTO_UDP)
					sprintf(msg + strlen(msg), ", dest port %d", __constant_ntohs(tcpudp_h->dst));
			}
			printk("%s\n", msg);
		}
		return 0;
	}

	return 1;
}

int wl_acl_should_pass(struct net_device *dev, struct sk_buff *skb)
{
	struct net_device *passdev = NULL;
	struct net_bridge_port *p = NULL;

	if (((passdev = __dev_get_by_name(&init_net,CONFIG_WLAN_BASE_5G_AP_IFNAME)) == NULL) && ((passdev = __dev_get_by_name(&init_net,CONFIG_WLAN_BASE_2G_AP_IFNAME)) == NULL)) {
		return 1;
	}

	p = br_port_get_rcu(passdev);
	if (!p || p->br == NULL){
		return 1;
	}

	if(!p->br->acl_enabled){
		return 1;
	}

	skb_reset_mac_header(skb);
	skb_set_network_header(skb, sizeof(struct ethhdr));

	return br_acl_should_pass(p->br, skb, (ACL_CHECK_SRC | ACL_CHECK_DST));
}
EXPORT_SYMBOL(wl_acl_should_pass);

static inline struct net_bridge_acl_entry *acl_find(struct hlist_head *head, const unsigned char *addr)
{
	struct hlist_node *h;
	struct net_bridge_acl_entry *acl;

	hlist_for_each_entry_rcu(acl, head, hlist) {
		if (!compare_ether_addr(acl->addr.addr, addr))
			return acl;
	}
	return NULL;
}

static struct net_bridge_acl_entry *acl_create(struct hlist_head *head, const unsigned char *addr)
{
	struct net_bridge_acl_entry *acl;

	acl = kmem_cache_alloc(br_acl_cache, GFP_ATOMIC);
	if (acl) {
		memcpy(acl->addr.addr, addr, ETH_ALEN);
		hlist_add_head_rcu(&acl->hlist, head);
	}
	return acl;
}

static int acl_insert(struct net_bridge *br, const unsigned char *addr)
{
	struct hlist_head *head = &br->acl_hash[br_mac_hash(addr)];
	struct net_bridge_acl_entry *acl;

	if (!is_valid_ether_addr(addr))
		return -EINVAL;

	acl = acl_find(head, addr);
	if (acl)
		return 0;

	if (!acl_create(head, addr))
		return -ENOMEM;

	return 0;
}

int br_acl_insert(struct net_bridge *br, const unsigned char *addr)
{
	int ret;

	spin_lock_bh(&br->acl_hash_lock);
	ret = acl_insert(br, addr);
	spin_unlock_bh(&br->acl_hash_lock);
	return ret;
}

void br_acl_debug_onoff(struct net_bridge *br, int onoff)
{
	int i;

	if (onoff == 0) {
		br->acl_debug = 0;
		return;
	}

	printk("ACL status: %s\n", br->acl_enabled == 1 ? "enable" : "disable");
	if (br->acl_enabled == 0) {
		br->acl_debug = 1;
		return;
	}
	printk("ACL type: only %s in ACL list\n", br->acl_type == 1 ? "block" : "allow");
	printk("ACL list:\n");
	for (i = 0; i < BR_ACL_HASH_SIZE; i++) {
		struct net_bridge_acl_entry *acl;
		struct hlist_node *h, *n;
		unsigned char *addr;

		hlist_for_each_entry_safe(acl, n, &br->acl_hash[i], hlist) {
			addr = acl->addr.addr;
			printk("hash %d, %02x:%02x:%02x:%02x:%02x:%02x\n", i, addr[0], addr[1], addr[2], addr[3], addr[4], addr[5]);
		}
	}
	br->acl_debug = 1;
}
