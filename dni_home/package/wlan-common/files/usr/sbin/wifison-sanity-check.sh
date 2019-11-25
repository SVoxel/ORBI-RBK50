#!/bin/sh
#WIFI
DEFAULT_WIFI_REPACD_CREATE_VAP=0
DEFAULT_WIFI_DBDC_ENABLE=0
DEFAULT_WIFI_BH_WSPLCD_UNMANAGED=1
DEFAULT_WIFI_BH_REPACD_SEC_UNMANAGED=1
DEFAULT_WIFI_UL_HYST=3

#HYD
DEFAULT_HYD_ENABLE=1
DEFAULT_HYD_RBR_MODE="HYROUTER"
DEFAULT_HYD_RBS_MODE="HYCLIENT"
DEFAULT_HYD_MAXMEDIUMUTILIZATION_W2=70
DEFAULT_HYD_MAXMEDIUMUTILIZATION_W5=99
DEFAULT_HYD_MAXMEDIUMUTILIZATIONFORLC_W2=0
DEFAULT_HYD_MAXMEDIUMUTILIZATIONFORLC_W5=99
DEFAULT_HYD_MAXHACTIVEENTRIES=8192
DEFAULT_HYD_NOTIFICATION_THROTTLING_WINDOW=1
DEFAULT_HYD_PERIODIC_QUERY_INTERVAL=15
DEFAULT_HYD_IEEE1905SETTINGS_AVOIDDUPRENEW=1
DEFAULT_HYD_IEEE1905SETTINGS_AVOIDDUPTOPOLOGYNOTIFICATION=1

#WSPLCD
DEFAULT_WSPLCD_HYFISECURITY=1

#LBD
DEFAULT_LBD_ENABLE=0
DEFAULT_LBD_RSSISTEERINGPOINT_UG=15
DEFAULT_LBD_NORMALINACTTIMEOUT=5
DEFAULT_LBD_OVERLOADINACTTIMEOUT=5
DEFAULT_LBD_TXRATEXINGTHRESHOLD_UG=20000
DEFAULT_LBD_RATERSSIXINGTHRESHOLD_UG=20
DEFAULT_LBD_MARKADVCLIENTASDUALBAND=1
DEFAULT_LBD_MUOVERLOADTHRESHOLD_W5=99
DEFAULT_LBD_MUOVERLOADTHRESHOLD_W2=80
DEFAULT_LBD_MUSAFETYTHRESHOLD_W5=90
DEFAULT_LBD_MUSAFETYTHRESHOLD_W2=50
DEFAULT_LBD_STEERINGPROHIBITTIME=120
DEFAULT_LBD_BTMSTEERINGPROHIBITSHORTTIME=15
DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP=25
DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE=25
DEFAULT_LBD_APSTEERTOROOTMINRSSIINCTHRESHOLD=10
DEFAULT_LBD_APSTEERTOLEAFMINRSSIINCTHRESHOLD=10
DEFAULT_LBD_APSTEERTOPEERMINRSSIINCTHRESHOLD=10
DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP_W5=20
DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE_W5=20
DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP_W2=35
DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE_W2=35
DEFAULT_LBD_DOWNLINKRSSITHRESHOLD_W5=-70
DEFAULT_LBD_MUREPORTPERIOD=15
DEFAULT_LBD_LOADBALANCINGALLOWEDMAXPERIOD=10
DEFAULT_LBD_11KPROHIBITTIMESHORT=15
DEFAULT_LBD_11KPROHIBITTIMELONG=60
DEFAULT_LBD_STEERINGUNFRIENDLYTIME=600
DEFAULT_LBD_STARTINBTMACTIVESTATE=1
DEFAULT_LBD_MAXCONSECUTIVEBTMFAILURESASACTIVE=6
DEFAULT_LBD_TSEERING=15
DEFAULT_LBD_AUTHREJMAX=2
DEFAULT_LBD_BTMUNFRIENDLYTIME=30
DEFAULT_LBD_MAXBTMUNFRIENDLY=120
DEFAULT_LBD_MAXBTMACTIVEUNFRIENDLY=120
DEFAULT_LBD_IAS_ENABLE_W2=0
DEFAULT_LBD_IAS_ENABLE_W5=0
DEFAULT_LBD_BLACKLISTTIME=60
DEFAULT_LBD_MARKADVCLIENTASDUALBAND=0

#REPACD
DEFAULT_REPACD_ENABLE=1
DEFAULT_REPACD_ENABLESTEERING=1
DEFAULT_REPACD_5GBACKHAULEVALTIMESHORT=330
DEFAULT_REPACD_5GBACKHAULEVALTIMELONG=1800
DEFAULT_REPACD_MOVEFROMCAPSNRHYSTERESIS5G=5
DEFAULT_REPACD_RATETHRESHOLDMAX5GINPERCENT=95
DEFAULT_REPACD_RATESCALINGFACTOR=85

#SMP_AFFINITY
DEFAULT_SMP_AFFINITY_174=
DEFAULT_SMP_AFFINITY_200=
DEFAULT_SMP_AFFINITY_201=

total_error_cnt=0

show_result(){
    item=$1
    got_result=$2
    expected_result=$3

    printf "\tChecking %-55s %10s" $item ".........."
    if [ "$expected_result" = "$got_result" ]; then
        printf "  %6s  [ %s ]\n" "PASSED" $got_result
    else
        printf " %8s [ %s != %s ]\n" "*FAILED*" $expected_result $got_result
        total_error_cnt=$(( $total_error_cnt + 1 ))
    fi
}

wifi_devices=`uci show wireless | grep "wifi-device" | sed 's/[.=]/ /g' | awk '{print $2}'`
orbi_project=`cat /tmp/orbi_project`
orbi_type=`cat /tmp/orbi_type`
model_id=`artmtd -r board_model_id | grep -o '..$'`    # judge project through the last two char of board_model_id. ex : RBR'50'

if [ "$orbi_project" = "Orbimini"  ]; then
    DEFAULT_SMP_AFFINITY_174=8
    DEFAULT_SMP_AFFINITY_200=4
    DEFAULT_SMP_AFFINITY_201=2
    DEFAULT_WIFI_CAPRSSI=30
    DEFAULT_REPACD_PREFERCAPSNRTHRESHOLD=30
    DEFAULT_REPACD_RATETHRESHOLDMIN5GINPERCENT=35
    
    case $model_id in
	"20")
	        DEFAULT_LBD_RSSISTEERINGPOINT_UG=22
	        DEFAULT_LBD_RATERSSIXINGTHRESHOLD_UG=31
	        DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP_W5=33
	        DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE_W5=33
	        DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP_W2=40
	        DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE_W2=40
	        DEFAULT_REPACD_RSSITHRESHOLDPREFER2GBACKHAUL=-82
	        ;;
	"40")
	        DEFAULT_REPACD_RSSITHRESHOLDPREFER2GBACKHAUL=-82
	        ;;
    esac
elif [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbipro"  ]; then
    DEFAULT_SMP_AFFINITY_174=2
    DEFAULT_SMP_AFFINITY_200=4
    DEFAULT_SMP_AFFINITY_201=8
    DEFAULT_WIFI_CAPRSSI=30
    DEFAULT_REPACD_PREFERCAPSNRTHRESHOLD=20
    DEFAULT_REPACD_RATETHRESHOLDMIN5GINPERCENT=25
    DEFAULT_REPACD_RSSITHRESHOLDPREFER2GBACKHAUL=-82
fi

#check region
country_code="`config get wl_country`"
if [ "$country_code" = "10"  ]; then
    DEFAULT_LBD_MARKADVCLIENTASDUALBAND=1
fi

# Check WiFi device related setting
for wi in $wifi_devices; do
    printf " Checking WiFi Device %s\n" $wi
    repacd_create_vap=$(uci -q get wireless.${wi}.repacd_auto_create_vaps)
    dbdc_enable=$(uci -q get wireless.${wi}.dbdc_enable)
    show_result "wireless.${wi}.repacd_auto_create_vaps" "$repacd_create_vap" "$DEFAULT_WIFI_REPACD_CREATE_VAP"
    show_result "wireless.${wi}.dbdc_enable" "$dbdc_enable" "$DEFAULT_WIFI_DBDC_ENABLE"
done

# Check WiFi virtual interface related setting
wifi_iface=`uci show wireless | grep "\.device=" | awk -F. '{print $2}'`
for wi in $wifi_iface; do
    backhaul=$(uci -q get wireless.${wi}.backhaul)
    if [ "x$backhaul" = "x1" ]; then
        printf " Checking backhaul related setting for %s\n" $wi
        wsplcd_unmanaged=$(uci -q get wireless.${wi}.wsplcd_unmanaged)
        repacd_security_unmanaged=$(uci -q get wireless.${wi}.repacd_security_unmanaged)
        show_result "wireless.${wi}.wsplcd_unmanaged" "$wsplcd_unmanaged" "$DEFAULT_WIFI_BH_WSPLCD_UNMANAGED"
        show_result "wireless.${wi}.repacd_security_unmanaged" "$repacd_security_unmanaged" "$DEFAULT_WIFI_BH_REPACD_SEC_UNMANAGED"
    fi
done

#Check smp affinity parameters
printf " Checking smp affinity parameters\n"
Irq_174_Smp_Affinity=`cat /proc/irq/174/smp_affinity`
show_result "smp.affinity.174" "$Irq_174_Smp_Affinity" "$DEFAULT_SMP_AFFINITY_174"

Irq_200_Smp_Affinity=`cat /proc/irq/200/smp_affinity`
show_result "smp.affinity.200" "$Irq_200_Smp_Affinity" "$DEFAULT_SMP_AFFINITY_200"

Irq_201_Smp_Affinity=`cat /proc/irq/201/smp_affinity`
show_result "smp.affinity.201" "$Irq_201_Smp_Affinity" "$DEFAULT_SMP_AFFINITY_201"

#Check ebtable sanity status in base
if [ "$orbi_type" = "Base" ]; then
    printf " Checking ebtables sanity status\n"

    if [ "$orbi_project" = "Orbimini"  ]; then
        wl2g_bh_athx=`config get wlg_BACKHAUL_STA`
        wl5g_bh_athx=`config get wla_BACKHAUL_STA`
    elif [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbipro"  ]; then
        wl2g_bh_athx=`config get wlg_BACKHAUL_STA`
        wl5g_bh_athx=`config get wla_2nd_BACKHAUL_STA`
    fi
    
    ebtable_wl2g_status=`ebtables -L | grep wl2g_bh_athx`
    show_result "ebtables.wl2g.status" "$ebtable_wl2g_status" ""

    ebtable_wl5g_status=`ebtables -L | grep wl5g_bh_athx`
    show_result "ebtables.wl5g.status" "$ebtable_wl5g_status" ""
fi

#Check hyd related setting
printf " Checking hyd related setting\n"
enable=$(uci -q get hyd.config.Enable)
show_result "hyd.config.Enable" "$enable" "$DEFAULT_HYD_ENABLE"

board=$(cat /tmp/board_model_id)

if [ "$orbi_type" = "Base" ]; then
    rbr_mode=$(uci -q get hyd.config.Mode)
    show_result "hyd.config.Mode" "$rbr_mode" "$DEFAULT_HYD_RBR_MODE"
fi

if [ "$orbi_type" = "Satellite" ]; then
    rbs_mode=$(uci -q get hyd.config.Mode)
    show_result "hyd.config.Mode" "$rbs_mode" "$DEFAULT_HYD_RBS_MODE"
fi

PathChWlan_MaxMediumUtilization_W2=$(uci -q get hyd.PathChWlan.MaxMediumUtilization_W2)
show_result "hyd.PathChWlan.MaxMediumUtilization_W2" "$PathChWlan_MaxMediumUtilization_W2" "$DEFAULT_HYD_MAXMEDIUMUTILIZATION_W2"

PathChWlan_MaxMediumUtilization_W5=$(uci -q get hyd.PathChWlan.MaxMediumUtilization_W5)
show_result "hyd.PathChWlan.MaxMediumUtilization_W5" "$PathChWlan_MaxMediumUtilization_W5" "$DEFAULT_HYD_MAXMEDIUMUTILIZATION_W5"

PathChWlan_MaxMediumUtilizationForLC_W2=$(uci -q get hyd.PathChWlan.MaxMediumUtilizationForLC_W2)
show_result "hyd.PathChWlan.MaxMediumUtilizationForLC_W2" "$PathChWlan_MaxMediumUtilizationForLC_W2" "$DEFAULT_HYD_MAXMEDIUMUTILIZATIONFORLC_W2"

PathChWlan_MaxMediumUtilizationForLC_W5=$(uci -q get hyd.PathChWlan.MaxMediumUtilizationForLC_W5)
show_result "hyd.PathChWlan.MaxMediumUtilizationForLC_W5" "$PathChWlan_MaxMediumUtilizationForLC_W5" "$DEFAULT_HYD_MAXMEDIUMUTILIZATIONFORLC_W5"

HSPECEst_MaxHActiveEntries=$(uci -q get hyd.HSPECEst.MaxHActiveEntries)
show_result "hyd.HSPECEst.MaxHActiveEntries" "$HSPECEst_MaxHActiveEntries" "$DEFAULT_HYD_MAXHACTIVEENTRIES"

Topology_NOTIFICATION_THROTTLING_WINDOW=$(uci -q get hyd.Topology.NOTIFICATION_THROTTLING_WINDOW)
show_result "hyd.Topology.NOTIFICATION_THROTTLING_WINDOW" "$Topology_NOTIFICATION_THROTTLING_WINDOW" "$DEFAULT_HYD_NOTIFICATION_THROTTLING_WINDOW"

Topology_PERIODIC_QUERY_INTERVAL=$(uci -q get hyd.Topology.PERIODIC_QUERY_INTERVAL)
show_result "hyd.Topology.PERIODIC_QUERY_INTERVAL" "$Topology_PERIODIC_QUERY_INTERVAL" "$DEFAULT_HYD_PERIODIC_QUERY_INTERVAL"

IEEE1905Settings_AvoidDupRenew=$(uci -q get hyd.IEEE1905Settings.AvoidDupRenew)
show_result "hyd.IEEE1905Settings.AvoidDupRenew" "$IEEE1905Settings_AvoidDupRenew" "$DEFAULT_HYD_IEEE1905SETTINGS_AVOIDDUPRENEW"

IEEE1905Settings_AvoidDupTopologyNotification=$(uci -q get hyd.IEEE1905Settings.AvoidDupTopologyNotification)
show_result "hyd.IEEE1905Settings.AvoidDupTopologyNotification" "$IEEE1905Settings_AvoidDupTopologyNotification" "$DEFAULT_HYD_IEEE1905SETTINGS_AVOIDDUPTOPOLOGYNOTIFICATION"

#Check wsplcd related setting
printf " Checking wsplcd related setting\n"
config_HyFiSecurity=$(uci -q get wsplcd.config.HyFiSecurity)
show_result "wsplcd.config.HyFiSecurity" "$config_HyFiSecurity" "$DEFAULT_WSPLCD_HYFISECURITY"

#Check lbd related setting
printf " Checking lbd related setting\n"
config_Enable=$(uci -q get lbd.config.Enable)
show_result "lbd.config.Enable" "$config_Enable" "$DEFAULT_LBD_ENABLE"

IdleSteer_RSSISteeringPoint_UG=$(uci -q get lbd.IdleSteer.RSSISteeringPoint_UG)
show_result "lbd.IdleSteer.RSSISteeringPoint_UG" "$IdleSteer_RSSISteeringPoint_UG" "$DEFAULT_LBD_RSSISTEERINGPOINT_UG"

IdleSteer_NormalInactTimeout=$(uci -q get lbd.IdleSteer.NormalInactTimeout)
show_result "lbd.IdleSteer.NormalInactTimeout" "$IdleSteer_NormalInactTimeout" "$DEFAULT_LBD_NORMALINACTTIMEOUT"

IdleSteer_OverloadInactTimeout=$(uci -q get lbd.IdleSteer.OverloadInactTimeout)
show_result "lbd.IdleSteer.OverloadInactTimeout" "$IdleSteer_OverloadInactTimeout" "$DEFAULT_LBD_OVERLOADINACTTIMEOUT"

ActiveSteer_TxRateXingThreshold_UG=$(uci -q get lbd.ActiveSteer.TxRateXingThreshold_UG)
show_result "lbd.ActiveSteer.TxRateXingThreshold_UG" "$ActiveSteer_TxRateXingThreshold_UG" "$DEFAULT_LBD_TXRATEXINGTHRESHOLD_UG"

ActiveSteer_RateRSSIXingThreshold_UG=$(uci -q get lbd.ActiveSteer.RateRSSIXingThreshold_UG)
show_result "lbd.ActiveSteer.RateRSSIXingThreshold_UG" "$ActiveSteer_RateRSSIXingThreshold_UG" "$DEFAULT_LBD_RATERSSIXINGTHRESHOLD_UG"

StaDB_MarkAdvClientAsDualBand=$(uci -q get lbd.StaDB.MarkAdvClientAsDualBand)
show_result "lbd.StaDB.MarkAdvClientAsDualBand" "$StaDB_MarkAdvClientAsDualBand" "$DEFAULT_LBD_MARKADVCLIENTASDUALBAND"

Offload_MUOverloadThreshold_W5=$(uci -q get lbd.Offload.MUOverloadThreshold_W5)
show_result "lbd.Offload.MUOverloadThreshold_W5" "$Offload_MUOverloadThreshold_W5" "$DEFAULT_LBD_MUOVERLOADTHRESHOLD_W5"

Offload_MUOverloadThreshold_W2=$(uci -q get lbd.Offload.MUOverloadThreshold_W2)
show_result "lbd.Offload.MUOverloadThreshold_W2" "$Offload_MUOverloadThreshold_W2" "$DEFAULT_LBD_MUOVERLOADTHRESHOLD_W2"

Offload_MUSafetyThreshold_W5=$(uci -q get lbd.Offload.MUSafetyThreshold_W5)
show_result "lbd.Offload.MUSafetyThreshold_W5" "$Offload_MUSafetyThreshold_W5" "$DEFAULT_LBD_MUSAFETYTHRESHOLD_W5"

Offload_MUSafetyThreshold_W2=$(uci -q get lbd.Offload.MUSafetyThreshold_W2)
show_result "lbd.Offload.MUSafetyThreshold_W2" "$Offload_MUSafetyThreshold_W2" "$DEFAULT_LBD_MUSAFETYTHRESHOLD_W2"

SteerExec_SteeringProhibitTime=$(uci -q get lbd.SteerExec.SteeringProhibitTime)
show_result "lbd.SteerExec.SteeringProhibitTime" "$SteerExec_SteeringProhibitTime" "$DEFAULT_LBD_STEERINGPROHIBITTIME"

SteerExec_BTMSteeringProhibitShortTime=$(uci -q get lbd.SteerExec.BTMSteeringProhibitShortTime)
show_result "lbd.SteerExec.BTMSteeringProhibitShortTime" "$SteerExec_BTMSteeringProhibitShortTime" "$DEFAULT_LBD_BTMSTEERINGPROHIBITSHORTTIME"

APSteer_LowRSSIAPSteerThreshold_CAP=$(uci -q get lbd.APSteer.LowRSSIAPSteerThreshold_CAP)
show_result "lbd.APSteer.LowRSSIAPSteerThreshold_CAP" "$APSteer_LowRSSIAPSteerThreshold_CAP" "$DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP"

APSteer_LowRSSIAPSteerThreshold_RE=$(uci -q get lbd.APSteer.LowRSSIAPSteerThreshold_RE)
show_result "lbd.APSteer.LowRSSIAPSteerThreshold_RE" "$APSteer_LowRSSIAPSteerThreshold_RE" "$DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE"

APSteer_APSteerToRootMinRSSIIncThreshold=$(uci -q get lbd.APSteer.APSteerToRootMinRSSIIncThreshold)
show_result "lbd.APSteer.APSteerToRootMinRSSIIncThreshold" "$APSteer_APSteerToRootMinRSSIIncThreshold" "$DEFAULT_LBD_APSTEERTOROOTMINRSSIINCTHRESHOLD"

APSteer_APSteerToLeafMinRSSIIncThreshold=$(uci -q get lbd.APSteer.APSteerToLeafMinRSSIIncThreshold)
show_result "lbd.APSteer.APSteerToLeafMinRSSIIncThreshold" "$APSteer_APSteerToLeafMinRSSIIncThreshold" "$DEFAULT_LBD_APSTEERTOLEAFMINRSSIINCTHRESHOLD"

APSteer_APSteerToPeerMinRSSIIncThreshold=$(uci -q get lbd.APSteer.APSteerToPeerMinRSSIIncThreshold)
show_result "lbd.APSteer.APSteerToPeerMinRSSIIncThreshold" "$APSteer_APSteerToPeerMinRSSIIncThreshold" "$DEFAULT_LBD_APSTEERTOPEERMINRSSIINCTHRESHOLD"

APSteer_LowRSSIAPSteerThreshold_CAP_W5=$(uci -q get lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W5)
show_result "lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W5" "$APSteer_LowRSSIAPSteerThreshold_CAP_W5" "$DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP_W5"

APSteer_LowRSSIAPSteerThreshold_RE_W5=$(uci -q get lbd.APSteer.LowRSSIAPSteerThreshold_RE_W5)
show_result "lbd.APSteer.LowRSSIAPSteerThreshold_RE_W5" "$APSteer_LowRSSIAPSteerThreshold_RE_W5" "$DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE_W5"

APSteer_LowRSSIAPSteerThreshold_CAP_W2=$(uci -q get lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W2)
show_result "lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W2" "$APSteer_LowRSSIAPSteerThreshold_CAP_W2" "$DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_CAP_W2"

APSteer_LowRSSIAPSteerThreshold_RE_W2=$(uci -q get lbd.APSteer.LowRSSIAPSteerThreshold_RE_W2)
show_result "lbd.APSteer.LowRSSIAPSteerThreshold_RE_W2" "$APSteer_LowRSSIAPSteerThreshold_RE_W2" "$DEFAULT_LBD_LOWRSSIAPSTEERTHRESHOLD_RE_W2"

APSteer_DownlinkRSSIThreshold_W5=$(uci -q get lbd.APSteer.DownlinkRSSIThreshold_W5)
show_result "lbd.APSteer.DownlinkRSSIThreshold_W5" "$APSteer_DownlinkRSSIThreshold_W5" "$DEFAULT_LBD_DOWNLINKRSSITHRESHOLD_W5"

BandMonitor_Adv_MUReportPeriod=$(uci -q get lbd.BandMonitor_Adv.MUReportPeriod)
show_result "lbd.BandMonitor_Adv.MUReportPeriod" "$BandMonitor_Adv_MUReportPeriod" "$DEFAULT_LBD_MUREPORTPERIOD"

BandMonitor_Adv_LoadBalancingAllowedMaxPeriod=$(uci -q get lbd.BandMonitor_Adv.LoadBalancingAllowedMaxPeriod)
show_result "lbd.BandMonitor_Adv.LoadBalancingAllowedMaxPeriod" "$BandMonitor_Adv_LoadBalancingAllowedMaxPeriod" "$DEFAULT_LBD_LOADBALANCINGALLOWEDMAXPERIOD"

Estimator_Adv_11kProhibitTimeShort=$(uci -q get lbd.Estimator_Adv.11kProhibitTimeShort)
show_result "lbd.Estimator_Adv.11kProhibitTimeShort" "$Estimator_Adv_11kProhibitTimeShort" "$DEFAULT_LBD_11KPROHIBITTIMESHORT"

Estimator_Adv_11kProhibitTimeLong=$(uci -q get lbd.Estimator_Adv.11kProhibitTimeLong)
show_result "lbd.Estimator_Adv.11kProhibitTimeLong" "$Estimator_Adv_11kProhibitTimeLong" "$DEFAULT_LBD_11KPROHIBITTIMELONG"

SteerExec_Adv_SteeringUnfriendlyTime=$(uci -q get lbd.SteerExec_Adv.SteeringUnfriendlyTime)
show_result "lbd.SteerExec_Adv.SteeringUnfriendlyTime" "$SteerExec_Adv_SteeringUnfriendlyTime" "$DEFAULT_LBD_STEERINGUNFRIENDLYTIME"

SteerExec_Adv_StartInBTMActiveState=$(uci -q get lbd.SteerExec_Adv.StartInBTMActiveState)
show_result "lbd.SteerExec_Adv.StartInBTMActiveState" "$SteerExec_Adv_StartInBTMActiveState" "$DEFAULT_LBD_STARTINBTMACTIVESTATE"

SteerExec_Adv_MaxConsecutiveBTMFailuresAsActive=$(uci -q get lbd.SteerExec_Adv.MaxConsecutiveBTMFailuresAsActive)
show_result "lbd.SteerExec_Adv.MaxConsecutiveBTMFailuresAsActive" "$SteerExec_Adv_MaxConsecutiveBTMFailuresAsActive" "$DEFAULT_LBD_MAXCONSECUTIVEBTMFAILURESASACTIVE"

SteerExec_Adv_BTMUnfriendlyTime=$(uci -q get lbd.SteerExec_Adv.BTMUnfriendlyTime)
show_result "lbd.SteerExec_Adv.BTMUnfriendlyTime" "$SteerExec_Adv_BTMUnfriendlyTime" "$DEFAULT_LBD_BTMUNFRIENDLYTIME"

SteerExec_Adv_MaxBTMUnfriendly=$(uci -q get lbd.SteerExec_Adv.MaxBTMUnfriendly)
show_result "lbd.SteerExec_Adv.MaxBTMUnfriendly" "$SteerExec_Adv_MaxBTMUnfriendly" "$DEFAULT_LBD_MAXBTMUNFRIENDLY"

SteerExec_Adv_MaxBTMActiveUnfriendly=$(uci -q get lbd.SteerExec_Adv.MaxBTMActiveUnfriendly)
show_result "lbd.SteerExec_Adv.MaxBTMActiveUnfriendly" "$SteerExec_Adv_MaxBTMActiveUnfriendly" "$DEFAULT_LBD_MAXBTMACTIVEUNFRIENDLY"

SteerExec_Adv_TSteering=$(uci -q get lbd.SteerExec_Adv.TSteering)
show_result "lbd.SteerExec_Adv.TSteering" "$SteerExec_Adv_TSteering" "$DEFAULT_LBD_TSEERING"

SteerExec_Adv_AuthRejMax=$(uci -q get lbd.SteerExec_Adv.AuthRejMax)
show_result "lbd.SteerExec_Adv.AuthRejMax" "$SteerExec_Adv_AuthRejMax" "$DEFAULT_LBD_AUTHREJMAX"

IAS_ENABLE_W2=$(uci -q get lbd.IAS.Enable_W2)
show_result "lbd.IAS.Enable_W2" "$IAS_ENABLE_W2" "$DEFAULT_LBD_IAS_ENABLE_W2"

IAS_ENABLE_W5=$(uci -q get lbd.IAS.Enable_W5)
show_result "lbd.IAS.Enable_W5" "$IAS_ENABLE_W5" "$DEFAULT_LBD_IAS_ENABLE_W5"

SteerExec_Adv_BlacklistTime=$(uci -q get lbd.SteerExec_Adv.BlacklistTime)
show_result "lbd.SteerExec_Adv.BlacklistTime" "$SteerExec_Adv_BlacklistTime" "$DEFAULT_LBD_BLACKLISTTIME"

#Check repacd related setting
printf " Checking repacd related setting\n"

board=$(cat /tmp/board_model_id)

if [ "$orbi_type" = "Satellite" ]; then

    if [ "$orbi_project" = "Orbimini"  ]; then
        wla_bh_sta_caprssi_in_athx=`config get wl5g_BACKHAUL_STA`
        wl2g_bh_athx=`config get wlg_BACKHAUL_STA`
        wl5g_bh_athx=`config get wla_BACKHAUL_STA`
    elif [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbipro"  ]; then
        wla_bh_sta_caprssi_in_athx=`config get wl5g_BACKHAUL_STA`
        wl2g_bh_athx=`config get wlg_BACKHAUL_STA`
        wl5g_bh_athx=`config get wla_2nd_BACKHAUL_STA`
    fi

    wla_bh_sta_caprssi_in_wix=`uci show | grep "ifname='$wla_bh_sta_caprssi_in_athx'"`        # wix : wireless interface
    wla_bh_sta_caprssi_prefix=`echo $wla_bh_sta_caprssi_in_wix | awk -F'.' '{print $1"."$2".caprssi"}'`
    

    #Check wireless related setting
    WiFi_Ul_Hyst=$(uci -q get wireless.wifi2.ul_hyst)
    show_result "wireless.wifi2.ul_hyst" "$WiFi_Ul_Hyst" "$DEFAULT_WIFI_UL_HYST"

    WiFi_Caprssi=$(uci -q get $wla_bh_sta_caprssi_prefix)
    show_result "WiFi_Caprssi" "$WiFi_Caprssi" "$DEFAULT_WIFI_CAPRSSI"
    
    repacd_Enable=$(uci -q get repacd.repacd.Enable)
    show_result "repacd.repacd.Enable" "$repacd_Enable" "$DEFAULT_REPACD_ENABLE"

    repacd_EnableSteering=$(uci -q get repacd.repacd.EnableSteering)
    show_result "repacd.repacd.EnableSteering" "$repacd_EnableSteering" "$DEFAULT_REPACD_ENABLESTEERING"

    WiFiLink_RSSIThresholdPrefer2GBackhaul=$(uci -q get repacd.WiFiLink.RSSIThresholdPrefer2GBackhaul)
    show_result "repacd.WiFiLink.RSSIThresholdPrefer2GBackhaul" "$WiFiLink_RSSIThresholdPrefer2GBackhaul" "$DEFAULT_REPACD_RSSITHRESHOLDPREFER2GBACKHAUL"

    WiFiLink_5GBackhaulEvalTimeShort=$(uci -q get repacd.WiFiLink.5GBackhaulEvalTimeShort)
    show_result "repacd.WiFiLink.5GBackhaulEvalTimeShort" "$WiFiLink_5GBackhaulEvalTimeShort" "$DEFAULT_REPACD_5GBACKHAULEVALTIMESHORT"

    WiFiLink_5GBackhaulEvalTimeLong=$(uci -q get repacd.WiFiLink.5GBackhaulEvalTimeLong)
    show_result "repacd.WiFiLink.5GBackhaulEvalTimeLong" "$WiFiLink_5GBackhaulEvalTimeLong" "$DEFAULT_REPACD_5GBACKHAULEVALTIMELONG"

    WiFiLink_MoveFromCAPSNRHysteresis5G=$(uci -q get repacd.WiFiLink.MoveFromCAPSNRHysteresis5G)
    show_result "repacd.WiFiLink.MoveFromCAPSNRHysteresis5G" "$WiFiLink_MoveFromCAPSNRHysteresis5G" "$DEFAULT_REPACD_MOVEFROMCAPSNRHYSTERESIS5G"

    WiFiLink_PreferCAPSNRThreshold=$(uci -q get repacd.WiFiLink.PreferCAPSNRThreshold)
    show_result "repacd.WiFiLink.PreferCAPSNRThreshold" "$WiFiLink_PreferCAPSNRThreshold" "$DEFAULT_REPACD_PREFERCAPSNRTHRESHOLD"

    WiFiLink_RATETHRESHOLDMIN5GINPERCENT=$(uci -q get repacd.WiFiLink.RateThresholdMin5GInPercent)
    show_result "repacd.WiFiLink.RateThresholdMin5GInPercent" "$WiFiLink_RATETHRESHOLDMIN5GINPERCENT" "$DEFAULT_REPACD_RATETHRESHOLDMIN5GINPERCENT"

    WiFiLink_RATETHRESHOLDMAX5GINPERCENT=$(uci -q get repacd.WiFiLink.RateThresholdMax5GInPercent)
    show_result "repacd.WiFiLink.RateThresholdMax5GInPercent" "$WiFiLink_RATETHRESHOLDMAX5GINPERCENT" "$DEFAULT_REPACD_RATETHRESHOLDMAX5GINPERCENT"

    WiFiLink_RATESCALINGFACTOR=$(uci -q get repacd.WiFiLink.RateScalingFactor)
    show_result "repacd.WiFiLink.RateScalingFactor" "$WiFiLink_RATESCALINGFACTOR" "$DEFAULT_REPACD_RATESCALINGFACTOR"

    #Check ebtable sanity status in satellite
    printf " Checking ebtables sanity status\n"

    ebtable_wl2g_status=`ebtables -L | grep wl2g_bh_athx`
    show_result "ebtables.wl2g.status" "$ebtable_wl2g_status" ""

    ebtable_wl5g_status=`ebtables -L | grep wl5g_bh_athx`
    show_result "ebtables.wl5g.status" "$ebtable_wl5g_status" ""
fi

# At the END
printf "\n ******* Total failed items = %d *******\n" $total_error_cnt
