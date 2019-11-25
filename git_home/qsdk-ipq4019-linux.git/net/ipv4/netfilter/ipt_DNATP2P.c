/* This is a module which is used for source-NAT-P2P.
 * with concept helped by Rusty Russel <rusty at rustcorp.com.au>
 * and with code by Jesse Peng <tzuhsi.peng at msa.hinet.net>
 */

#include <linux/module.h>
#include <linux/skbuff.h>
#include <linux/netfilter.h>
#include <linux/netfilter/x_tables.h>
#include <net/netfilter/nf_nat_core.h>

#if 0
#define DEBUGP printk
#else
#define DEBUGP(format, args...)
#endif

/*
 * Defect ID : 331 Loopback mode is not supported
 *
 * Description 
 *   From the LAN PC of the same Router can not access the Router config using the
 * dyndns name, nor access a port which is forwarded to a computer on the lan.
 *   For example, If we set port forwarding to 192.168.1.2 and port 6000 and url is
 * http://3700.netgear.com, then we use the PC (192.168.1.3 or 192.168.1.2) to open
 * url and enter http://3700.netgear.com:6000 to access the service on 192.168.1.2.
 */

static void dnatp2p_convert_range(struct nf_nat_range *dst,
				  const struct nf_nat_ipv4_range *src)
{
	memset(&dst->min_addr, 0, sizeof(dst->min_addr));
	memset(&dst->max_addr, 0, sizeof(dst->max_addr));

	dst->flags       = src->flags;
	dst->min_addr.ip = src->min_ip;
	dst->max_addr.ip = src->max_ip;
	dst->min_proto   = src->min;
	dst->max_proto   = src->max;
}

#ifdef CONFIG_IP_NF_TARGET_DNAT_PORT_RANGE_ONE_BY_ONE
static unsigned int ipt_dnatp2p_target(struct sk_buff *skb, const struct xt_action_param *par)
{
	struct nf_conn *ct;
	enum ip_conntrack_info ctinfo;
	const struct nf_nat_ipv4_multi_range_compat *mr = par->targinfo;
	const struct nf_nat_ipv4_range *orig_range = &mr->range[0];
	struct nf_nat_ipv4_multi_range_compat tmp_mr;
	struct nf_nat_ipv4_multi_range_compat *tmp_mr_ptr;
	struct nf_nat_range range;
	/* Use host order for calculation */
	u_int16_t add_num, new_port;

	tmp_mr_ptr = &tmp_mr;
	memcpy(tmp_mr_ptr, mr, sizeof(struct nf_nat_ipv4_multi_range_compat));

	NF_CT_ASSERT(hooknum == NF_INET_PRE_ROUTING);

	ct = nf_ct_get(skb, &ctinfo);

	/* Connection must be valid and new. */
	NF_CT_ASSERT(ct && (ctinfo == IP_CT_NEW || ctinfo == IP_CT_RELATED));

	if (orig_range->flags & IP_NAT_RANGE_PORT_RANGE_ONE_BY_ONE) {
		/* Get original port, and calculate num added to make port correspond one by one */
		add_num = ntohs(ct->tuplehash[IP_CT_DIR_ORIGINAL].tuple.dst.u.all) -
			  ntohs(orig_range->port_forwarding_external_starting_port);
		new_port = ntohs(orig_range->min.all) + add_num;

		tmp_mr_ptr->range[0].min.all = tmp_mr_ptr->range[0].max.all = htons(new_port);

		if (net_ratelimit()) {
			printk("[LAN access from remote] from %pI4:%u to %pI4:%u\n",
					&(ct->tuplehash[IP_CT_DIR_ORIGINAL].tuple.src.u3),
					ntohs(ct->tuplehash[IP_CT_DIR_ORIGINAL].tuple.src.u.all),
					&(orig_range->min_ip), new_port);
		}
	}

	/*
	 * To support Loopback mode, we implement new target called 'DNATP2P' which co-works with 'HAIRPIN'.
	 * It works like 'DNAT', such as adding a Port Forwarding item "FTP 20 21 192.168.1.13", if loopback
	 * mode supporting, then the conntack SHOULD be as bellowing (WAN: 172.17.145.38; LAN: 192.168.1.2):
	 *
	 * tcp ESTABLISHED
	 * [ORIGINAL] src=192.168.1.2  dst=172.17.145.38 sport=1155 dport=21
	 * [REPLY]    src=192.168.1.13 dst=172.17.145.38 sport=21 dport=1155
	 *
	 * It means using 'DNATP2P' to change the destination IP to the Forwarded-LAN-Server (called 'DNAT')
	 * firstly, then this conntrack has 'IPS_SNATP2P_DST_DONE_BIT' bit set; after that, the 'HAIRPIN' will
	 * change the source IP to the Router-WAN-Side-IP (called 'SNAT'). These actions make the packets look
	 * like coming from Internet side.
	 */
	ct->status |= IPS_SNATP2P_DST;

#if defined(CONFIG_NF_CONNTRACK_NAT_MANAGEMENT)
	/* The session is initiated from inside (LAN), it matches a
	 * Port Forwarding, or UPnP Port Mapping rule. -- [DNATP2P]*/
	ct->status |= IPS_NAT_STATIC_HIGH_PRIORITY;
#endif

	dnatp2p_convert_range(&range, &tmp_mr_ptr->range[0]);
	return nf_nat_setup_info(ct, &range, NF_NAT_MANIP_DST);
}
#else
static unsigned int ipt_dnatp2p_target(struct sk_buff *skb, const struct xt_action_param *par)
{
	struct nf_conn *ct;
	enum ip_conntrack_info ctinfo;
	const struct nf_nat_ipv4_multi_range_compat *mr = par->targinfo;
	struct nf_nat_range range;

	NF_CT_ASSERT(hooknum == NF_INET_PRE_ROUTING);

	ct = nf_ct_get(skb, &ctinfo);

	/* Connection must be valid and new. */
	NF_CT_ASSERT(ct && (ctinfo == IP_CT_NEW || ctinfo == IP_CT_RELATED));

	/*
	 * To support Loopback mode, we implement new target called 'DNATP2P' which co-works with 'HAIRPIN'.
	 * It works like 'DNAT', such as adding a Port Forwarding item "FTP 20 21 192.168.1.13", if loopback
	 * mode supporting, then the conntack SHOULD be as bellowing (WAN: 172.17.145.38; LAN: 192.168.1.2):
	 *
	 * tcp ESTABLISHED
	 * [ORIGINAL] src=192.168.1.2  dst=172.17.145.38 sport=1155 dport=21
	 * [REPLY]    src=192.168.1.13 dst=172.17.145.38 sport=21 dport=1155
	 *
	 * It means using 'DNATP2P' to change the destination IP to the Forwarded-LAN-Server (called 'DNAT')
	 * firstly, then this conntrack has 'IPS_SNATP2P_DST_DONE_BIT' bit set; after that, the 'HAIRPIN' will
	 * change the source IP to the Router-WAN-Side-IP (called 'SNAT'). These actions make the packets look
	 * like coming from Internet side.
	 */
	ct->status |= IPS_SNATP2P_DST;

#if defined(CONFIG_NF_CONNTRACK_NAT_MANAGEMENT)
	/* The session is initiated from inside (LAN), it matches a
	 * Port Forwarding, or UPnP Port Mapping rule. -- [DNATP2P]*/
	ct->status |= IPS_NAT_STATIC_HIGH_PRIORITY;
#endif

	dnatp2p_convert_range(&range, &mr->range[0]);
	return nf_nat_setup_info(ct, &range, NF_NAT_MANIP_DST);
}
#endif

static int ipt_dnatp2p_checkentry(const struct xt_tgchk_param *par)
{
	const struct nf_nat_ipv4_multi_range_compat *mr = par->targinfo;

	/* Must be a valid range */
	if (mr->rangesize != 1) {
		printk("DNATP2P: multiple ranges no longer supported\n");
		return -EINVAL;
	}

	return 0;
}

static struct xt_target ipt_dnatp2p_reg = {
	.name		= "DNATP2P",
	.family		= NFPROTO_IPV4,
	.target		= ipt_dnatp2p_target,
	.checkentry	= ipt_dnatp2p_checkentry,
	.targetsize	= sizeof(struct nf_nat_ipv4_multi_range_compat),
	.table		= "nat",
	.hooks		= NF_INET_PRE_ROUTING,
	.me		= THIS_MODULE,
};

static int __init init(void)
{
	if (xt_register_target(&ipt_dnatp2p_reg))
		return -EINVAL;

	return 0;
}

static void __exit fini(void)
{
	xt_unregister_target(&ipt_dnatp2p_reg);
}

module_init(init);
module_exit(fini);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("");
MODULE_DESCRIPTION("Firewall and NAT");
