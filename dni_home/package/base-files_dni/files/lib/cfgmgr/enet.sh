#the following line combines the last line to prevent this file from being sourced twice
if [ "x$enet_sh" = "x" ]; then enet_sh="sourced"
. /lib/cfgmgr/cfgmgr.sh

# this file is target depedent, it provids
# 1. following variables :
#      RawEth=         # name of raw eth NIF. not assigned means 2 eth NIFs, otherwise 1 eth NIF.
#      RawEthLan=      # name of raw eth NIF for lan.
#      RawEthWan=      # name of raw eth NIF for wan.
#      WanIndepPhy=    # 0 means RawEthWan doesn't have independent phy (ie. connects to switch).
#                      # 1 means RawEthWan has independent phy (ie. doesn't connects to switch).
# 2. following functions :
#      et_init()       # initialize ethernet & switch.
#      sw_configvlan() # configure switch vlan for all kind of opmode.
#

RawEth=
RawEthLan=eth1
RawEthWan=eth0
WanIndepPhy=0
enable_bond=0
BondEth=bond0
[ "$($CONFIG get ipv6_type)" = "bridge" ] && enable_bond=0

# for ap148-r7500 (8327 switch) : 
#    sw port0 -> CPU (RawEthWan)
#    sw port6 -> CPU (RawEthLan) 
#    sw port1 -> LAN4 
#    sw port2 -> LAN3 
#    sw port3 -> LAN2 
#    sw port4 -> LAN1 
#    sw port5 -> WAN 

ssdk_sh=/usr/sbin/ssdk_sh
swconfig=/sbin/swconfig
swconf=/tmp/sw.conf
ssdk_cmds_file=/tmp/ssdk.sh

et_landefmac()
{
	[ -f /tmp/lan_mac ] && cat /tmp/lan_mac || \
	echo "00:03:7f:$(hexdump -n 4 /dev/urandom | awk 'NR==1 {print $2$3}' \
	                 | sed 's/../&:/g' | cut -c 1-8)"
}

et_wandefmac()
{
	[ -f /tmp/wan_mac ] && cat /tmp/wan_mac || \
	echo "00:03:7f:$(hexdump -n 4 /dev/urandom | awk 'NR==1 {print $2$3}' \
	                 | sed 's/../&:/g' | cut -c 1-8)"
}

bond_init(){
	[ "$enable_bond" != "1" ] && return
	echo "2" > /sys/devices/virtual/net/bond0/bonding/mode
	echo "layer2+3" > /sys/devices/virtual/net/bond0/bonding/xmit_hash_policy
	echo "1000" > /sys/devices/virtual/net/bond0/bonding/miimon
	echo "+$RawEthWan" > /sys/devices/virtual/net/bond0/bonding/slaves
	echo "+$RawEthLan" > /sys/devices/virtual/net/bond0/bonding/slaves
}

et_init()
{
	sw_init
	$CONFIG set lan_factory_mac="$(et_landefmac)"
	$CONFIG set wan_factory_mac="$(et_wandefmac)"
	ethtool -K $RawEthLan gro on # enable ethlan GRO to improve smb write performance
}

bond_switch_set() {
	sw_printconf_add_switch > $swconf
	$swconfig dev switch0 load $swconf

	$ssdk_sh vlan entry create 1
	$ssdk_sh vlan entry create 2
	$ssdk_sh vlan member add 1 0 tagged
	$ssdk_sh vlan member add 1 6 tagged
	$ssdk_sh vlan member add 2 0 tagged
	$ssdk_sh vlan member add 2 6 tagged
	$ssdk_sh vlan member add 1 1 untagged
	$ssdk_sh vlan member add 1 2 untagged
	$ssdk_sh vlan member add 1 3 untagged
	$ssdk_sh vlan member add 1 4 untagged
	$ssdk_sh vlan member add 2 5 untagged
	$ssdk_sh portVlan defaultCvid set 1 1
	$ssdk_sh portVlan defaultCvid set 2 1
	$ssdk_sh portVlan defaultCvid set 3 1
	$ssdk_sh portVlan defaultCvid set 4 1
	$ssdk_sh portVlan defaultCvid set 5 2
	$ssdk_sh misc cpuVid set enable
	$ssdk_sh portvlan ingress set 1 check
	$ssdk_sh portvlan ingress set 2 check
	$ssdk_sh portvlan ingress set 3 check
	$ssdk_sh portvlan ingress set 4 check
	$ssdk_sh portvlan ingress set 5 check
	$ssdk_sh trunk group set 0 enable 0x41
	$ssdk_sh trunk hashmode set 0xf
}

bond_hashstop(){
	$ssdk_sh misc cpuVid set disable
	$ssdk_sh trunk group set 0 disable 0x41
	$ssdk_sh trunk hashmode set 0x0
}

sw_init()                                                                                            
{                                                                                                    
	echo "switch init"
	# workaround of switch hw issue on r7500                                                      
	#$ssdk_sh debug reg set 0x04 0x07700000 4 >/dev/null                                           
	#$ssdk_sh debug reg set 0xe4 0x0006a545 4 >/dev/null                                           

	#Fix Orbi TD1050 PC Lan link rate and Internet speed slow down when connect to TP SG1024D switch.
	# it is due to EEE mode. here disable EEE mode.
	$ssdk_sh debug phy set 0x0 0xd 0x7
	$ssdk_sh debug phy set 0x0 0xe 0x3c
	$ssdk_sh debug phy set 0x0 0xd 0x4007
	$ssdk_sh debug phy set 0x0 0xe 0x00
	$ssdk_sh debug phy set 0x0 0x00 0x1200

	$ssdk_sh debug phy set 0x1 0xd 0x7
	$ssdk_sh debug phy set 0x1 0xe 0x3c
	$ssdk_sh debug phy set 0x1 0xd 0x4007
	$ssdk_sh debug phy set 0x1 0xe 0x00
	$ssdk_sh debug phy set 0x1 0x00 0x1200

	$ssdk_sh debug phy set 0x2 0xd 0x7
	$ssdk_sh debug phy set 0x2 0xe 0x3c
	$ssdk_sh debug phy set 0x2 0xd 0x4007
	$ssdk_sh debug phy set 0x2 0xe 0x00
	$ssdk_sh debug phy set 0x2 0x00 0x1200
	
	$ssdk_sh debug phy set 0x3 0xd 0x7
	$ssdk_sh debug phy set 0x3 0xe 0x3c
	$ssdk_sh debug phy set 0x3 0xd 0x4007
	$ssdk_sh debug phy set 0x3 0xe 0x00
	$ssdk_sh debug phy set 0x3 0x00 0x1200

	$ssdk_sh debug phy set 0x4 0xd 0x7
	$ssdk_sh debug phy set 0x4 0xe 0x3c
	$ssdk_sh debug phy set 0x4 0xd 0x4007
	$ssdk_sh debug phy set 0x4 0xe 0x00
	$ssdk_sh debug phy set 0x4 0x00 0x1200
}                                                                                                    

sw_printconf_add_switch()
{
	cat <<EOF
config switch
	option name 'switch0'
	option reset '1'
	option enable_vlan '1'

EOF
}

sw_printconf_add_vlan() # $1: device, $2: vlan, $3: vid, $4: ports
{
	cat <<EOF
config switch_vlan
	option device '$1'
	option vlan '$2'
	option vid '$3'
	option ports '$4'

EOF
}

sw_tmpconf_start()
{
	rm -f $swconf.tmp*
}

sw_tmpconf_add_vlan() # $1: vlanindex, $2: vid, $3: ports
{
	cat <<EOF > "$swconf.tmp$1"
vid="$2"
ports="$3"
EOF
}

sw_tmpconf_adjust_vlan() # $1: vlanindex, $2: vid, $3: ports
{
	local vid ports i=1

	while [ $i -le $1 ]; do
		. "$swconf.tmp$i"
		if [ "$vid" = "$2" ]; then
			for p in $3; do
				echo $ports | grep -q '\<'$p'\>' && continue
				ports="$ports $p"
			done
			sw_tmpconf_add_vlan "$i" "$vid" "$ports"
			return 0
		fi
		i=$(($i + 1))
	done

	return 1
}

sw_tmpconf_generate_swconf() # $1: vlanindex
{
	local vid ports i=1

	sw_printconf_add_switch
	while [ $i -le $1 ]; do
		. "$swconf.tmp$i"
		sw_printconf_add_vlan "switch0" "$i" "$vid" "$ports"
		i=$(($i + 1))
	done
}

sw_print_ssdk_cmds_start()
{
	echo -n
}

sw_print_ssdk_cmds_set_ports_pri() # $1: ports, $2: pri
{
	local p

	for p in $ports; do
		echo $p | grep -q "t" && continue

		cat <<EOF
$ssdk_sh qos ptDefaultCpri set $p $2
EOF
	done
}

sw_print_ssdk_cmds_add_vlan_for_wan() # $1: vid
{
	cat <<EOF
$ssdk_sh vlan entry create $1
$ssdk_sh vlan entry append $1 $1 0,1 0,1 null null no no
EOF
}

sw_print_ssdk_cmds_add_vlan_for_wan_with_untag() # $1: vid
{
	cat <<EOF
$ssdk_sh vlan entry create $1
$ssdk_sh vlan entry append $1 $1 0,1 0 1 null no no
$ssdk_sh portvlan defaultcvid set 1 $1
EOF
}

sw_print_ssdk_cmds_add_vlan_for_arlo() # $1: ports $2 vid
{
	local p
	cat <<EOF
$ssdk_sh vlan entry create $2
$ssdk_sh vlan member add $2 0 tagged
EOF
	for p in $1; do
		echo $p |grep -q "t" && continue
	cat <<EOF
$ssdk_sh vlan member add $2 $p tagged
EOF
	done
}
sw_print_ssdk_cmds_add_vlan_for_lan() # $1: ports $2 vid
{
	local p
	cat <<EOF
$ssdk_sh vlan entry create $2
$ssdk_sh vlan member add $2 0 tagged
EOF
	for p in $1; do
		echo $p |grep -q "t" && continue
	cat <<EOF
$ssdk_sh vlan member add $2 $p untagged
EOF
	done
}

sw_print_ssdk_cmds_set_ports_default_cvid() #$1: ports, $2: vid
{
	local p

	for p in $1; do
		echo $p | grep -q "t" && continue

		cat <<EOF
$ssdk_sh portvlan defaultcvid set $p $2
EOF
	done
}

sw_print_ssdk_cmds_set_cpu_port_vid()
{
	cat <<EOF
$ssdk_sh misc cpuvid set enable
EOF
}

sw_configvlan_apmode()
{
	[ "$enable_bond" = "1" ] && bond_switch_set && return
	arlo_enale=`$CONFIG get enable_arlo_function`
	arlo_vid=`$CONFIG get wlg_ap_bh_vids`
	sw_printconf_add_switch > $swconf
	if [ "x$arlo_enale" = "x1" ] ; then
		sw_printconf_add_vlan "switch0" "1" "1" "0t 2 3 4" >> $swconf
		sw_printconf_add_vlan "switch0" "2" "2" "0t 1" >> $swconf
		sw_printconf_add_vlan "switch0" "3" "$arlo_vid" "0t 2t 3t 4t" >> $swconf
	else
		sw_printconf_add_vlan "switch0" "1" "1" "0 2 3 4" >> $swconf
		sw_printconf_add_vlan "switch0" "2" "2" "0 1" >> $swconf
	fi
	$swconfig dev switch0 load $swconf
}

sw_configvlan_normal()
{
	[ "$enable_bond" = "1" ] && bond_switch_set && return
	module_type=`cat /tmp/orbi_type`
	arlo_enale=`$CONFIG get enable_arlo_function`
	arlo_vid=`$CONFIG get wlg_ap_bh_vids`
	sw_printconf_add_switch > $swconf

if [ "x$($CONFIG get factory_tt3)" = "x1" ]; then
	sw_printconf_add_vlan "switch0" "1" "1" "1 2 3 4" >> $swconf
	sw_printconf_add_vlan "switch0" "2" "2" "0" >> $swconf
	$swconfig dev switch0 load $swconf
else
	if [ "x$arlo_enale" = "x1" ] ; then
		if [ "$module_type" = "Base" ]; then
			sw_printconf_add_vlan "switch0" "1" "1" "0t 2 3 4" >> $swconf
			sw_printconf_add_vlan "switch0" "2" "2" "0t 1" >> $swconf
			sw_printconf_add_vlan "switch0" "3" "$arlo_vid" "0t 2t 3t 4t" >> $swconf
		else 
			sw_printconf_add_vlan "switch0" "1" "1" "0t 1 2 3 4" >> $swconf
			sw_printconf_add_vlan "switch0" "2" "$arlo_vid" "0t 1t 2t 3t 4t" >> $swconf
		fi
		$swconfig dev switch0 load $swconf
	else
		sw_printconf_add_vlan "switch0" "1" "1" "0 2 3 4" >> $swconf
		sw_printconf_add_vlan "switch0" "2" "2" "0 1" >> $swconf
		if [ "$module_type" = "Base" ]; then
			$swconfig dev switch0 load $swconf
		fi
	fi
fi
}

i_mask() # $1: 1 / 2 / 3 / 4
{
	case $1 in
	2) echo 1 ;;
	3) echo 2 ;;
	4) echo 4 ;;
	esac
}

sw_configvlan_iptv() # $1: iptv_mask
{
	local i mask=$(($1 & 0x7))
	local ports1="0t" ports2="0t 1" ports3="0t" ports4="0t 1t"
	# ports1 is lan port, ports2 is wan port and ports4 is wan port in iptv vlan

	local iptv_vlan_enable=$($CONFIG get iptv_vlan_enable)
	local iptv_vlan=$($CONFIG get iptv_vlan)
	
	for i in 2 3 4; do
		if [ $(( $(i_mask $i) & $mask )) -eq 0 ]; then
			ports1="$ports1 $i"
			ports3="$ports3 ${i}t"
		else
			ports2="$ports2 $i"
		fi

		if [ "$iptv_vlan_enable" = "1" ]; then
			[ $(( $(i_mask $i) & $mask )) -eq 0 ] || ports4="$ports4 ${i}t"		
		fi
	done

	arlo_vid=`$CONFIG get wlg_ap_bh_vids`
	sw_printconf_add_switch > $swconf
	sw_printconf_add_vlan "switch0" "1" "1" "$ports1" >> $swconf
	sw_printconf_add_vlan "switch0" "2" "2" "$ports2" >> $swconf
	[ "$iptv_vlan_enable" = "1" ] && sw_printconf_add_vlan "switch0" "$iptv_vlan" "$iptv_vlan" "$ports4" >> $swconf
	##add arlo lan port##
	arlo_enale=`$CONFIG get enable_arlo_function`
	if [ "x$arlo_enale" = "x1" ] ; then
		sw_printconf_add_vlan "switch0" "3" "$arlo_vid" "$ports3" >> $swconf
	fi

	$swconfig dev switch0 load $swconf
}

sw_configvlan_vlan()
# $1: start
#     add -> $2: br/wan/lan, $3: vid, $4: mask, $5: pri
#     end
{
	case "$1" in
	start)
		sw_tmpconf_start
		sw_print_ssdk_cmds_start > $ssdk_cmds_file
		g_vlanindex=0
		;;
	add)
		local vid=$3 mask=$(($4 & 0x7)) pri=$5
		local i ports ports1="0t"

		case "$2" in
			br) ports="0t 1t" ;;
			lan) ports="0t" ;;
			wan) ports="0t 1" ;;
			vlan) ports="0t 1t" ;
		esac
		for i in 2 3 4; do
			[ $(( $(i_mask $i) & $mask )) -eq 0 ] || {
				ports="$ports $i" 
				ports1="$ports1 ${i}t"
			}
		done
		sw_tmpconf_adjust_vlan "$g_vlanindex" "$vid" "$ports" || {
			g_vlanindex=$(($g_vlanindex + 1))
			sw_tmpconf_add_vlan "$g_vlanindex" "$vid" "$ports"
		}
		[ "$2" == "br" -o "$2" == "vlan" ] && sw_print_ssdk_cmds_add_vlan_for_wan "$vid" >> $ssdk_cmds_file
		[ "$2" == "wan" ]  && sw_print_ssdk_cmds_add_vlan_for_wan_with_untag "$vid"  >> $ssdk_cmds_file
		if [ "$2" == "lan" ]; then
			sw_print_ssdk_cmds_add_vlan_for_lan "$ports" "$vid" >> $ssdk_cmds_file
			##add arlo lan port##
			arlo_enale=`$CONFIG get enable_arlo_function`
			if [ "x$arlo_enale" = "x1" ] ; then
				g_vlanindex=$(($g_vlanindex + 1))
				arlo_vid=`$CONFIG get wlg_ap_bh_vids`
				sw_tmpconf_add_vlan "$g_vlanindex" "$arlo_vid" "$ports1"
				sw_print_ssdk_cmds_add_vlan_for_arlo "$ports" "$arlo_vid" >> $ssdk_cmds_file
			fi
			sw_print_ssdk_cmds_set_ports_default_cvid "$ports" "$vid" >> $ssdk_cmds_file
		fi
		sw_print_ssdk_cmds_set_ports_pri "$ports" "$pri" >> $ssdk_cmds_file

		;;
	end)
		sw_tmpconf_generate_swconf $g_vlanindex > $swconf
		#$swconfig dev switch0 load $swconf
		sw_print_ssdk_cmds_set_cpu_port_vid >> $ssdk_cmds_file
		qt sh $ssdk_cmds_file
		;;
	esac
}

sw_configvlan() # $1 : normal/iptv/vlan/apmode/brmode
{
	local opmode=$1

	bond_hashstop
	shift
	case "$opmode" in
	normal) sw_configvlan_normal "$@" ;;
	apmode) sw_configvlan_apmode "$@" ;;
	iptv) sw_configvlan_iptv "$@" ;;
	vlan) sw_configvlan_vlan "$@" ;;
	#factory) sw_configvlan_factory "$@" ;;
	*) sw_configvlan_normal "$@" ;;
	esac
}

fi #-------------------- this must be the last line -----------------------------
