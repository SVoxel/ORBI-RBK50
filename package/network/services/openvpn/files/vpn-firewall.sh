#!/bin/sh

CONFIG=/bin/config


wan_proto=$(config get wan_proto)
lan_ipaddr=$(config get lan_ipaddr)
mask=$(config get lan_netmask)
tun_subnet=$(tun_net $lan_ipaddr $mask)
wan_interface="$($CONFIG get dgc_netif_wan_if)"
ppp_interace="$($CONFIG get dgc_netif_ppp_if)"
lan_interface="$($CONFIG get dgc_netif_lan_if)"
if [ "$wan_proto" = "static" ] || [ "$wan_proto" = "dhcp" ]; then
	iptables -t nat -A ${wan_interface}_masq -s $tun_subnet/$mask -j MASQUERADE
else
	iptables -t nat -A ${ppp_interace}_masq -s $tun_subnet/$mask -j MASQUERADE
fi	
iptables -I INPUT 10 -i tun0 -j ${lan_interface}_in
iptables -I OUTPUT  11 -o tun0 -j fw2loc
iptables -I FORWARD 3 -i tun0 -j ${lan_interface}_fwd
iptables -A ${lan_interface}_fwd -o tun0 -j loc2loc
if [ "$wan_proto" = "static" ] || [ "$wan_proto" = "dhcp" ]; then
	iptables -A ${wan_interface}_fwd -o tun0 -j net2loc
else
	iptables -A ${ppp_interace}_fwd -o tun0 -j net2loc
fi
iptables -I loc2net 5 -s $tun_subnet/$mask -j ACCEPT
