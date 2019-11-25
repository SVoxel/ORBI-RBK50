/*
 *	add a moudle to match ip array
 * 			Copyright (C) 2009 Delta Networks Inc.
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/skbuff.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <linux/icmp.h>

#include <linux/version.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,30)
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#else
#include <linux/netfilter_ipv4.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ip_conntrack.h>
#include <linux/netfilter_ipv4/ip_conntrack_core.h>
#include <linux/netfilter_ipv4/ip_conntrack_tuple.h>
#endif

#if 0
#define DEBUGP printk
#else
#define DEBUGP(format, args...)
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,30)
#define ipt_register_match(match)               xt_register_matches(match, 1)
#define ipt_unregister_match(match)             xt_unregister_matches(match, 1)
#endif

#define MAXIPNUM 16

struct ipt_iparray_info {
	int inverse;
	__u32 iparray[MAXIPNUM];
};


/* It is simple, need to be improved ... but now, it works well :) */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,35)
static bool ipt_iparray_match(const struct sk_buff *skb, struct xt_action_param *par)
#elif LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,30)
static bool ipt_iparray_match(const struct sk_buff *skb,
		const struct xt_match_param * par)
#else
static int ipt_iparray_match(const struct sk_buff *skb,
		const struct net_device *in,
		const struct net_device *out,
		const void *matchinfo,
		int offset,
		int *hotdrop)
#endif
{
	int i, flag;
	struct iphdr *iph;
	const struct ipt_iparray_info *info;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,30)
	iph = ip_hdr(skb);
	info = par->matchinfo; 
#else
	iph = skb->nh.iph;
	info = matchinfo; 
#endif

	flag = 0;
	for (i=0; i<MAXIPNUM; i++) {
		if(info->iparray[i] == 0)
			break;

		if(iph->saddr == info->iparray[i]){
			flag = 1;
			break;
		}
	}

	if(flag && info->inverse == 0)
		return 1;
	if(!flag && info->inverse == 1)
		return 1;

	return 0;
}

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,30)
static int ipt_iparray_match_checkentry(const char *tablename,
		const struct ipt_ip *ip,
		void *matchinfo,
		unsigned int matchsize,
		unsigned int hook_mask)
{
	if(ip->proto == IPPROTO_UDP || ip->proto == IPPROTO_TCP)
		return 1;

	return 0;
}
#endif

#if LINUX_VERSION_CODE >= KERNEL_VERSION(3,4,0)
static struct xt_match iparray_match = {
#else
static struct ipt_match iparray_match = {
#endif
	.name		= "iparray",
	.match		= ipt_iparray_match,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,30)
	.family		= NFPROTO_IPV4,
	.matchsize	= sizeof(struct ipt_iparray_info),
#else
	.checkentry	= ipt_iparray_match_checkentry,
#endif
	.me		= THIS_MODULE
};

static int __init init(void)
{
	return ipt_register_match(&iparray_match);
}

static void __exit fini(void)
{
	ipt_unregister_match(&iparray_match);
}

module_init(init);
module_exit(fini);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("");
MODULE_DESCRIPTION("Firewall and NAT");
