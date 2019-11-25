#!/bin/sh

local orbi_project=
local orbi_type=
local wifi_topology_file=`cat /etc/ath/wifi.conf  | grep WIFI_TOPOLOGY_FILE | awk -F= '{print $2}'`

#lbd configs
#
lbd_updateDNI_config () {
    #config

    local lbd_config
    local lbd_enable
    local lbd_PHYBasedPrioritization
    local adjust_ssid
    local tmp_ssid=`config get wl_ssid`

    echo "$tmp_ssid" > /tmp/adj_ssid

    #Add SSID Special Characters adjustment for sync lbd's MatchingSSID and fronthaul SSID.
    sed -i 's/\\\\\\\\/\\/g' /tmp/adj_ssid
    sed -i 's/\\\"/\"/g' /tmp/adj_ssid
    sed -i 's/\\\\\\`/`/g' /tmp/adj_ssid

    adjust_ssid=`cat /tmp/adj_ssid`

    #At QSDK SPF8.0 lbd.config.MatchingSSID type is changed from option to list.
    if [ -n "`cat /etc/config/lbd | grep MatchingSSID | grep list`" ]; then
        uci delete lbd.config.MatchingSSID
        uci add_list lbd.config.MatchingSSID="$adjust_ssid"
    else
        uci set lbd.config.MatchingSSID="$adjust_ssid"
    fi

    rm /tmp/adj_ssid

    lbd_config=$(config get lbd_config)
    if [ -n "$lbd_config" ]; then
        uci set lbd.config=$lbd_config
    fi

    lbd_enable=$(config get lbd_enable)
    case $lbd_enable in
        1)
            uci set lbd.config.Enable=1
            ;;
        0)
            uci set lbd.config.Enable=0
            ;;
        "")
            lbd_enable=$(uci get lbd.config.Enable)
            config set lbd_enable=$lbd_enable
            config commit
            ;;
    esac

    lbd_PHYBasedPrioritization=$(config get lbd_PHYBasedPrioritization)
    case $lbd_PHYBasedPrioritization in
        1)
            uci set lbd.config.PHYBasedPrioritization=1
            ;;
        0)
            uci set lbd.config.PHYBasedPrioritization=0
            ;;
        "")
            lbd_PHYBasedPrioritization=$(uci get lbd.config.PHYBasedPrioritization)
            config set lbd_PHYBasedPrioritization=$lbd_PHYBasedPrioritization
            config commit
            ;;
    esac

    # Idle Steering
    local lbd_IdleSteer
    local lbd_RSSISteeringPoint_DG
    local lbd_RSSISteeringPoint_UG
    local lbd_NormalInactTimeout
    local lbd_OverloadInactTimeout
    local lbd_InactCheckInterval
    local lbd_AuthAllow

    lbd_IdleSteer=$(config get lbd_IdleSteer)
    if [ -n "$lbd_IdleSteer" ]; then
        uci set lbd.IdleSteer.lbd_IdleSteer=$lbd_IdleSteer
    fi

    lbd_RSSISteeringPoint_DG=$(config get lbd_RSSISteeringPoint_DG)
    if [ -n "$lbd_RSSISteeringPoint_DG" ]; then
        uci set lbd.IdleSteer.RSSISteeringPoint_DG=$lbd_RSSISteeringPoint_DG
    else
        config set lbd_RSSISteeringPoint_DG=$(uci get lbd.IdleSteer.RSSISteeringPoint_DG)
    fi


    lbd_NormalInactTimeout=$(config get lbd_NormalInactTimeout)
    if [ -n "$lbd_NormalInactTimeout" ]; then
        uci set lbd.IdleSteer.NormalInactTimeout=$lbd_NormalInactTimeout
    else
        config set lbd_NormalInactTimeout=$(uci get lbd.IdleSteer.NormalInactTimeout)
    fi

    lbd_OverloadInactTimeout=$(config get lbd_OverloadInactTimeout)
    if [ -n "$lbd_OverloadInactTimeout" ]; then
        uci set lbd.IdleSteer.OverloadInactTimeout=$lbd_OverloadInactTimeout
    else
        config set lbd_OverloadInactTimeout=$(uci get lbd.IdleSteer.OverloadInactTimeout)
    fi

    lbd_InactCheckInterval=$(config get lbd_InactCheckInterval)
    if [ -n "$lbd_InactCheckInterval" ]; then
        uci set lbd.IdleSteer.InactCheckInterval=$lbd_InactCheckInterval
    else
        config set lbd_InactCheckInterval=$(uci get lbd.IdleSteer.InactCheckInterval)
    fi

    lbd_RSSISteeringPoint_UG=$(config get lbd_RSSISteeringPoint_UG)
    if [ -n "$lbd_RSSISteeringPoint_UG" ]; then
        uci set lbd.IdleSteer.RSSISteeringPoint_UG=$lbd_RSSISteeringPoint_UG
    else
        config set lbd_RSSISteeringPoint_UG=$(uci get lbd.IdleSteer.RSSISteeringPoint_UG)
    fi

    lbd_AuthAllow=$(config get lbd_AuthAllow)
    if [ -n "$lbd_AuthAllow" ]; then
        uci set lbd.IdleSteer.AuthAllow=$lbd_lbd_AuthAllow
    fi

    # Active Steering
    local lbd_ActiveSteer
    local lbd_TxRateXingThreshold_UG
    local lbd_RateRSSIXingThreshold_UG
    local lbd_TxRateXingThreshold_DG
    local lbd_RateRSSIXingThreshold_DG

    lbd_ActiveSteer=$(config get lbd_ActiveSteer)
    if [ -n "$lbd_ActiveSteer" ]; then
        uci set lbd.ActiveSteer=$lbd_ActiveSteer
    fi

    lbd_TxRateXingThreshold_UG=$(config get lbd_TxRateXingThreshold_UG)
    if [ -n "$lbd_TxRateXingThreshold_UG" ]; then
        uci set lbd.ActiveSteer.TxRateXingThreshold_UG=$lbd_TxRateXingThreshold_UG
    else
        config set lbd_TxRateXingThreshold_UG=$(uci get lbd.ActiveSteer.TxRateXingThreshold_UG)
    fi

    lbd_RateRSSIXingThreshold_UG=$(config get lbd_RateRSSIXingThreshold_UG)
    if [ -n "$lbd_RateRSSIXingThreshold_UG" ]; then
        uci set lbd.ActiveSteer.RateRSSIXingThreshold_UG=$lbd_RateRSSIXingThreshold_UG
    else
        config set lbd_RateRSSIXingThreshold_UG=$(uci get lbd.ActiveSteer.RateRSSIXingThreshold_UG)
    fi

    lbd_TxRateXingThreshold_DG=$(config get lbd_TxRateXingThreshold_DG)
    if [ -n "$lbd_TxRateXingThreshold_DG" ]; then
        uci set lbd.ActiveSteer.TxRateXingThreshold_DG=$lbd_TxRateXingThreshold_DG
    else
        config set lbd_TxRateXingThreshold_DG=$(uci get lbd.ActiveSteer.TxRateXingThreshold_DG)
    fi

    lbd_RateRSSIXingThreshold_DG=$(config get lbd_RateRSSIXingThreshold_DG)
    if [ -n "$lbd_RateRSSIXingThreshold_DG" ]; then
        uci set lbd.ActiveSteer.RateRSSIXingThreshold_DG=$lbd_RateRSSIXingThreshold_DG
    else
        config set lbd_RateRSSIXingThreshold_DG=$(uci get lbd.ActiveSteer.RateRSSIXingThreshold_DG)
    fi

    # Offload
    local lbd_Offload
    local lbd_MUAvgPeriod
    local lbd_MUOverloadThreshold_W5
    local lbd_MUOverloadThreshold_W2
    local lbd_MUSafetyThreshold_W5
    local lbd_MUSafetyThreshold_W2
    local lbd_OffloadingMinRSSI

    lbd_Offload=$(config get lbd_Offload)
    if [ -n "$lbd_Offload" ]; then
        uci set lbd.Offload=$lbd_Offload
    fi

    lbd_MUAvgPeriod=$(config get lbd_MUAvgPeriod)
    if [ -n "$lbd_MUAvgPeriod" ]; then
        uci set lbd.Offload.MUAvgPeriod=$lbd_MUAvgPeriod
    else
        config set lbd_MUAvgPeriod=$(uci get lbd.Offload.MUAvgPeriod)
    fi

    lbd_MUOverloadThreshold_W5=$(config get lbd_MUOverloadThreshold_W5)
    if [ -n "$lbd_MUOverloadThreshold_W5" ]; then
        uci set lbd.Offload.MUOverloadThreshold_W5=$lbd_MUOverloadThreshold_W5
    else
        config set lbd_MUOverloadThreshold_W5=$(uci get lbd.Offload.MUOverloadThreshold_W5)
    fi

    lbd_MUOverloadThreshold_W2=$(config get lbd_MUOverloadThreshold_W2)
    if [ -n "$lbd_MUOverloadThreshold_W2" ]; then
        uci set lbd.Offload.MUOverloadThreshold_W2=$lbd_MUOverloadThreshold_W2
    else
        config set lbd_MUOverloadThreshold_W2=$(uci get lbd.Offload.MUOverloadThreshold_W2)
    fi

    lbd_MUSafetyThreshold_W5=$(config get lbd_MUSafetyThreshold_W5)
    if [ -n "$lbd_MUSafetyThreshold_W5" ]; then
        uci set lbd.Offload.MUSafetyThreshold_W5=$lbd_MUSafetyThreshold_W5
    else
        config set lbd_MUSafetyThreshold_W5=$(uci get lbd.Offload.MUSafetyThreshold_W5)
    fi

    lbd_MUSafetyThreshold_W2=$(config get lbd_MUSafetyThreshold_W2)
    if [ -n "$lbd_MUSafetyThreshold_W2" ]; then
        uci set lbd.Offload.MUSafetyThreshold_W2=$lbd_MUSafetyThreshold_W2
    else
        config set lbd_MUSafetyThreshold_W2=$(uci get lbd.Offload.MUSafetyThreshold_W2)
    fi

    lbd_OffloadingMinRSSI=$(config get lbd_OffloadingMinRSSI)
    if [ -n "$lbd_OffloadingMinRSSI" ]; then
        uci set lbd.Offload.OffloadingMinRSSI=$lbd_OffloadingMinRSSI
    else
        config set lbd_OffloadingMinRSSI=$(uci get lbd.Offload.OffloadingMinRSSI)
    fi

    #IAS
    local lbd_IAS
    local lbd_IAS_Enable_W2
    local lbd_IAS_Enable_W5
    local lbd_IAS_MaxPollutionTime
    local lbd_IAS_UseBestEffort

    lbd_IAS=$(config get lbd_IAS)
    if [ -n "$lbd_IAS" ]; then
        uci set lbd.IAS=$lbd_IAS
    fi

    lbd_IAS_Enable_W2=$(config get lbd_IAS_Enable_W2)
    if [ -n "$lbd_IAS_Enable_W2" ]; then
        uci set lbd.IAS.Enable_W2=$lbd_IAS_Enable_W2
    fi

    lbd_IAS_Enable_W5=$(config get lbd_IAS_Enable_W5)
    if [ -n "$lbd_IAS_Enable_W5" ]; then
        uci set lbd.IAS.Enable_W5=$lbd_IAS_Enable_W5
    fi

    lbd_IAS_MaxPollutionTime=$(config get lbd_IAS_MaxPollutionTime)
    if [ -n "$lbd_MaxPollutionTime" ]; then
        uci set lbd.IAS.MaxPollutionTime=$lbd_MaxPollutionTime
    fi

    lbd_IAS_UseBestEffort=$(config get lbd_IAS_UseBestEffort)
    if [ -n "$lbd_UseBestEffort" ]; then
        uci set lbd.IAS.UseBestEffort=$lbd_UseBestEffort
    fi

    #StaDB
    local lbd_StaDB
    local lbd_IncludeOutOfNetwork
    local lbd_MarkAdvClientAsDualBand
    local country_code

    lbd_StaDB=$(config get lbd_StaDB)
    if [ -n "$lbd_StaDB" ]; then
        uci set lbd.StaDB=$lbd_StaDB
    fi

    lbd_IncludeOutOfNetwork=$(config get lbd_IncludeOutOfNetwork)
    if [ -n "$lbd_IncludeOutOfNetwork" ]; then
        uci set lbd.StaDB.IncludeOutOfNetwork=$lbd_IncludeOutOfNetwork
    else
        config set lbd_IncludeOutOfNetwork=$(uci get lbd.StaDB.IncludeOutOfNetwork)
    fi

    lbd_MarkAdvClientAsDualBand=$(config get lbd_MarkAdvClientAsDualBand)
    country_code=$(config get wl_country)

    #NTGR request disable MarkAdvClientAsDualBand in the region other than USA
    #Because some client not support 5GL
    if [ "$country_code" -ne "10"  ]; then
        lbd_MarkAdvClientAsDualBand=0
    fi

    if [ -n "$lbd_MarkAdvClientAsDualBand" ]; then
        uci set lbd.StaDB.MarkAdvClientAsDualBand=$lbd_MarkAdvClientAsDualBand
    fi

    #SteerExec
    local lbd_SteerExec
    local lbd_SteeringProhibitTime
    local lbd_BTMSteeringProhibitShortTime

    lbd_SteerExec=$(config get lbd_SteerExec)
    if [ -n "$lbd_SteerExec" ]; then
        uci set lbd.SteerExec=$lbd_SteerExec
    fi

    lbd_SteeringProhibitTime=$(config get lbd_SteeringProhibitTime)
    if [ -n "$lbd_SteeringProhibitTime" ]; then
        uci set lbd.SteerExec.SteeringProhibitTime=$lbd_SteeringProhibitTime
    else
        config set lbd_SteeringProhibitTime=$(uci get lbd.SteerExec.SteeringProhibitTime)
    fi

    lbd_BTMSteeringProhibitShortTime=$(config get lbd_BTMSteeringProhibitShortTime)
    if [ -n "$lbd_BTMSteeringProhibitShortTime" ]; then
        uci set lbd.SteerExec.BTMSteeringProhibitShortTime=$lbd_BTMSteeringProhibitShortTime
    else
        config set lbd_BTMSteeringProhibitShortTime=$(uci get lbd.SteerExec.BTMSteeringProhibitShortTime)
    fi

    #AP_Steer
    local lbd_APSteer
    local lbd_LowRSSIAPSteerThreshold_CAP
    local lbd_LowRSSIAPSteerThreshold_RE
    local lbd_LowRSSIAPSteerThreshold_CAP_W5
    local lbd_LowRSSIAPSteerThreshold_RE_W5
    local lbd_LowRSSIAPSteerThreshold_CAP_w2
    local lbd_LowRSSIAPSteerThreshold_RE_w2
    local lbd_APSteerToRootMinRSSIIncThreshold
    local lbd_APSteerToLeafMinRSSIIncThreshold
    local lbd_APSteerToPeerMinRSSIIncThreshold
    local lbd_DownlinkRSSIThreshold_W5

    lbd_APSteer=$(config get lbd_APSteer)
    if [ -n "$lbd_APSteer" ]; then
        uci set lbd.StaDB=$lbd_APSteer
    fi

    lbd_LowRSSIAPSteerThreshold_CAP=$(config get lbd_LowRSSIAPSteerThreshold_CAP)
    if [ -n "$lbd_LowRSSIAPSteerThreshold_CAP" ]; then
        uci set lbd.APSteer.LowRSSIAPSteerThreshold_CAP=$lbd_LowRSSIAPSteerThreshold_CAP
    fi

    lbd_LowRSSIAPSteerThreshold_RE=$(config get lbd_LowRSSIAPSteerThreshold_RE)
    if [ -n "$lbd_LowRSSIAPSteerThreshold_RE_W5" ]; then
        uci set lbd.APSteer.LowRSSIAPSteerThreshold_RE=$lbd_LowRSSIAPSteerThreshold_RE
    fi

    lbd_LowRSSIAPSteerThreshold_CAP_W5=$(config get lbd_LowRSSIAPSteerThreshold_CAP_W5)
    if [ -n "$lbd_LowRSSIAPSteerThreshold_CAP_W5" ]; then
        uci set lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W5=$lbd_LowRSSIAPSteerThreshold_CAP_W5
    else
        config set lbd_LowRSSIAPSteerThreshold_CAP_W5=$(uci get lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W5)
    fi

    lbd_LowRSSIAPSteerThreshold_RE_W5=$(config get lbd_LowRSSIAPSteerThreshold_RE_W5)
    if [ -n "$lbd_LowRSSIAPSteerThreshold_RE_W5" ]; then
        uci set lbd.APSteer.LowRSSIAPSteerThreshold_RE_W5=$lbd_LowRSSIAPSteerThreshold_RE_W5
    else
        config set lbd_LowRSSIAPSteerThreshold_RE_W5=$(uci get lbd.APSteer.LowRSSIAPSteerThreshold_RE_W5)
    fi

    lbd_LowRSSIAPSteerThreshold_CAP_W2=$(config get lbd_LowRSSIAPSteerThreshold_CAP_W2)
    if [ -n "$lbd_LowRSSIAPSteerThreshold_CAP_W2" ]; then
        uci set lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W2=$lbd_LowRSSIAPSteerThreshold_CAP_W2
    else
        config set lbd_LowRSSIAPSteerThreshold_CAP_W2=$(uci get lbd.APSteer.LowRSSIAPSteerThreshold_CAP_W2)
    fi

    lbd_LowRSSIAPSteerThreshold_RE_W2=$(config get lbd_LowRSSIAPSteerThreshold_RE_W2)
    if [ -n "$lbd_LowRSSIAPSteerThreshold_RE_W2" ]; then
        uci set lbd.APSteer.LowRSSIAPSteerThreshold_RE_W2=$lbd_LowRSSIAPSteerThreshold_RE_W2
    else
        config set lbd_LowRSSIAPSteerThreshold_RE_W2=$(uci get lbd.APSteer.LowRSSIAPSteerThreshold_RE_W2)
    fi

    lbd_APSteerToRootMinRSSIIncThreshold=$(config get lbd_APSteerToRootMinRSSIIncThreshold)
    if [ -n "$lbd_APSteerToRootMinRSSIIncThreshold" ]; then
        uci set lbd.APSteer.APSteerToRootMinRSSIIncThreshold=$lbd_APSteerToRootMinRSSIIncThreshold
    else
        config set lbd_APSteerToRootMinRSSIIncThreshold=$(uci get lbd.APSteer.APSteerToRootMinRSSIIncThreshold)
    fi

    lbd_APSteerToLeafMinRSSIIncThreshold=$(config get lbd_APSteerToLeafMinRSSIIncThreshold)
    if [ -n "$lbd_APSteerToLeafMinRSSIIncThreshold" ]; then
        uci set lbd.APSteer.APSteerToLeafMinRSSIIncThreshold=$lbd_APSteerToLeafMinRSSIIncThreshold
    else
        config set lbd_APSteerToLeafMinRSSIIncThreshold=$(uci get lbd.APSteer.APSteerToLeafMinRSSIIncThreshold)
    fi

    lbd_APSteerToPeerMinRSSIIncThreshold=$(config get lbd_APSteerToPeerMinRSSIIncThreshold)
    if [ -n "$lbd_APSteerToPeerMinRSSIIncThreshold" ]; then
        uci set lbd.APSteer.APSteerToPeerMinRSSIIncThreshold=$lbd_APSteerToPeerMinRSSIIncThreshold
    else
        config set lbd_APSteerToPeerMinRSSIIncThreshold=$(uci get lbd.APSteer.APSteerToPeerMinRSSIIncThreshold)
    fi

    lbd_DownlinkRSSIThreshold_W5=$(config get lbd_DownlinkRSSIThreshold_W5)
    if [ -n "$lbd_DownlinkRSSIThreshold_W5" ]; then
        uci set lbd.APSteer.DownlinkRSSIThreshold_W5=$lbd_DownlinkRSSIThreshold_W5
    else
        config set lbd_DownlinkRSSIThreshold_W5=$(uci get lbd.APSteer.DownlinkRSSIThreshold_W5)
    fi

    #config_Adv
    local lbd_config_Adv
    local lbd_AgeLimit

    lbd_config_Adv=$(config get lbd_config_Adv)
    if [ -n "$lbd_config_Adv" ]; then
        uci set lbd.config_Adv=$lbd_config_Adv
    fi

    lbd_AgeLimit=$(config get lbd_AgeLimit)
    if [ -n "$lbd_AgeLimit" ]; then
        uci set lbd.config_Adv.AgeLimit=$lbd_AgeLimit
    else
        config set lbd_AgeLimit=$(uci get lbd.config_Adv.AgeLimit)
    fi

    #StaDB_Adv
    local lbd_StaDB_Adv
    local lbd_AgingSizeThreshold
    local lbd_AgingFrequency
    local lbd_OutOfNetworkMaxAge
    local lbd_InNetworkMaxAge
    local lbd_NumRemoteBSSes
    local lbd_PopulateNonServingPHYInfo
    local lbd_LegacyUpgradeAllowedCnt

    lbd_StaDB_Adv=$(config get lbd_StaDB_Adv)
    if [ -n "$lbd_StaDB_Adv" ]; then
        uci set lbd.StaDB_Adv=$lbd_StaDB_Adv
    fi

    lbd_AgingSizeThreshold=$(config get lbd_AgingSizeThreshold)
    if [ -n "$lbd_AgingSizeThreshold" ]; then
        uci set lbd.StaDB_Adv.AgingSizeThreshold=$lbd_AgingSizeThreshold
    else
        config set lbd_AgingSizeThreshold=$(uci get lbd.StaDB_Adv.AgingSizeThreshold)
    fi

    lbd_AgingFrequency=$(config get lbd_AgingFrequency)
    if [ -n "$lbd_AgingFrequency" ]; then
        uci set lbd.StaDB_Adv.AgingFrequency=$lbd_AgingFrequency
    else
        config set lbd_AgingFrequency=$(uci get lbd.StaDB_Adv.AgingFrequency)
    fi

    lbd_OutOfNetworkMaxAge=$(config get lbd_OutOfNetworkMaxAge)
    if [ -n "$lbd_OutOfNetworkMaxAge" ]; then
        uci set lbd.StaDB_Adv.OutOfNetworkMaxAge=$lbd_OutOfNetworkMaxAge
    else
        config set lbd_OutOfNetworkMaxAge=$(uci get lbd.StaDB_Adv.OutOfNetworkMaxAge)
    fi

    lbd_InNetworkMaxAge=$(config get lbd_InNetworkMaxAge)
    if [ -n "$lbd_InNetworkMaxAge" ]; then
        uci set lbd.StaDB_Adv.InNetworkMaxAge=$lbd_InNetworkMaxAge
    else
        config set lbd_InNetworkMaxAge=$(uci get lbd.StaDB_Adv.InNetworkMaxAge)
    fi

    lbd_NumRemoteBSSes=$(config get lbd_NumRemoteBSSes)
    if [ -n "$lbd_NumRemoteBSSes" ]; then
        uci set lbd.StaDB_Adv.NumRemoteBSSes=$lbd_NumRemoteBSSes
    else
        config set lbd_NumRemoteBSSes=$(uci get lbd.StaDB_Adv.NumRemoteBSSes)
    fi

    lbd_PopulateNonServingPHYInfo=$(config get lbd_PopulateNonServingPHYInfo)
    if [ -n "$lbd_PopulateNonServingPHYInfo" ]; then
        uci set lbd.StaDB_Adv.PopulateNonServingPHYInfo=$lbd_PopulateNonServingPHYInfo
    fi

    lbd_LegacyUpgradeAllowedCnt=$(config get lbd_LegacyUpgradeAllowedCnt)
    if [ -n "$lbd_LegacyUpgradeAllowedCnt" ]; then
        uci set lbd.StaDB_Adv.LegacyUpgradeAllowedCnt=$lbd_LegacyUpgradeAllowedCnt
    fi

    #StaMonitor_Adv
    local StaMonitor_Adv
    local lbd_RSSIMeasureSamples_W2
    local lbd_RSSIMeasureSamples_W5

    lbd_StaMonitor_Adv=$(config get lbd_StaMonitor_Adv)
    if [ -n "$lbd_StaMonitor_Adv" ]; then
        uci set lbd.StaMonitor_Adv=$lbd_StaMonitor_Adv
    fi

    lbd_RSSIMeasureSamples_W2=$(config get lbd_RSSIMeasureSamples_W2)
    if [ -n "$lbd_RSSIMeasureSamples_W2" ]; then
        uci set lbd.StaMonitor_Adv.RSSIMeasureSamples_W2=$lbd_RSSIMeasureSamples_W2
    else
        config set lbd_RSSIMeasureSamples_W2=$(uci get lbd.StaMonitor_Adv.RSSIMeasureSamples_W2)
    fi

    lbd_RSSIMeasureSamples_W5=$(config get lbd_RSSIMeasureSamples_W5)
    if [ -n "$lbd_RSSIMeasureSamples_W5" ]; then
        uci set lbd.StaMonitor_Adv.RSSIMeasureSamples_W5=$lbd_RSSIMeasureSamples_W5
    else
        config set lbd_RSSIMeasureSamples_W5=$(uci get lbd.StaMonitor_Adv.RSSIMeasureSamples_W5)
    fi

    #BandMonitor_Adv
    local lbd_BandMonitor_Adv
    local lbd_ProbeCountThreshold
    local lbd_MUCheckInterval_W2
    local lbd_MUCheckInterval_W5
    local lbd_MUReportPeriod
    local lbd_LoadBalancingAllowedMaxPeriod
    local lbd_NumRemoteChannels

    lbd_BandMonitor_Adv=$(config get lbd_BandMonitor_Adv)
    if [ -n "$lbd_BandMonitor_Adv" ]; then
        uci set lbd.BandMonitor_Adv=$lbd_BandMonitor_Adv
    fi

    lbd_ProbeCountThreshold=$(config get lbd_ProbeCountThreshold)
    if [ -n "$lbd_ProbeCountThreshold" ]; then
        uci set lbd.BandMonitor_Adv.ProbeCountThreshold=$lbd_ProbeCountThreshold
    else
        config set lbd_ProbeCountThreshold=$(uci get lbd.BandMonitor_Adv.ProbeCountThreshold)
    fi

    lbd_MUCheckInterval_W2=$(config get lbd_MUCheckInterval_W2)
    if [ -n "$lbd_MUCheckInterval_W2" ]; then
        uci set lbd.BandMonitor_Adv.MUCheckInterval_W2=$lbd_MUCheckInterval_W2
    else
        config set lbd_MUCheckInterval_W2=$(uci get lbd.BandMonitor_Adv.MUCheckInterval_W2)
    fi

    lbd_MUCheckInterval_W5=$(config get lbd_MUCheckInterval_W5)
    if [ -n "$lbd_MUCheckInterval_W5" ]; then
        uci set lbd.BandMonitor_Adv.MUCheckInterval_W5=$lbd_MUCheckInterval_W5
    else
        config set lbd_MUCheckInterval_W5=$(uci get lbd.BandMonitor_Adv.MUCheckInterval_W5)
    fi

    lbd_MUReportPeriod=$(config get lbd_MUReportPeriod)
    if [ -n "$lbd_MUReportPeriod" ]; then
        uci set lbd.BandMonitor_Adv.MUReportPeriod=$lbd_MUReportPeriod
    else
        config set lbd_MUReportPeriod=$(uci get lbd.BandMonitor_Adv.MUReportPeriod)
    fi

    lbd_LoadBalancingAllowedMaxPeriod=$(config get lbd_LoadBalancingAllowedMaxPeriod)
    if [ -n "$lbd_LoadBalancingAllowedMaxPeriod" ]; then
        uci set lbd.BandMonitor_Adv.LoadBalancingAllowedMaxPeriod=$lbd_LoadBalancingAllowedMaxPeriod
    else
        config set lbd_LoadBalancingAllowedMaxPeriod=$(uci get lbd.BandMonitor_Adv.LoadBalancingAllowedMaxPeriod)
    fi

    lbd_NumRemoteChannels=$(config get lbd_NumRemoteChannels)
    if [ -n "$lbd_NumRemoteChannels" ]; then
        uci set lbd.BandMonitor_Adv.NumRemoteChannels=$lbd_NumRemoteChannels
    else
        config set lbd_NumRemoteChannels=$(uci get lbd.BandMonitor_Adv.NumRemoteChannels)
    fi

    #Estimator_Adv
    local lbd_RSSIDiff_EstW5FromW2
    local lbd_RSSIDiff_EstW2FromW5
    local lbd_Est_ProbeCountThreshold
    local lbd_StatsSampleInterval
    local lbd_11kProhibitTimeShort
    local lbd_11kProhibitTimeLong
    local lbd_PhyRateScalingForAirtime
    local lbd_EnableContinuousThroughput
    local lbd_BcnrptActiveDuration
    local lbd_BcnrptPassiveDuration

    local lbd_Estimator_Adv
    local lbd_FastPollutionDetectBufSize
    local lbd_NormalPollutionDetectBufSize
    local lbd_PollutionDetectThreshold
    local lbd_PollutionClearThreshold
    local lbd_InterferenceAgeLimit
    local lbd_IASLowRSSIThreshold
    local lbd_IASMaxRateFactor
    local lbd_IASMinDeltaBytes
    local lbd_IASMinDeltaPackets

    lbd_RSSIDiff_EstW5FromW2=$(config get lbd_RSSIDiff_EstW5FromW2)
    if [ -n "$lbd_RSSIDiff_EstW5FromW2" ]; then
        uci set lbd.Estimator_Adv.RSSIDiff_EstW5FromW2=$lbd_RSSIDiff_EstW5FromW2
    else
        config set lbd_RSSIDiff_EstW5FromW2=$(uci get lbd.Estimator_Adv.RSSIDiff_EstW5FromW2)
    fi

    lbd_RSSIDiff_EstW2FromW5=$(config get lbd_RSSIDiff_EstW2FromW5)
    if [ -n "$lbd_RSSIDiff_EstW2FromW5" ]; then
        uci set lbd.Estimator_Adv.RSSIDiff_EstW2FromW5=$lbd_RSSIDiff_EstW2FromW5
    else
        config set lbd_RSSIDiff_EstW2FromW5=$(uci get lbd.Estimator_Adv.RSSIDiff_EstW2FromW5)
    fi

    lbd_Est_ProbeCountThreshold=$(config get lbd_Est_ProbeCountThreshold)
    if [ -n "$lbd_Est_ProbeCountThreshold" ]; then
        uci set lbd.Estimator_Adv.ProbeCountThreshold=$lbd_Est_ProbeCountThreshold
    else
        config set lbd_Est_ProbeCountThreshold=$(uci get lbd.Estimator_Adv.ProbeCountThreshold)
    fi

    lbd_StatsSampleInterval=$(config get lbd_StatsSampleInterval)
    if [ -n "$lbd_StatsSampleInterval" ]; then
        uci set lbd.Estimator_Adv.StatsSampleInterval=$lbd_StatsSampleInterval
    else
        config set lbd_StatsSampleInterval=$(uci get lbd.Estimator_Adv.StatsSampleInterval)
    fi

    lbd_11kProhibitTimeShort=$(config get lbd_11kProhibitTimeShort)
    if [ -n "$lbd_11kProhibitTimeShort" ]; then
        uci set lbd.Estimator_Adv.11kProhibitTimeShort=$lbd_11kProhibitTimeShort
    else
        config set lbd_11kProhibitTimeShort=$(uci get lbd.Estimator_Adv.11kProhibitTimeShort)
    fi

    lbd_11kProhibitTimeLong=$(config get lbd_11kProhibitTimeLong)
    if [ -n "$lbd_11kProhibitTimeLong" ]; then
        uci set lbd.Estimator_Adv.11kProhibitTimeLong=$lbd_11kProhibitTimeLong
    else
        config set lbd_11kProhibitTimeLong=$(uci get lbd.Estimator_Adv.11kProhibitTimeLong)
    fi

    lbd_PhyRateScalingForAirtime=$(config get lbd_PhyRateScalingForAirtime)
    if [ -n "$lbd_PhyRateScalingForAirtime" ]; then
        uci set lbd.Estimator_Adv.PhyRateScalingForAirtime=$lbd_PhyRateScalingForAirtime
    else
        config set lbd_PhyRateScalingForAirtime=$(uci get lbd.Estimator_Adv.PhyRateScalingForAirtime)
    fi

    lbd_EnableContinuousThroughput=$(config get lbd_EnableContinuousThroughput)
    if [ -n "$lbd_EnableContinuousThroughput" ]; then
        uci set lbd.Estimator_Adv.EnableContinuousThroughput=$lbd_EnableContinuousThroughput
    else
        config set lbd_EnableContinuousThroughput=$(uci get lbd.Estimator_Adv.EnableContinuousThroughput)
    fi

    lbd_BcnrptActiveDuration=$(config get lbd_BcnrptActiveDuration)
    if [ -n "$lbd_BcnrptActiveDuration" ]; then
        uci set lbd.Estimator_Adv.BcnrptActiveDuration=$lbd_BcnrptActiveDuration
    else
        config set lbd_BcnrptActiveDuration=$(uci get lbd.Estimator_Adv.BcnrptActiveDuration)
    fi

    lbd_BcnrptPassiveDuration=$(config get lbd_BcnrptPassiveDuration)
    if [ -n "$lbd_BcnrptPassiveDuration" ]; then
        uci set lbd.Estimator_Adv.BcnrptPassiveDuration=$lbd_BcnrptPassiveDuration
    else
        config set lbd_BcnrptPassiveDuration=$(uci get lbd.Estimator_Adv.BcnrptPassiveDuration)
    fi

    lbd_FastPollutionDetectBufSize=$(config get lbd_FastPollutionDetectBufSize)
    if [ -n "$lbd_FastPollutionDetectBufSize" ]; then
        uci set lbd.Estimator_Adv.FastPollutionDetectBufSize=$lbd_FastPollutionDetectBufSize
    fi

    lbd_NormalPollutionDetectBufSize=$(config get lbd_NormalPollutionDetectBufSize)

    lbd_PollutionDetectThreshold=$(config get lbd_PollutionDetectThreshold)
    if [ -n "$lbd_PollutionDetectThreshold" ]; then
        uci set lbd.Estimator_Adv.PollutionDetectThreshold=$lbd_PollutionDetectThreshold
    fi

    lbd_PollutionClearThreshold=$(config get lbd_PollutionClearThreshold)
    if [ -n "$lbd_PollutionClearThreshold" ]; then
        uci set lbd.Estimator_Adv.PollutionClearThreshold=$lbd_PollutionClearThreshold
    fi

    lbd_InterferenceAgeLimit=$(config get lbd_InterferenceAgeLimit)
    if [ -n "$lbd_InterferenceAgeLimit" ]; then
        uci set lbd.Estimator_Adv.InterferenceAgeLimit=$lbd_InterferenceAgeLimit
    fi

    lbd_IASLowRSSIThreshold=$(config get lbd_IASLowRSSIThreshold)
    if [ -n "$lbd_IASLowRSSIThreshold" ]; then
        uci set lbd.Estimator_Adv.IASLowRSSIThreshold=$lbd_IASLowRSSIThreshold
    fi

    lbd_IASMaxRateFactor=$(config get lbd_IASMaxRateFactor)
    if [ -n "$lbd_IASMaxRateFactor" ]; then
        uci set lbd.Estimator_Adv.IASMaxRateFactor=$lbd_IASMaxRateFactor
    fi

    lbd_IASMinDeltaBytes=$(config get lbd_IASMinDeltaBytes)
    if [ -n "$lbd_IASMinDeltaBytes" ]; then
        uci set lbd.Estimator_Adv.IASMinDeltaBytes=$lbd_IASMinDeltaBytes
    fi

    lbd_IASMinDeltaPackets=$(config get lbd_IASMinDeltaPackets)
    if [ -n "$lbd_IASMinDeltaPackets" ]; then
        uci set lbd.Estimator_Adv.IASMinDeltaPackets=$lbd_IASMinDeltaPackets
    fi

    #SteerExec_Adv
    local lbd_TSteering
    local lbd_InitialAuthRejCoalesceTime
    local lbd_AuthRejMax
    local lbd_SteeringUnfriendlyTime
    local lbd_MaxSteeringUnfriendly
    local lbd_TargetLowRSSIThreshold_W2
    local lbd_TargetLowRSSIThreshold_W5
    local lbd_BlacklistTime
    local lbd_BTMResponseTime
    local lbd_BTMAssociationTime
    local lbd_BTMAlsoBlacklist
    local lbd_BTMUnfriendlyTime
    local lbd_MaxBTMUnfriendly
    local lbd_MaxBTMActiveUnfriendly
    local lbd_MinRSSIBestEffort
    local lbd_LowRSSIXingThreshold

    local lbd_StartInBTMActiveState
    local lbd_Delay24GProbeRSSIThreshold
    local lbd_Delay24GProbeTimeWindow
    local lbd_Delay24GProbeMinReqCount
    local lbd_MaxConsecutiveBTMFailuresAsActive

    lbd_TSteering=$(config get lbd_TSteering)
    if [ -n "$lbd_TSteering" ]; then
        uci set lbd.SteerExec_Adv.TSteering=$lbd_TSteering
    else
        config set lbd_TSteering=$(uci get lbd.SteerExec_Adv.TSteering)
    fi

    lbd_InitialAuthRejCoalesceTime=$(config get lbd_InitialAuthRejCoalesceTime)
    if [ -n "$lbd_InitialAuthRejCoalesceTime" ]; then
        uci set lbd.SteerExec_Adv.InitialAuthRejCoalesceTime=$lbd_InitialAuthRejCoalesceTime
    else
        config set lbd_InitialAuthRejCoalesceTime=$(uci get lbd.SteerExec_Adv.InitialAuthRejCoalesceTime)
    fi

    lbd_AuthRejMax=$(config get lbd_AuthRejMax)
    if [ -n "$lbd_AuthRejMax" ]; then
        uci set lbd.SteerExec_Adv.AuthRejMax=$lbd_AuthRejMax
    else
        config set lbd_AuthRejMax=$(uci get lbd.SteerExec_Adv.AuthRejMax)
    fi

    lbd_SteeringUnfriendlyTime=$(config get lbd_SteeringUnfriendlyTime)
    if [ -n "$lbd_SteeringUnfriendlyTime" ]; then
        uci set lbd.SteerExec_Adv.SteeringUnfriendlyTime=$lbd_SteeringUnfriendlyTime
    else
        config set lbd_SteeringUnfriendlyTime=$(uci get lbd.SteerExec_Adv.SteeringUnfriendlyTime)
    fi

    lbd_MaxSteeringUnfriendly=$(config get lbd_MaxSteeringUnfriendly)
    if [ -n "$lbd_MaxSteeringUnfriendly" ]; then
        uci set lbd.SteerExec_Adv.MaxSteeringUnfriendly=$lbd_MaxSteeringUnfriendly
    else
        config set lbd_MaxSteeringUnfriendly=$(uci get lbd.SteerExec_Adv.MaxSteeringUnfriendly)
    fi

    lbd_TargetLowRSSIThreshold_W2=$(config get lbd_TargetLowRSSIThreshold_W2)
    if [ -n "$lbd_TargetLowRSSIThreshold_W2" ]; then
        uci set lbd.SteerExec_Adv.TargetLowRSSIThreshold_W2=$lbd_TargetLowRSSIThreshold_W2
    else
        config set lbd_TargetLowRSSIThreshold_W2=$(uci get lbd.SteerExec_Adv.TargetLowRSSIThreshold_W2)
    fi

    lbd_TargetLowRSSIThreshold_W5=$(config get lbd_TargetLowRSSIThreshold_W5)
    if [ -n "$lbd_TargetLowRSSIThreshold_W5" ]; then
        uci set lbd.SteerExec_Adv.TargetLowRSSIThreshold_W5=$lbd_TargetLowRSSIThreshold_W5
    else
        config set lbd_TargetLowRSSIThreshold_W5=$(uci get lbd.SteerExec_Adv.TargetLowRSSIThreshold_W5)
    fi

    lbd_BlacklistTime=$(config get lbd_BlacklistTime)
    if [ -n "$lbd_BlacklistTime" ]; then
        uci set lbd.SteerExec_Adv.BlacklistTime=$lbd_BlacklistTime
    else
        config set lbd_BlacklistTime=$(uci get lbd.SteerExec_Adv.BlacklistTime)
    fi

    lbd_BTMResponseTime=$(config get lbd_BTMResponseTime)
    if [ -n "$lbd_BTMResponseTime" ]; then
        uci set lbd.SteerExec_Adv.BTMResponseTime=$lbd_BTMResponseTime
    else
        config set lbd_BTMResponseTime=$(uci get lbd.SteerExec_Adv.BTMResponseTime)
    fi

    lbd_BTMAssociationTime=$(config get lbd_BTMAssociationTime)
    if [ -n "$lbd_BTMAssociationTime" ]; then
        uci set lbd.SteerExec_Adv.BTMAssociationTime=$lbd_BTMAssociationTime
    else
        config set lbd_BTMAssociationTime=$(uci get lbd.SteerExec_Adv.BTMAssociationTime)
    fi

    lbd_BTMAlsoBlacklist=$(config get lbd_BTMAlsoBlacklist)
    if [ -n "$lbd_BTMAlsoBlacklist" ]; then
        uci set lbd.SteerExec_Adv.BTMAlsoBlacklist=$lbd_BTMAlsoBlacklist
    else
        config set lbd_BTMAlsoBlacklist=$(uci get lbd.SteerExec_Adv.BTMAlsoBlacklist)
    fi

    lbd_BTMUnfriendlyTime=$(config get lbd_BTMUnfriendlyTime)
    if [ -n "$lbd_BTMUnfriendlyTime" ]; then
        uci set lbd.SteerExec_Adv.BTMUnfriendlyTime=$lbd_BTMUnfriendlyTime
    else
        config set lbd_BTMUnfriendlyTime=$(uci get lbd.SteerExec_Adv.BTMUnfriendlyTime)
    fi

    lbd_MaxBTMUnfriendly=$(config get lbd_MaxBTMUnfriendly)
    if [ -n "$lbd_MaxBTMUnfriendly" ]; then
        uci set lbd.SteerExec_Adv.MaxBTMUnfriendly=$lbd_MaxBTMUnfriendly
    else
        config set lbd_MaxBTMUnfriendly=$(uci get lbd.SteerExec_Adv.MaxBTMUnfriendly)
    fi

    lbd_MaxBTMActiveUnfriendly=$(config get lbd_MaxBTMActiveUnfriendly)
    if [ -n "$lbd_MaxBTMActiveUnfriendly" ]; then
        uci set lbd.SteerExec_Adv.MaxBTMActiveUnfriendly=$lbd_MaxBTMActiveUnfriendly
    else
        config set lbd_MaxBTMActiveUnfriendly=$(uci get lbd.SteerExec_Adv.MaxBTMActiveUnfriendly)
    fi

    lbd_MinRSSIBestEffort=$(config get lbd_MinRSSIBestEffort)
    if [ -n "$lbd_MinRSSIBestEffort" ]; then
        uci set lbd.SteerExec_Adv.MinRSSIBestEffort=$lbd_MinRSSIBestEffort
    else
        config set lbd_MinRSSIBestEffort=$(uci get lbd.SteerExec_Adv.MinRSSIBestEffort)
    fi

    lbd_LowRSSIXingThreshold=$(config get lbd_LowRSSIXingThreshold)
    if [ -n "$lbd_LowRSSIXingThreshold" ]; then
        uci set lbd.SteerExec_Adv.LowRSSIXingThreshold=$lbd_LowRSSIXingThreshold
    else
        config set lbd_LowRSSIXingThreshold=$(uci get lbd.SteerExec_Adv.LowRSSIXingThreshold)
    fi

    lbd_StartInBTMActiveState=$(config get lbd_StartInBTMActiveState)
    if [ -n "$StartInBTMActiveState" ]; then
        uci set lbd.SteerExec_Adv.StartInBTMActiveState=$lbd_StartInBTMActiveState
    fi

    lbd_Delay24GProbeTimeWindow=$(config get lbd_Delay24GProbeTimeWindow)
    if [ -n "$lbd_Delay24GProbeTimeWindow" ]; then
        uci set lbd.SteerExec_Adv.lbd_Delay24GProbeTimeWindow=$lbd_Delay24GProbeTimeWindow
    fi

    lbd_Delay24GProbeMinReqCount=$(config get lbd_Delay24GProbeMinReqCount)
    if [ -n "$lbd_Delay24GProbeMinReqCount" ]; then
        uci set lbd.SteerExec_Adv.lbd_Delay24GProbeMinReqCount=$lbd_Delay24GProbeMinReqCount
    fi

    lbd_MaxConsecutiveBTMFailuresAsActive=$(config get lbd_MaxConsecutiveBTMFailuresAsActive)
    if [ -n "$lbd_MaxConsecutiveBTMFailuresAsActive" ]; then
        uci set lbd.SteerExec_Adv.MaxConsecutiveBTMFailuresAsActive=$lbd_MaxConsecutiveBTMFailuresAsActive
    fi

    lbd_Delay24GProbeRSSIThreshold=$(config get lbd_Delay24GProbeRSSIThreshold)
    if [ -n "$lbd_Delay24GProbeRSSIThreshold" ]; then
        uci set lbd.SteerExec_Adv.lbd_Delay24GProbeRSSIThreshold=$lbd_Delay24GProbeRSSIThreshold
    fi

    #SteerAlg_Adv
    local lbd_SteerAlg_Adv
    local lbd_MinTxRateIncreaseThreshold
    local lbd_MaxSteeringTargetCount

    lbd_SteerAlg_Adv=$(config get lbd_SteerAlg_Adv)
    if [ -n "$lbd_SteerAlg_Adv" ]; then
        uci set lbd.SteerAlg_Adv=$lbd_SteerAlg_Adv
    fi

    lbd_MinTxRateIncreaseThreshold=$(config get lbd_MinTxRateIncreaseThreshold)
    if [ -n "$lbd_MinTxRateIncreaseThreshold" ]; then
        uci set lbd.SteerAlg_Adv.MinTxRateIncreaseThreshold=$lbd_MinTxRateIncreaseThreshold
    else
        config set lbd_MinTxRateIncreaseThreshold=$(uci get lbd.SteerAlg_Adv.MinTxRateIncreaseThreshold)
    fi

    lbd_MaxSteeringTargetCount=$(config get lbd_MaxSteeringTargetCount)
    if [ -n "$lbd_MaxSteeringTargetCount" ]; then
        uci set lbd.SteerAlg_Adv.MaxSteeringTargetCount=$lbd_MaxSteeringTargetCount
    else
        config set lbd_MaxSteeringTargetCount=$(uci get lbd.SteerAlg_Adv.MaxSteeringTargetCount)
    fi

    #Enable lbd diaglog
    local enable_lbd_diaglog
    enable_lbd_diaglog=$(config get enable_lbd_diaglog)
    case $enable_lbd_diaglog in
        1)
            uci set lbd.DiagLog.EnableLog=1
            uci set lbd.DiagLog.LogServerIP=192.168.1.170
            uci set lbd.DiagLog.LogLevelWlanIF=0
            uci set lbd.DiagLog.LogLevelBandMon=0
            uci set lbd.DiagLog.LogLevelStaDB=0
            uci set lbd.DiagLog.LogLevelSteerExec=0
            uci set lbd.DiagLog.LogLevelStaMon=0
            uci set lbd.DiagLog.LogLevelEstimator=0
            uci set lbd.DiagLog.LogLevelDiagLog=0
            ;;
        "")
            config set enable_lbd_diaglog=0
            config commit
            ;;
    esac

    local lbd_Persist
    local lbd_Persist_PersistPeriod

    lbd_Persist=$(config get lbd_Persist)
    if [ -n "$lbd_Persist" ]; then
        uci set lbd.Persist=$lbd_Persist
    fi

    lbd_Persist_PersistPeriod=$(config get lbd_Persist_PersistPeriod)
    if [ -n "$lbd_Persist_PersistPeriod" ]; then
        uci set lbd.Persist.PersistPeriod=$lbd_Persist_PersistPeriod
    fi

    local enable_band_steering
    local multi_ap_disablesteering

    enable_band_steering=$(config get enable_band_steering)
    multi_ap_disablesteering=$(config get multi_ap_disablesteering)

    case $enable_band_steering in
        1)
            uci set hyd.config.DisableSteering=0
            uci set repacd.repacd.EnableSteering=1
            uci commit hyd
            uci commit repacd
            ;;
        0)
            uci set hyd.config.DisableSteering=1
            uci set repacd.repacd.EnableSteering=0
            uci commit hyd
            uci commit repacd
            ;;
        "")
            enable_band_steering=$(uci get repacd.repacd.EnableSteering)

            case $enable_band_steering in
                1)
                    uci set hyd.config.DisableSteering=0
                    config set enable_band_steering=$enable_band_steering
                    uci commit hyd
                    ;;
                *)
                    uci set hyd.config.DisableSteering=1
                    config set enable_band_steering=$enable_band_steering
                    uci commit hyd
                    ;;
            esac
            ;;
    esac

    case $multi_ap_disablesteering in
        1)
            uci set lbd.APSteer.LowRSSIAPSteerThreshold_RE=100
            uci set lbd.APSteer.APSteerToRootMinRSSIIncThreshold=50
            uci set lbd.APSteer.APSteerToLeafMinRSSIIncThreshold=50
            uci set lbd.APSteer.APSteerToPeerMinRSSIIncThreshold=50
            uci set lbd.APSteer.DownlinkRSSIThreshold_W5=-10
            ;;
        0)
            uci set hyd.config.DisableSteering=0
            uci set repacd.repacd.EnableSteering=1
            uci commit hyd
            uci commit repacd

            #Multi-AP Treshold parameters has updated from DNI config above
            #
            ;;
        "")
            multi_ap_disablesteering=$(uci get hyd.config.DisableSteering)

            case $multi_ap_disablesteering in
                0)
                    uci set repacd.repacd.EnableSteering=1
                    config set multi_ap_disablesteering=$multi_ap_disablesteering
                    uci commit repacd
                    ;;
                *)
                    uci set repacd.repacd.EnableSteering=0
                    config set multi_ap_disablesteering=$multi_ap_disablesteering
                    uci commit repacd
                    ;;
            esac
            ;;
    esac

    config commit
}

#hyd configs
#
hyd_updateDNI_config () {

    local hyd_enable
    hyd_enable=$(config get hyd_enable)

    case $hyd_enable in
        1)
            uci set hyd.config.Enable=1
            ;;
        0)
            uci set hyd.config.Enable=0
            ;;
        "")
            hyd_enable=$(uci get hyd.config.Enable)
            config set hyd_enable=$hyd_enable
            config commit
            ;;
    esac

    local hyd_LoadBalancingSeamless
    hyd_LoadBalancingSeamless=$(config get hyd_LoadBalancingSeamless)

    case $hyd_LoadBalancingSeamless in
        1)
            uci set hyd.hy.LoadBalancingSeamless=1
            ;;
        0)
            uci set hyd.hy.LoadBalancingSeamless=0
            ;;
        "")
            hyd_LoadBalancingSeamless=$(uci get hyd.hy.LoadBalancingSeamless)
            config set hyd_LoadBalancingSeamless=$hyd_LoadBalancingSeamless
            config commit
            ;;
    esac

    local hyd_PathTransitionMethod
    hyd_PathTransitionMethod=$(config get hyd_PathTransitionMethod)

    case $hyd_PathTransitionMethod in
        1)
            uci set hyd.hy.PathTransitionMethod=1
            ;;
        0)
            uci set hyd.hy.PathTransitionMethod=0
            ;;
        "")
            hyd_PathTransitionMethod=$(uci get hyd.hy.PathTransitionMethod)
            config set hyd_PathTransitionMethod=$hyd_PathTransitionMethod
            config commit
            ;;
    esac

    # hyd.config
    local hyd_SwitchInterface
    local hyd_SwitchLanVid
    local hyd_Control
    local hyd_DisableSteering
    local hyd_Mode

    hyd_SwitchInterface=$(config get hyd_SwitchInterface)
    if [ -n "$hyd_SwitchInterface" ]; then
        uci set hyd.config.SwitchInterface=$hyd_SwitchInterface
    fi

    hyd_SwitchLanVid=$(config get hyd_SwitchLanVid)
    if [ -n "$hyd_SwitchLanVid" ]; then
        uci set hyd.config.SwitchLanVid=$hyd_SwitchLanVid
    fi

    hyd_Control=$(config get hyd_Control)
    if [ -n "$hyd_Control" ]; then
        uci set hyd.config.Control=$hyd_Control
    fi

    hyd_DisableSteering=$(config get hyd_DisableSteering)
    if [ -n "$hyd_DisableSteering" ]; then
        uci set hyd.config.DisableSteering=$hyd_DisableSteering
    fi

    hyd_Mode=$(config get hyd_Mode)
    if [ -n "$hyd_Mode" ]; then
        uci set hyd.config.Mode=$hyd_Mode
    fi

    # hyd.hy
    local hyd_hy
    local hyd_ConstrainTCPMedium
    local hyd_HActiveMaxAge

    hyd_hy=$(config get hyd_hy)
    if [ -n "$hyd_hy" ]; then
        uci set hyd.hy=$hyd_hy
    fi

    hyd_ConstrainTCPMedium=$(config get hyd_ConstrainTCPMedium)
    if [ -n "$hyd_ConstrainTCPMedium" ]; then
        uci set hyd.hy.ConstrainTCPMedium=$hyd_ConstrainTCPMedium
    fi

    hyd_MaxLBReordTimeout=$(config get hyd_MaxLBReordTimeout)
    if [ -n "$hyd_MaxLBReordTimeout" ]; then
        uci set hyd.hy.MaxLBReordTimeout=$hyd_MaxLBReordTimeout
    fi

    hyd_HActiveMaxAge=$(config get hyd_HActiveMaxAge)
    if [ -n "$hyd_HActiveMaxAge" ]; then
        uci set hyd.hy.HActiveMaxAge=$hyd_HActiveMaxAge
    fi

    # hyd.Wlan
    local hyd_Wlan
    local hyd_WlanCheckFreqInterval

    hyd_Wlan=$(config get hyd_Wlan)
    if [ -n "$hyd_Wlan" ]; then
        uci set hyd.Wlan=$hyd_Wlan
    fi

    hyd_WlanCheckFreqInterval=$(config get hyd_WlanCheckFreqInterval)
    if [ -n "$hyd_WlanCheckFreqInterval" ]; then
        uci set hyd.WlanCheckFreqInterval=$hyd_WlanCheckFreqInterval
    fi

    # hyd.PathChWlan
    local hyd_PathChWlan
    local hyd_PathChWlan_UpdatedStatsInterval_W2
    local hyd_PathChWlan_StatsAgedOutInterval_W2
    local hyd_PathChWlan_MaxMediumUtilization_W2
    local hyd_PathChWlan_MediumChangeThreshold_W2
    local hyd_PathChWlan_LinkChangeThreshold_W2
    local hyd_PathChWlan_MaxMediumUtilizationForLC_W2
    local hyd_PathChWlan_PHYRateThresholdForMU_W2
    local hyd_PathChWlan_ProbePacketSize_W2
    local hyd_PathChWlan_EnableProbe_W2
    local hyd_PathChWlan_AssocDetectionDelay_W2

    local hyd_PathChWlan_UpdatedStatsInterval_W5
    local hyd_PathChWlan_StatsAgedOutInterval_W5
    local hyd_PathChWlan_MaxMediumUtilization_W5
    local hyd_PathChWlan_MediumChangeThreshold_W5
    local hyd_PathChWlan_LinkChangeThreshold_W5
    local hyd_PathChWlan_MaxMediumUtilizationForLC_W5
    local hyd_PathChWlan_PHYRateThresholdForMU_W5
    local hyd_PathChWlan_ProbePacketSize_W5
    local hyd_PathChWlan_EnableProbe_W5
    local hyd_PathChWlan_AssocDetectionDelay_W5

    local hyd_PathChWlan_ScalingFactorHighRate_W2
    local hyd_PathChWlan_ScalingFactorHighRate_W5
    local hyd_PathChWlan_ScalingFactorLow
    local hyd_PathChWlan_ScalingFactorMedium
    local hyd_PathChWlan_ScalingFactorHigh
    local hyd_PathChWlan_ScalingFactorTCP

    local hyd_PathChWlan_UseWHCAlgorithm
    local hyd_PathChWlan_NumUpdatesUntilStatsValid

    local hyd_PathChWlan_CPULimitedTCPThroughput_W2
    local hyd_PathChWlan_CPULimitedUDPThroughput_W2
    local hyd_PathChWlan_CPULimitedTCPThroughput_W5
    local hyd_PathChWlan_CPULimitedUDPThroughput_W5

    hyd_PathChWlan=$(config get hyd_PathChWlan)
    if [ -n "$hyd_PathChWlan" ]; then
        uci set hyd.PathChWlan=$hyd_PathChWlan
    fi

    hyd_PathChWlan_UseWHCAlgorithm=$(config get hyd_PathChWlan_UseWHCAlgorithm)
    if [ -n "$hyd_PathChWlan_UseWHCAlgorithm" ]; then
        uci set hyd.PathChWlan_UseWHCAlgorithm=$hyd_PathChWlan_UseWHCAlgorithm
    fi

    hyd_PathChWlan_NumUpdatesUntilStatsValid=$(config get hyd_PathChWlan_NumUpdatesUntilStatsValid)
    if [ -n "$hyd_PathChWlan_NumUpdatesUntilStatsValid" ]; then
        uci set hyd.PathChWlan_NumUpdatesUntilStatsValid=$hyd_PathChWlan_NumUpdatesUntilStatsValid
    fi

    hyd_PathChWlan_UpdatedStatsInterval_W2=$(config get hyd_PathChWlan_UpdatedStatsInterval_W2)
    if [ -n "$hyd_PathChWlan_UpdatedStatsInterval_W2" ]; then
        uci set hyd.PathChWlan.UpdatedStatsInterval_W2=$hyd_PathChWlan_UpdatedStatsInterval_W2
    fi

    hyd_PathChWlan_StatsAgedOutInterval_W2=$(config get hyd_PathChWlan_StatsAgedOutInterval_W2)
    if [ -n "$hyd_PathChWlan_StatsAgedOutInterval_W2" ]; then
        uci set hyd.PathChWlan.StatsAgedOutInterval_W2=$hyd_PathChWlan_StatsAgedOutInterval_W2
    fi

    hyd_PathChWlan_MaxMediumUtilization_W2=$(config get hyd_PathChWlan_MaxMediumUtilization_W2)
    if [ -n "$hyd_PathChWlan_MaxMediumUtilization_W2" ]; then
        uci set hyd.PathChWlan.MaxMediumUtilization_W2=$hyd_PathChWlan_MaxMediumUtilization_W2
    fi

    hyd_PathChWlan_MediumChangeThreshold_W2=$(config get hyd_PathChWlan_MediumChangeThreshold_W2)
    if [ -n "$hyd_PathChWlan_MediumChangeThreshold_W2" ]; then
        uci set hyd.PathChWlan.MediumChangeThreshold_W2=$hyd_PathChWlan_MediumChangeThreshold_W2
    fi

    hyd_PathChWlan_LinkChangeThreshold_W2=$(config get hyd_PathChWlan_LinkChangeThreshold_W2)
    if [ -n "$hyd_PathChWlan_LinkChangeThreshold_W2" ]; then
        uci set hyd.PathChWlan.LinkChangeThreshold_W2=$hyd_PathChWlan_LinkChangeThreshold_W2
    fi

    hyd_PathChWlan_MaxMediumUtilizationForLC_W2=$(config get hyd_PathChWlan_MaxMediumUtilizationForLC_W2)
    if [ -n "$hyd_PathChWlan_MaxMediumUtilizationForLC_W2" ]; then
        uci set hyd.PathChWlan.MaxMediumUtilizationForLC_W2=$hyd_PathChWlan_MaxMediumUtilizationForLC_W2
    fi

    hyd_PathChWlan_PHYRateThresholdForMU_W2=$(config get hyd_PathChWlan_PHYRateThresholdForMU_W2)
    if [ -n "$hyd_PathChWlan_PHYRateThresholdForMU_W2" ]; then
        uci set hyd.PathChWlan.PHYRateThresholdForMU_W2=$hyd_PathChWlan_PHYRateThresholdForMU_W2
    fi

    hyd_PathChWlan_ProbePacketSize_W2=$(config get hyd_PathChWlan_ProbePacketSize_W2)
    if [ -n "$hyd_PathChWlan_ProbePacketSize_W2" ]; then
        uci set hyd.PathChWlan.ProbePacketSize_W2=$hyd_PathChWlan_ProbePacketSize_W2
    fi

    hyd_PathChWlan_EnableProbe_W2=$(config get hyd_PathChWlan_EnableProbe_W2)
    if [ -n "$hyd_PathChWlan_EnableProbe_W2" ]; then
        uci set hyd.PathChWlan.EnableProbe_W2=$hyd_PathChWlan_EnableProbe_W2
    fi

    hyd_PathChWlan_AssocDetectionDelay_W2=$(config get hyd_PathChWlan_AssocDetectionDelay_W2)
    if [ -n "$hyd_PathChWlan_AssocDetectionDelay_W2" ]; then
        uci set hyd.PathChWlan.AssocDetectionDelay_W2=$hyd_PathChWlan_AssocDetectionDelay_W2
    fi


    hyd_PathChWlan_UpdatedStatsInterval_W5=$(config get hyd_PathChWlan_UpdatedStatsInterval_W5)
    if [ -n "$hyd_PathChWlan_UpdatedStatsInterval_W5" ]; then
        uci set hyd.PathChWlan.UpdatedStatsInterval_W5=$hyd_PathChWlan_UpdatedStatsInterval_W5
    fi

    hyd_PathChWlan_StatsAgedOutInterval_W5=$(config get hyd_PathChWlan_StatsAgedOutInterval_W5)
    if [ -n "$hyd_PathChWlan_StatsAgedOutInterval_W5" ]; then
        uci set hyd.PathChWlan.StatsAgedOutInterval_W5=$hyd_PathChWlan_StatsAgedOutInterval_W5
    fi

    hyd_PathChWlan_MaxMediumUtilization_W5=$(config get hyd_PathChWlan_MaxMediumUtilization_W5)
    if [ -n "$hyd_PathChWlan_MaxMediumUtilization_W5" ]; then
        uci set hyd.PathChWlan.MaxMediumUtilization_W5=$hyd_PathChWlan_MaxMediumUtilization_W5
    fi

    hyd_PathChWlan_MediumChangeThreshold_W5=$(config get hyd_PathChWlan_MediumChangeThreshold_W5)
    if [ -n "$hyd_PathChWlan_MediumChangeThreshold_W5" ]; then
        uci set hyd.PathChWlan.MediumChangeThreshold_W5=$hyd_PathChWlan_MediumChangeThreshold_W5
    fi

    hyd_PathChWlan_LinkChangeThreshold_W5=$(config get hyd_PathChWlan_LinkChangeThreshold_W5)
    if [ -n "$hyd_PathChWlan_LinkChangeThreshold_W5" ]; then
        uci set hyd.PathChWlan.LinkChangeThreshold_W5=$hyd_PathChWlan_LinkChangeThreshold_W5
    fi

    hyd_PathChWlan_MaxMediumUtilizationForLC_W5=$(config get hyd_PathChWlan_MaxMediumUtilizationForLC_W5)
    if [ -n "$hyd_PathChWlan_MaxMediumUtilizationForLC_W5" ]; then
        uci set hyd.PathChWlan.MaxMediumUtilizationForLC_W5=$hyd_PathChWlan_MaxMediumUtilizationForLC_W5
    fi

    hyd_PathChWlan_PHYRateThresholdForMU_W5=$(config get hyd_PathChWlan_PHYRateThresholdForMU_W5)
    if [ -n "$hyd_PathChWlan_PHYRateThresholdForMU_W5" ]; then
        uci set hyd.PathChWlan.PHYRateThresholdForMU_W5=$hyd_PathChWlan_PHYRateThresholdForMU_W5
    fi

    hyd_PathChWlan_ProbePacketSize_W5=$(config get hyd_PathChWlan_ProbePacketSize_W5)
    if [ -n "$hyd_PathChWlan_ProbePacketSize_W5" ]; then
        uci set hyd.PathChWlan.ProbePacketSize_W5=$hyd_PathChWlan_ProbePacketSize_W5
    fi

    hyd_PathChWlan_EnableProbe_W5=$(config get hyd_PathChWlan_EnableProbe_W5)
    if [ -n "$hyd_PathChWlan_EnableProbe_W5" ]; then
        uci set hyd.PathChWlan.EnableProbe_W5=$hyd_PathChWlan_EnableProbe_W5
    fi

    hyd_PathChWlan_AssocDetectionDelay_W5=$(config get hyd_PathChWlan_AssocDetectionDelay_W5)
    if [ -n "$hyd_PathChWlan_AssocDetectionDelay_W5" ]; then
        uci set hyd.PathChWlan.AssocDetectionDelay_W5=$hyd_PathChWlan_AssocDetectionDelay_W5
    fi

    hyd_PathChWlan_ScalingFactorHighRate_W2=$(config get hyd_PathChWlan_ScalingFactorHighRate_W2)
    if [ -n "$hyd_PathChWlan_ScalingFactorHighRate_W2" ]; then
        uci set hyd.PathChWlan.ScalingFactorHighRate_W2=$hyd_PathChWlan_ScalingFactorHighRate_W2
    fi

    hyd_PathChWlan_ScalingFactorHighRate_W5=$(config get hyd_PathChWlan_ScalingFactorHighRate_W5)
    if [ -n "$hyd_PathChWlan_ScalingFactorHighRate_W5" ]; then
        uci set hyd.PathChWlan.ScalingFactorHighRate_W5=$hyd_PathChWlan_ScalingFactorHighRate_W5
    fi

    hyd_PathChWlan_ScalingFactorLow=$(config get hyd_PathChWlan_ScalingFactorLow)
    if [ -n "$hyd_PathChWlan_ScalingFactorLow" ]; then
        uci set hyd.PathChWlan.ScalingFactorLow=$hyd_PathChWlan_ScalingFactorLow
    fi

    hyd_PathChWlan_ScalingFactorMedium=$(config get hyd_PathChWlan_ScalingFactorMedium)
    if [ -n "$hyd_PathChWlan_ScalingFactorMedium" ]; then
        uci set hyd.PathChWlan.ScalingFactorMedium=$hyd_PathChWlan_ScalingFactorMedium
    fi

    hyd_PathChWlan_ScalingFactorHigh=$(config get hyd_PathChWlan_ScalingFactorHigh)
    if [ -n "$hyd_PathChWlan_ScalingFactorHigh" ]; then
        uci set hyd.PathChWlan.ScalingFactorHigh=$hyd_PathChWlan_ScalingFactorHigh
    fi

    hyd_PathChWlan_ScalingFactorTCP=$(config get hyd_PathChWlan_ScalingFactorTCP)
    if [ -n "$hyd_PathChWlan_ScalingFactorTCP" ]; then
        uci set hyd.PathChWlan.ScalingFactorTCP=$hyd_PathChWlan_ScalingFactorTCP
    fi

    hyd_PathChWlan_CPULimitedTCPThroughput_W2=$(config get hyd_PathChWlan_CPULimitedTCPThroughput_W2)
    if [ -n "$hyd_PathChWlan_CPULimitedTCPThroughput_W2" ]; then
        uci set hyd.PathChWlan.CPULimitedTCPThroughput_W2=$hyd_PathChWlan_CPULimitedTCPThroughput_W2
    fi

    hyd_PathChWlan_CPULimitedUDPThroughput_W2=$(config get hyd_PathChWlan_CPULimitedUDPThroughput_W2)
    if [ -n "$hyd_PathChWlan_CPULimitedUDPThroughput_W2" ]; then
        uci set hyd.PathChWlan.CPULimitedUDPThroughput_W2=$hyd_PathChWlan_CPULimitedUDPThroughput_W2
    fi

    hyd_PathChWlan_CPULimitedTCPThroughput_W5=$(config get hyd_PathChWlan_CPULimitedTCPThroughput_W5)
    if [ -n "$hyd_PathChWlan_CPULimitedTCPThroughput_W5" ]; then
        uci set hyd.PathChWlan.CPULimitedTCPThroughput_W5=$hyd_PathChWlan_CPULimitedTCPThroughput_W5
    fi

    hyd_PathChWlan_CPULimitedUDPThroughput_W5=$(config get hyd_PathChWlan_CPULimitedUDPThroughput_W5)
    if [ -n "$hyd_PathChWlan_CPULimitedUDPThroughput_W5" ]; then
        uci set hyd.PathChWlan.CPULimitedUDPThroughput_W5=$hyd_PathChWlan_CPULimitedUDPThroughput_W5
    fi

    # hyd.PathChPlc
    local hyd_PathChPlc
    local hyd_PathChPlc_MaxMediumUtilization
    local hyd_PathChPlc_MediumChangeThreshold
    local hyd_PathChPlc_LinkChangeThreshold
    local hyd_PathChPlc_StatsAgedOutInterval
    local hyd_PathChPlc_UpdateStatsInterval
    local hyd_PathChPlc_EntryExpirationInterval
    local hyd_PathChPlc_MaxMediumUtilizationForLC
    local hyd_PathChPlc_LCThresholdForUnreachable
    local hyd_PathChPlc_LCThresholdForReachable
    local hyd_PathChPlc_HostPLCInterfaceSpeed

    hyd_PathChPlc=$(config get hyd_PathChPlc)
    if [ -n "$hyd_PathChPlc" ]; then
        uci set hyd.PathChPlc=$hyd_PathChPlc
    fi

    hyd_PathChPlc_MaxMediumUtilization=$(config get hyd_PathChPlc_MaxMediumUtilization)
    if [ -n "$hyd_PathChPlc_MaxMediumUtilization" ]; then
        uci set hyd.PathChPlc_MaxMediumUtilization=$hyd_PathChPlc_MaxMediumUtilization
    fi

    hyd_PathChPlc_MediumChangeThreshold=$(config get hyd_PathChPlc_MediumChangeThreshold)
    if [ -n "$hyd_PathChPlc_MediumChangeThreshold" ]; then
        uci set hyd.PathChPlc_MediumChangeThreshold=$hyd_PathChPlc_MediumChangeThreshold
    fi

    hyd_PathChPlc_LinkChangeThreshold=$(config get hyd_PathChPlc_LinkChangeThreshold)
    if [ -n "$hyd_PathChPlc_LinkChangeThreshold" ]; then
        uci set hyd.PathChPlc_LinkChangeThreshold=$hyd_PathChPlc_LinkChangeThreshold
    fi

    hyd_PathChPlc_StatsAgedOutInterval=$(config get hyd_PathChPlc_StatsAgedOutInterval)
    if [ -n "$hyd_PathChPlc_StatsAgedOutInterval" ]; then
        uci set hyd.PathChPlc_StatsAgedOutInterval=$hyd_PathChPlc_StatsAgedOutInterval
    fi

    hyd_PathChPlc_UpdateStatsInterval=$(config get hyd_PathChPlc_UpdateStatsInterval)
    if [ -n "$hyd_PathChPlc_UpdateStatsInterval" ]; then
        uci set hyd.PathChPlc_UpdateStatsInterval=$hyd_PathChPlc_UpdateStatsInterval
    fi

    hyd_PathChPlc_EntryExpirationInterval=$(config get hyd_PathChPlc_EntryExpirationInterval)
    if [ -n "$hyd_PathChPlc_EntryExpirationInterval" ]; then
        uci set hyd.PathChPlc_EntryExpirationInterval=$hyd_PathChPlc_EntryExpirationInterval
    fi

    hyd_PathChPlc_MaxMediumUtilizationForLC=$(config get hyd_PathChPlc_MaxMediumUtilizationForLC)
    if [ -n "$hyd_PathChPlc_MaxMediumUtilizationForLC" ]; then
        uci set hyd.PathChPlc_MaxMediumUtilizationForLC=$hyd_PathChPlc_MaxMediumUtilizationForLC
    fi

    hyd_PathChPlc_LCThresholdForUnreachable=$(config get hyd_PathChPlc_LCThresholdForUnreachable)
    if [ -n "$hyd_PathChPlc_LCThresholdForUnreachable" ]; then
        uci set hyd.PathChPlc_LCThresholdForUnreachable=$hyd_PathChPlc_LCThresholdForUnreachable
    fi

    hyd_PathChPlc_LCThresholdForReachable=$(config get hyd_PathChPlc_LCThresholdForReachable)
    if [ -n "$hyd_PathChPlc_LCThresholdForReachable" ]; then
        uci set hyd.PathChPlc_LCThresholdForReachable=$hyd_PathChPlc_LCThresholdForReachable
    fi

    hyd_PathChPlc_HostPLCInterfaceSpeed=$(config get hyd_PathChPlc_HostPLCInterfaceSpeed)
    if [ -n "$hyd_PathChPlc_HostPLCInterfaceSpeed" ]; then
        uci set hyd.PathChPlc_HostPLCInterfaceSpeed=$hyd_PathChPlc_HostPLCInterfaceSpeed
    fi

    # hyd.Topology
    local hyd_Topology
    local hyd_Topology_ND_UPDATE_INTERVAL
    local hyd_Topology_BD_UPDATE_INTERVAL
    local hyd_Topology_HOLDING_TIME
    local hyd_Topology_TIMER_LOW_BOUND
    local hyd_Topology_TIMER_UPPER_BOUND
    local hyd_Topology_MSGID_DELTA
    local hyd_Topology_HA_AGING_INTERVAL
    local hyd_Topology_ENABLE_TD3
    local hyd_Topology_ENABLE_BD_SPOOFING
    local hyd_Topology_NOTIFICATION_THROTTLING_WINDOW
    local hyd_Topology_PERIODIC_QUERY_INTERVAL
    local hyd_Topology_ENABLE_NOTIFICATION_UNICAST

    hyd_Topology=$(config get hyd_Topology)
    if [ -n "$hyd_Topology" ]; then
        uci set hyd.Topology=$hyd_Topology
    fi

    hyd_Topology_ND_UPDATE_INTERVAL=$(config get hyd_Topology_ND_UPDATE_INTERVAL)
    if [ -n "$hyd_Topology_ND_UPDATE_INTERVAL" ]; then
        uci set hyd.Topology_ND_UPDATE_INTERVAL=$hyd_Topology_ND_UPDATE_INTERVAL
    fi

    hyd_Topology_BD_UPDATE_INTERVAL=$(config get hyd_Topology_BD_UPDATE_INTERVAL)
    if [ -n "$hyd_Topology_BD_UPDATE_INTERVAL" ]; then
        uci set hyd.Topology_BD_UPDATE_INTERVAL=$hyd_Topology_BD_UPDATE_INTERVAL
    fi

    hyd_Topology_HOLDING_TIME=$(config get hyd_Topology_HOLDING_TIME)
    if [ -n "$hyd_Topology_HOLDING_TIME" ]; then
        uci set hyd.Topology_HOLDING_TIME=$hyd_Topology_HOLDING_TIME
    fi

    hyd_Topology_TIMER_LOW_BOUND=$(config get hyd_Topology_TIMER_LOW_BOUND)
    if [ -n "$hyd_Topology_TIMER_LOW_BOUND" ]; then
        uci set hyd.Topology_TIMER_LOW_BOUND=$hyd_Topology_TIMER_LOW_BOUND
    fi

    hyd_Topology_TIMER_UPPER_BOUND=$(config get hyd_Topology_TIMER_UPPER_BOUND)
    if [ -n "$hyd_Topology_TIMER_UPPER_BOUND" ]; then
        uci set hyd.Topology_TIMER_UPPER_BOUND=$hyd_Topology_TIMER_UPPER_BOUND
    fi

    hyd_Topology_MSGID_DELTA=$(config get hyd_Topology_MSGID_DELTA)
    if [ -n "$hyd_Topology_MSGID_DELTA" ]; then
        uci set hyd.Topology_MSGID_DELTA=$hyd_Topology_MSGID_DELTA
    fi

    hyd_Topology_HA_AGING_INTERVAL=$(config get hyd_Topology_HA_AGING_INTERVAL)
    if [ -n "$hyd_Topology_HA_AGING_INTERVAL" ]; then
        uci set hyd.Topology_HA_AGING_INTERVAL=$hyd_Topology_HA_AGING_INTERVAL
    fi

    hyd_Topology_ENABLE_TD3=$(config get hyd_Topology_ENABLE_TD3)
    if [ -n "$hyd_Topology_ENABLE_TD3" ]; then
        uci set hyd.Topology_ENABLE_TD3=$hyd_Topology_ENABLE_TD3
    fi

    hyd_Topology_ENABLE_BD_SPOOFING=$(config get hyd_Topology_ENABLE_BD_SPOOFING)
    if [ -n "$hyd_Topology_ENABLE_BD_SPOOFING" ]; then
        uci set hyd.Topology_ENABLE_BD_SPOOFING=$hyd_Topology_ENABLE_BD_SPOOFING
    fi

    hyd_Topology_NOTIFICATION_THROTTLING_WINDOW=$(config get hyd_Topology_NOTIFICATION_THROTTLING_WINDOW)
    if [ -n "$hyd_Topology_NOTIFICATION_THROTTLING_WINDOW" ]; then
        uci set hyd.Topology_NOTIFICATION_THROTTLING_WINDOW=$hyd_Topology_NOTIFICATION_THROTTLING_WINDOW
    fi

    hyd_Topology_PERIODIC_QUERY_INTERVAL=$(config get hyd_Topology_PERIODIC_QUERY_INTERVAL)
    if [ -n "$hyd_Topology_PERIODIC_QUERY_INTERVAL" ]; then
        uci set hyd.Topology_PERIODIC_QUERY_INTERVAL=$hyd_Topology_PERIODIC_QUERY_INTERVAL
    fi

    hyd_Topology_ENABLE_NOTIFICATION_UNICAST=$(config get hyd_Topology_ENABLE_NOTIFICATION_UNICAST)
    if [ -n "$hyd_Topology_ENABLE_NOTIFICATION_UNICAST" ]; then
        uci set hyd.Topology_ENABLE_NOTIFICATION_UNICAST=$hyd_Topology_ENABLE_NOTIFICATION_UNICAST
    fi

    # hyd.HSPECEst
    local hyd_HSPECEst
    local hyd_HSPECEst_UpdateHSPECInterval
    local hyd_HSPECEst_NotificationThresholdLimit
    local hyd_HSPECEst_NotificationThresholdPercentage
    local hyd_HSPECEst_AlphaNumerator
    local hyd_HSPECEst_AlphaDenominator
    local hyd_HSPECEst_LocalFlowRateThreshold
    local hyd_HSPECEst_LocalFlowRatioThreshold
    local hyd_HSPECEst_MaxHActiveEntries

    hyd_HSPECEst=$(config get hyd_HSPECEst)
    if [ -n "$hyd_HSPECEst" ]; then
        uci set hyd.HSPECEst=$hyd_HSPECEst
    fi

    hyd_HSPECEst_UpdateHSPECInterval=$(config get hyd_HSPECEst_UpdateHSPECInterval)
    if [ -n "$hyd_HSPECEst_UpdateHSPECInterval" ]; then
        uci set hyd.HSPECEst_UpdateHSPECInterval=$hyd_HSPECEst_UpdateHSPECInterval
    fi

    hyd_HSPECEst_NotificationThresholdLimit=$(config get hyd_HSPECEst_NotificationThresholdLimit)
    if [ -n "$hyd_HSPECEst_NotificationThresholdLimit" ]; then
        uci set hyd.HSPECEst_NotificationThresholdLimit=$hyd_HSPECEst_NotificationThresholdLimit
    fi

    hyd_HSPECEst_NotificationThresholdPercentage=$(config get hyd_HSPECEst_NotificationThresholdPercentage)
    if [ -n "$hyd_HSPECEst_NotificationThresholdPercentage" ]; then
        uci set hyd.HSPECEst_NotificationThresholdPercentage=$hyd_HSPECEst_NotificationThresholdPercentage
    fi

    hyd_HSPECEst_AlphaNumerator=$(config get hyd_HSPECEst_AlphaNumerator)
    if [ -n "$hyd_HSPECEst_AlphaNumerator" ]; then
        uci set hyd.HSPECEst_AlphaNumerator=$hyd_HSPECEst_AlphaNumerator
    fi

    hyd_HSPECEst_AlphaDenominator=$(config get hyd_HSPECEst_AlphaDenominator)
    if [ -n "$hyd_HSPECEst_AlphaDenominator" ]; then
        uci set hyd.HSPECEst_AlphaDenominator=$hyd_HSPECEst_AlphaDenominator
    fi

    hyd_HSPECEst_LocalFlowRateThreshold=$(config get hyd_HSPECEst_LocalFlowRateThreshold)
    if [ -n "$hyd_HSPECEst_LocalFlowRateThreshold" ]; then
        uci set hyd.HSPECEst_LocalFlowRateThreshold=$hyd_HSPECEst_LocalFlowRateThreshold
    fi

    hyd_HSPECEst_LocalFlowRatioThreshold=$(config get hyd_HSPECEst_LocalFlowRatioThreshold)
    if [ -n "$hyd_HSPECEst_LocalFlowRatioThreshold" ]; then
        uci set hyd.HSPECEst_LocalFlowRatioThreshold=$hyd_HSPECEst_LocalFlowRatioThreshold
    fi

    hyd_HSPECEst_MaxHActiveEntries=$(config get hyd_HSPECEst_MaxHActiveEntries)
    if [ -n "$hyd_HSPECEst_MaxHActiveEntries" ]; then
        uci set hyd.HSPECEst_MaxHActiveEntries=$hyd_HSPECEst_MaxHActiveEntries
    fi

    # hyd.PathSelect
    local hyd_PathSelect
    local hyd_PathSelect_UpdateHDInterval
    local hyd_PathSelect_LinkCapacityThreshold
    local hyd_PathSelect_UDPInterfaceOrder
    local hyd_PathSelect_NonUDPInterfaceOrder
    local hyd_PathSelect_SerialflowIterations
    local hyd_PathSelect_DeltaLCThreshold

    hyd_PathSelect=$(config get hyd_PathSelect)
    if [ -n "$hyd_PathSelect" ]; then
        uci set hyd.PathSelect=$hyd_PathSelect
    fi

    hyd_PathSelect_UpdateHDInterval=$(config get hyd_PathSelect_UpdateHDInterval)
    if [ -n "$hyd_PathSelect_UpdateHDInterval" ]; then
        uci set hyd.PathSelect_UpdateHDInterval=$hyd_PathSelect_UpdateHDInterval
    fi

    hyd_PathSelect_LinkCapacityThreshold=$(config get hyd_PathSelect_LinkCapacityThreshold)
    if [ -n "$hyd_PathSelect_LinkCapacityThreshold" ]; then
        uci set hyd.PathSelect_LinkCapacityThreshold=$hyd_PathSelect_LinkCapacityThreshold
    fi

    hyd_PathSelect_UDPInterfaceOrder=$(config get hyd_PathSelect_UDPInterfaceOrder)
    if [ -n "$hyd_PathSelect_UDPInterfaceOrder" ]; then
        uci set hyd.PathSelect_UDPInterfaceOrder=$hyd_PathSelect_UDPInterfaceOrder
    fi

    hyd_PathSelect_NonUDPInterfaceOrder=$(config get hyd_PathSelect_NonUDPInterfaceOrder)
    if [ -n "$hyd_PathSelect_NonUDPInterfaceOrder" ]; then
        uci set hyd.PathSelect_NonUDPInterfaceOrder=$hyd_PathSelect_NonUDPInterfaceOrder
    fi


    hyd_PathSelect_SerialflowIterations=$(config get hyd_PathSelect_SerialflowIterations)
    if [ -n "$hyd_PathSelect_SerialflowIterations" ]; then
        uci set hyd.PathSelect_SerialflowIterations=$hyd_PathSelect_SerialflowIterations
    fi

    hyd_PathSelect_DeltaLCThreshold=$(config get hyd_PathSelect_DeltaLCThreshold)
    if [ -n "$hyd_PathSelect_DeltaLCThreshold" ]; then
        uci set hyd.PathSelect_DeltaLCThreshold=$hyd_PathSelect_DeltaLCThreshold
    fi

    # hyd.LogSettings
    local hyd_LogSettings
    local hyd_LogSettings_EnableLog
    local hyd_LogSettings_LogRestartIntervalSec
    local hyd_LogSettings_LogPCSummaryPeriodSec
    local hyd_LogSettings_LogServerIP
    local hyd_LogSettings_LogServerPort
    local hyd_LogSettings_EnableLogPCW2
    local hyd_LogSettings_EnableLogPCW5
    local hyd_LogSettings_EnableLogPCP
    local hyd_LogSettings_EnableLogTD
    local hyd_LogSettings_EnableLogHE
    local hyd_LogSettings_EnableLogHETables
    local hyd_LogSettings_EnableLogPS
    local hyd_LogSettings_EnableLogPSTables
    local hyd_LogSettings_LogHEThreshold1
    local hyd_LogSettings_LogHEThreshold2

    hyd_LogSettings=$(config get hyd_LogSettings)
    if [ -n "$hyd_LogSettings" ]; then
        uci set hyd.LogSettings=$hyd_LogSettings
    fi

    hyd_LogSettings_EnableLog=$(config get hyd_LogSettings_EnableLog)
    if [ -n "$hyd_LogSettings_EnableLog" ]; then
        uci set hyd.LogSettings_EnableLog=$hyd_LogSettings_EnableLog
    fi

    hyd_LogSettings_LogRestartIntervalSec=$(config get hyd_LogSettings_LogRestartIntervalSec)
    if [ -n "$hyd_LogSettings_LogRestartIntervalSec" ]; then
        uci set hyd.LogSettings_LogRestartIntervalSec=$hyd_LogSettings_LogRestartIntervalSec
    fi

    hyd_LogSettings_LogPCSummaryPeriodSec=$(config get hyd_LogSettings_LogPCSummaryPeriodSec)
    if [ -n "$hyd_LogSettings_LogPCSummaryPeriodSec" ]; then
        uci set hyd.LogSettings_LogPCSummaryPeriodSec=$hyd_LogSettings_LogPCSummaryPeriodSec
    fi

    hyd_LogSettings_LogServerIP=$(config get hyd_LogSettings_LogServerIP)
    if [ -n "$hyd_LogSettings_LogServerIP" ]; then
        uci set hyd.LogSettings_LogServerIP=$hyd_LogSettings_LogServerIP
    fi

    hyd_LogSettings_LogServerPort=$(config get hyd_LogSettings_LogServerPort)
    if [ -n "$hyd_LogSettings_LogServerPort" ]; then
        uci set hyd.LogSettings_LogServerPort=$hyd_LogSettings_LogServerPort
    fi

    hyd_LogSettings_EnableLogPCW2=$(config get hyd_LogSettings_EnableLogPCW2)
    if [ -n "$hyd_LogSettings_EnableLogPCW2" ]; then
        uci set hyd.LogSettings_EnableLogPCW2=$hyd_LogSettings_EnableLogPCW2
    fi

    hyd_LogSettings_EnableLogPCW5=$(config get hyd_LogSettings_EnableLogPCW5)
    if [ -n "$hyd_LogSettings_EnableLogPCW5" ]; then
        uci set hyd.LogSettings_EnableLogPCW5=$hyd_LogSettings_EnableLogPCW5
    fi

    hyd_LogSettings_EnableLogPCP=$(config get hyd_LogSettings_EnableLogPCP)
    if [ -n "$hyd_LogSettings_EnableLogPCP" ]; then
        uci set hyd.LogSettings_EnableLogPCP=$hyd_LogSettings_EnableLogPCP
    fi

    hyd_LogSettings_EnableLogTD=$(config get hyd_LogSettings_EnableLogTD)
    if [ -n "$hyd_LogSettings_EnableLogTD" ]; then
        uci set hyd.LogSettings_EnableLogTD=$hyd_LogSettings_EnableLogTD
    fi

    hyd_LogSettings_EnableLogHE=$(config get hyd_LogSettings_EnableLogHE)
    if [ -n "$hyd_LogSettings_EnableLogHE" ]; then
        uci set hyd.LogSettings_EnableLogHE=$hyd_LogSettings_EnableLogHE
    fi

    hyd_LogSettings_EnableLogHETables=$(config get hyd_LogSettings_EnableLogHETables)
    if [ -n "$hyd_LogSettings_EnableLogHETables" ]; then
        uci set hyd.LogSettings_EnableLogHETables=$hyd_LogSettings_EnableLogHETables
    fi

    hyd_LogSettings_EnableLogPS=$(config get hyd_LogSettings_EnableLogPS)
    if [ -n "$hyd_LogSettings_EnableLogPS" ]; then
        uci set hyd.LogSettings_EnableLogPS=$hyd_LogSettings_EnableLogPS
    fi

    hyd_LogSettings_EnableLogPSTables=$(config get hyd_LogSettings_EnableLogPSTables)
    if [ -n "$hyd_LogSettings_EnableLogPSTables" ]; then
        uci set hyd.LogSettings_EnableLogPSTables=$hyd_LogSettings_EnableLogPSTables
    fi

    hyd_LogSettings_LogHEThreshold1=$(config get hyd_LogSettings_LogHEThreshold1)
    if [ -n "$hyd_LogSettings_LogHEThreshold1" ]; then
        uci set hyd.LogSettings_LogHEThreshold1=$hyd_LogSettings_LogHEThreshold1
    fi

    hyd_LogSettings_LogHEThreshold2=$(config get hyd_LogSettings_LogHEThreshold2)
    if [ -n "$hyd_LogSettings_LogHEThreshold2" ]; then
        uci set hyd.LogSettings_LogHEThreshold2=$hyd_LogSettings_LogHEThreshold2
    fi

    # hyd.IEEE1905Settings
    local hyd_IEEE1905Settings
    local hyd_IEEE1905Settings_StrictIEEE1905Mode
    local hyd_IEEE1905Settings_GenerateLLDP
    local hyd_IEEE1905Settings_AvoidDupRenew
    local hyd_IEEE1905Settings_AvoidDupTopologyNotification

    hyd_IEEE1905Settings=$(config get hyd_IEEE1905Settings)
    if [ -n "$hyd_IEEE1905Settings" ]; then
        uci set hyd.IEEE1905Settings=$hyd_IEEE1905Settings
    fi

    hyd_IEEE1905Settings_StrictIEEE1905Mode=$(config get hyd_IEEE1905Settings_StrictIEEE1905Mode)
    if [ -n "$hyd_IEEE1905Settings_StrictIEEE1905Mode" ]; then
        uci set hyd.IEEE1905Settings_StrictIEEE1905Mode=$hyd_IEEE1905Settings_StrictIEEE1905Mode
    fi

    hyd_IEEE1905Settings_GenerateLLDP=$(config get hyd_IEEE1905Settings_GenerateLLDP)
    if [ -n "$hyd_IEEE1905Settings_GenerateLLDP" ]; then
        uci set hyd.IEEE1905Settings_GenerateLLDP=$hyd_IEEE1905Settings_GenerateLLDP
    fi

    hyd_IEEE1905Settings_AvoidDupRenew=$(config get hyd_IEEE1905Settings_AvoidDupRenew)
    if [ -n "$hyd_IEEE1905Settings_AvoidDupRenew" ]; then
        uci set hyd.IEEE1905Settings.AvoidDupRenew=$hyd_IEEE1905Settings_AvoidDupRenew
    fi

    hyd_IEEE1905Settings_AvoidDupTopologyNotification=$(config get hyd_IEEE1905Settings_AvoidDupTopologyNotification)
    if [ -n "$hyd_IEEE1905Settings_AvoidDupTopologyNotification" ]; then
        uci set hyd.IEEE1905Settings.AvoidDupTopologyNotification=$hyd_IEEE1905Settings_AvoidDupTopologyNotification
    fi

    # hyd.HCPSettings
    local hyd_HCPSettings
    local hyd_HCPSettings_V1Compat

    hyd_HCPSettings=$(config get hyd_HCPSettings)
    if [ -n "$hyd_HCPSettings" ]; then
        uci set hyd.HCPSettings=$hyd_HCPSettings
    fi

    hyd_HCPSettings_V1Compat=$(config get hyd_HCPSettings_V1Compat)
    if [ -n "$hyd_HCPSettings_V1Compat" ]; then
        uci set hyd.HCPSettings_V1Compat=$hyd_HCPSettings_V1Compat
    fi

    # hyd.SteerMsg
    local hyd_SteerMsg
    local hyd_SteerMsg_AvgUtilReqTimeout
    local hyd_SteerMsg_LoadBalancingCompleteTimeout
    local hyd_SteerMsg_RspTimeout

    hyd_SteerMsg=$(config get hyd_SteerMsg)
    if [ -n "$hyd_SteerMsg" ]; then
        uci set hyd.SteerMsg=$hyd_SteerMsg
    fi

    hyd_SteerMsg_AvgUtilReqTimeout=$(config get hyd_SteerMsg_AvgUtilReqTimeout)
    if [ -n "$hyd_SteerMsg_AvgUtilReqTimeout" ]; then
        uci set hyd.SteerMsg_AvgUtilReqTimeout=$hyd_SteerMsg_AvgUtilReqTimeout
    fi

    hyd_SteerMsg_LoadBalancingCompleteTimeout=$(config get hyd_SteerMsg_LoadBalancingCompleteTimeout)
    if [ -n "$hyd_SteerMsg_LoadBalancingCompleteTimeout" ]; then
        uci set hyd.SteerMsg_LoadBalancingCompleteTimeout=$hyd_SteerMsg_LoadBalancingCompleteTimeout
    fi

    hyd_SteerMsg_RspTimeout=$(config get hyd_SteerMsg_RspTimeout)
    if [ -n "$hyd_SteerMsg_RspTimeout" ]; then
        uci set hyd.SteerMsg_RspTimeout=$hyd_SteerMsg_RspTimeout
    fi
}

repacd_updateDNI_config() {
    #Orbi DNI setting
    if [ "$orbi_type" = "Base" ]; then
        config set repacd_enable=1
        uci set repacd.repacd.Enable=1

        if [ "x$(/bin/config get factory_mode)" = "x1" ]; then
            config set repacd_enable=0
            uci set repacd.repacd.Enable=0
        fi

        uci set repacd.repacd.DeviceType=CAP
        uci set repacd.repacd.Role=CAP
        uci set repacd.repacd.DefaultREMode=son
        if [ "x`/bin/config get enable_arlo_function`" = "x1" ];then
            ifname=`awk -v input_optype=ARLO -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
            if [ -n "$ifname" ]; then
                uci set repacd.repacd.DNI_TrafficSeparationEnabled=1
                uci set repacd.repacd.DNI_TrafficSeparationActive=1
                uci set repacd.repacd.NetworkBackhaul=backhaul
                network_arlo=$(config get i_wlg_arlo_br)
                uci set repacd.repacd.NetworkGuest=${network_arlo#"br"}
            fi
        fi
        config commit
    elif [ "$orbi_type" = "Satellite" ]; then
        uci set repacd.repacd.ConfigREMode=son

        local repacd_enable
        repacd_enable=$(config get repacd_enable)

        case $repacd_enable in
        1)
            uci set repacd.repacd.Enable=1
        ;;
        0)
            uci set repacd.repacd.Enable=0
        ;;
        "")
            repacd_enable=$(uci get repacd.repacd.Enable)
            config set repacd_enable=$repacd_enable
            config commit
        ;;
        esac

        local repacd_ManagedNetwork
        repacd_ManagedNetwork=$(config get repacd_ManagedNetwork)
        if [ -n "$repacd_ManagedNetwork" ]; then
            uci set repacd.repacd.ManagedNetwork=$repacd_ManagedNetwork
        fi

        local repacd_GatewayconnectedMode
        repacd_GatewayconnectedMode=$(config get repacd_GatewayconnectedMode)
        if [ -n "$repacd_GatewayconnectedMode" ]; then
            uci set repacd.repacd.GatewayconnectedMode=$repacd_GatewayconnectedMode
        fi

        local repacd_ConfigREMode
        repacd_ConfigREMode=$(config get repacd_ConfigREMode)
        if [ -n "$repacd_ConfigREMode" ]; then
            uci set repacd.repacd.ConfigREMode=$repacd_ConfigREMode
        fi

        local repacd_DefaultREMode
        repacd_DefaultREMode=$(config get repacd_DefaultREMode)
        if [ -n "$repacd_DefaultREMode" ]; then
            uci set repacd.repacd.DefaultREMode=$repacd_DefaultREMode
        fi

        local repacd_BlockDFSChannles
        repacd_BlockDFSChannles=$(config get repacd_BlockDFSChannles)
        if [ -n "$repacd_BlockDFSChannles" ]; then
            uci set repacd.repacd.BlockDFSChannles=$repacd_BlockDFSChannles
        fi

        local repacd_EnableSON
        repacd_EnableSON=$(config get repacd_EnableSON)
        if [ -n "$repacd_EnableSON" ]; then
            uci set repacd.repacd.EnableSON=$repacd_EnableSON
        fi

        local repacd_ManageMCSD
        repacd_ManageMCSD=$(config get repacd_ManageMCSD)
        if [ -n "$repacd_ManageMCSD" ]; then
            uci set repacd.repacd.ManageMCSD=$repacd_ManageMCSD
        fi

        local repacd_LinkCheckDelay
        repacd_LinkCheckDelay=$(config get repacd_LinkCheckDelay)
        if [ -n "$repacd_LinkCheckDelay" ]; then
            uci set repacd.repacd.LinkCheckDelay=$repacd_LinkCheckDelay
        fi

        local repacd_DNI_Mode
        repacd_DNI_Mode=$(config get repacd_DNI_Mode)
        if [ -n "$repacd_DNI_Mode" ]; then
            uci set repacd.repacd.DNI_Mode=$repacd_DNI_Mode
        fi

        local repacd_TrafficSeparationEnabled
        repacd_TrafficSeparationEnabled=$(config get repacd_TrafficSeparationEnabled)
        if [ -n "$repacd_TrafficSeparationEnabled" ]; then
            uci set repacd.repacd.TrafficSeparationEnabled=$repacd_TrafficSeparationEnabled
        fi

        local repacd_NetworkGuest
        repacd_NetworkGuest=$(config get repacd_NetworkGuest)
        if [ -n "$repacd_NetworkGuest" ]; then
            uci set repacd.repacd.NetworkGuest=$repacd_NetworkGuest
        fi

        local repacd_NetworkGuestBackhaulInterface
        repacd_NetworkGuestBackhaulInterface=$(config get repacd_NetworkGuestBackhaulInterface)
        if [ -n "$repacd_NetworkGuestBackhaulInterface" ]; then
            uci set repacd.repacd.NetworkGuestBackhaulInterface=$repacd_NetworkGuestBackhaulInterface
        fi

        local repacd_EnableSteering
        repacd_EnableSteering=$(config get repacd_EnableSteering)
        if [ -n "$repacd_EnableSteering" ]; then
            uci set repacd.repacd.EnableSteering=$repacd_EnableSteering
        fi

        # repacd.WiFiLink
        local repacd_WiFiLink
        local repacd_MinAssocCheckAutoMode
        local repacd_MinAssocCheckPostWPS
        local repacd_MinAssocCheckPostBSSIDConfig
        local repacd_WPSTimeout
        local repacd_AssociationTimeout
        local repacd_RSSINumMeasurements
        local repacd_RSSIThresholdFar
        local repacd_RSSIThresholdNear
        local repacd_RSSIThresholdMin
        local repacd_2GBackhaulSwitchDownTime
        local repacd_RateNumMeasurements
        local repacd_5GBackhaulBadlinkTimeout
        local repacd_2GBackhaulEvalTime
        local repacd_2GIndependentChannelSelectionEnable
        local repacd_2GIndependentChannelSelectionRssiLevel
        local repacd_2GIndependentChannelSelectionTotalRssiCounter
        local repacd_2GIndependentChannelSelectionRssiDebug
        local repacd_2GIndependentChannelSelectionStartRssiCheckTime
        local repacd_BSSIDResolveState
        local repacd_MoveFromCAPSNRHysteresis5G

        repacd_WiFiLink=$(config get repacd_WiFiLink)
        if [ -n "$repacd_WiFiLink" ]; then
            uci set repacd.WiFiLink=$repacd_WiFiLink
        fi

        repacd_MinAssocCheckAutoMode=$(config get repacd_MinAssocCheckAutoMode)
        if [ -n "$repacd_MinAssocCheckAutoMode" ]; then
            uci set repacd.WiFiLink.MinAssocCheckAutoMode=$repacd_MinAssocCheckAutoMode
        fi

        repacd_MinAssocCheckPostWPS=$(config get repacd_MinAssocCheckPostWPS)
        if [ -n "$repacd_MinAssocCheckPostWPS" ]; then
            uci set repacd.WiFiLink.MinAssocCheckPostWPS=$repacd_MinAssocCheckPostWPS
        fi

        repacd_MinAssocCheckPostBSSIDConfig=$(config get repacd_MinAssocCheckPostBSSIDConfig)
        if [ -n "$repacd_MinAssocCheckPostBSSIDConfig" ]; then
            uci set repacd.WiFiLink.MinAssocCheckPostBSSIDConfig=$repacd_MinAssocCheckPostBSSIDConfig
        fi

        repacd_WPSTimeout=$(config get repacd_WPSTimeout)
        if [ -n "$repacd_WPSTimeout" ]; then
            uci set repacd.WiFiLink.WPSTimeout=$repacd_WPSTimeout
        fi

        repacd_AssociationTimeout=$(config get repacd_AssociationTimeout)
        if [ -n "$repacd_AssociationTimeout" ]; then
            uci set repacd.WiFiLink.AssociationTimeout=$repacd_AssociationTimeout
        fi

        repacd_RSSINumMeasurements=$(config get repacd_RSSINumMeasurements)
        if [ -n "$repacd_RSSINumMeasurements" ]; then
            uci set repacd.WiFiLink.RSSINumMeasurements=$repacd_RSSINumMeasurements
        fi

        repacd_RSSIThresholdFar=$(config get repacd_aRSSIThresholdFar)
        if [ -n "$repacd_RSSIThresholdFar" ]; then
            uci set repacd.WiFiLink.RSSIThresholdFar=$repacd_RSSIThresholdFar
        fi

        repacd_RSSIThresholdNear=$(config get repacd_RSSIThresholdNear)
        if [ -n "$repacd_RSSIThresholdNear" ]; then
            uci set repacd.WiFiLink.RSSIThresholdNear=$repacd_RSSIThresholdNear
        fi

        repacd_RSSIThresholdMin=$(config get repacd_RSSIThresholdMin)
        if [ -n "$repacd_RSSIThresholdMin" ]; then
            uci set repacd.WiFiLink.RSSIThresholdMin=$repacd_RSSIThresholdMin
        fi

        repacd_2GBackhaulSwitchDownTime=$(config get repacd_2GBackhaulSwitchDownTime)
        if [ -n "$repacd_2GBackhaulSwitchDownTime" ]; then
            uci set repacd.WiFiLink.2GBackhaulSwitchDownTime=$repacd_2GBackhaulSwitchDownTime
        fi

        repacd_RateNumMeasurements=$(config get repacd_RateNumMeasurements)
        if [ -n "$repacd_RateNumMeasurements" ]; then
            uci set repacd.WiFiLink.RateNumMeasurements=$repacd_RateNumMeasurements
        fi

        repacd_5GBackhaulBadlinkTimeout=$(config get repacd_5GBackhaulBadlinkTimeout)
        if [ -n "$repacd_5GBackhaulBadlinkTimeout" ]; then
            uci set repacd.WiFiLink.5GBackhaulBadlinkTimeout=$repacd_5GBackhaulBadlinkTimeout
        fi

        repacd_=$(config get repacd_2GBackhaulEvalTime)
        if [ -n "$repacd_2GBackhaulEvalTime" ]; then
            uci set repacd.WiFiLink.2GBackhaulEvalTime=$repacd_2GBackhaulEvalTime
        fi

        repacd_2GIndependentChannelSelectionEnable=$(config get repacd_2GIndependentChannelSelectionEnable)
        if [ -n "$repacd_2GIndependentChannelSelectionEnable" ]; then
            uci set repacd.WiFiLink.2GIndependentChannelSelectionEnable=$repacd_2GIndependentChannelSelectionEnable
        fi


        repacd_2GIndependentChannelSelectionRssiLevel=$(config get repacd_2GIndependentChannelSelectionRssiLevel)
        if [ -n "$repacd_2GIndependentChannelSelectionRssiLevel" ]; then
            uci set repacd.WiFiLink.2GIndependentChannelSelectionRssiLevel=$repacd_2GIndependentChannelSelectionRssiLevel
        fi

        repacd_2GIndependentChannelSelectionTotalRssiCounter=$(config get repacd_2GIndependentChannelSelectionTotalRssiCounter)
        if [ -n "$repacd_2GIndependentChannelSelectionTotalRssiCounter" ]; then
            uci set repacd.WiFiLink.2GIndependentChannelSelectionTotalRssiCounter=$repacd_2GIndependentChannelSelectionTotalRssiCounter
        fi


        repacd_2GIndependentChannelSelectionRssiDebug=$(config get repacd_2GIndependentChannelSelectionRssiDebug)
        if [ -n "$repacd_2GIndependentChannelSelectionRssiDebug" ]; then
            uci set repacd.WiFiLink.2GIndependentChannelSelectionRssiDebug=$repacd_2GIndependentChannelSelectionRssiDebug
        fi


        repacd_2GIndependentChannelSelectionStartRssiCheckTime=$(config get repacd_2GIndependentChannelSelectionStartRssiCheckTime)
        if [ -n "$repacd_2GIndependentChannelSelectionStartRssiCheckTime" ]; then
            uci set repacd.WiFiLink.2GIndependentChannelSelectionStartRssiCheckTime=$repacd_2GIndependentChannelSelectionStartRssiCheckTime
        fi


        repacd_BSSIDResolveState=$(config get repacd_BSSIDResolveState)
        if [ -n "$repacd_BSSIDResolveState" ]; then
            uci set repacd.WiFiLink.BSSIDResolveState=$repacd_BSSIDResolveState
        fi

        repacd_MoveFromCAPSNRHysteresis5G=$(config get repacd_MoveFromCAPSNRHysteresis5G)
        if [ -n "$repacd_MoveFromCAPSNRHysteresis5G" ]; then
            uci set repacd.WiFiLink.MoveFromCAPSNRHysteresis5G=$repacd_MoveFromCAPSNRHysteresis5G
        fi

        # repacd.Reset
        local repacd_Reset
        local repacd_Reset_Brightness_1
        local repacd_Reset_Trigger_1
        local repacd_Reset_Name_1
        local repacd_Reset_Brightness_2
        local repacd_Reset_Trigger_2
        local repacd_Reset_Name_2

        repacd_Reset=$(config get repacd_Reset)
        if [ -n "$repacd_Reset" ]; then
            uci set repacd.Reset=$repacd_Reset
        fi

        repacd_Reset_Name_1=$(config get repacd_Reset_Name_1)
        if [ -n "$repacd_Reset_Name_1" ]; then
            uci set repacd.Reset.Name_1=$repacd_Reset_Name_1
        fi

        repacd_Reset_Trigger_1=$(config get repacd_Reset_Trigger_1)
        if [ -n "$repacd_Reset_Trigger_1" ]; then
            uci set repacd.Reset.Trigger_1=$repacd_Reset_Trigger_1
        fi

        repacd_Brightness_1=$(config get repacd_Reset_Brightness_1)
        if [ -n "$repacd_Reset_Brightness_1" ]; then
            uci set repacd.Reset.Brightness_1=$repacd_Reset_Brightness_1
        fi

        repacd_Reset_Name_2=$(config get repacd_Reset_Name_2)
        if [ -n "$repacd_Reset_Name_2" ]; then
            uci set repacd.Reset.Name_2=$repacd_Reset_Name_2
        fi

        repacd_Reset_Trigger_2=$(config get repacd_Reset_Trigger_2)
        if [ -n "$repacd_Reset_Trigger_2" ]; then
            uci set repacd.Reset.Trigger_2=$repacd_Reset_Trigger_2
        fi

        repacd_Reset_Brightness_2=$(config get repacd_Reset_Brightness_2)
        if [ -n "$repacd_Reset_Brightness_2" ]; then
            uci set repacd.Reset.Brightness_2=$repacd_Reset_Brightness_2
        fi

        # repacd.NotAssociated
        local repacd_NotAssociated
        local repacd_NotAssociated_Name_1
        local repacd_NotAssociated_Trigger_1
        local repacd_NotAssociated_Brightness_1
        local repacd_NotAssociated_DelayOn_1
        local repacd_NotAssociated_DelayOff_1
        local repacd_NotAssociated_Name_2
        local repacd_NotAssociated_Trigger_2
        local repacd_NotAssociated_Brightness_2

        repacd_NotAssociated=$(config get repacd_NotAssociated)
        if [ -n "$repacd_NotAssociated" ]; then
            uci set repacd.NotAssociated=$repacd_NotAssociated
        fi

        repacd_NotAssociated_Name_1=$(config get repacd_NotAssociated_Name_1)
        if [ -n "$repacd_NotAssociated_Name_1" ]; then
            uci set repacd.NotAssociated.Name_1=$repacd_NotAssociated_Name_1
        fi

        repacd_NotAssociated_Trigger_1=$(config get repacd_NotAssociated_Trigger_1)
        if [ -n "$repacd_NotAssociated_Trigger_1" ]; then
            uci set repacd.NotAssociated.Trigger_1=$repacd_NotAssociated_Trigger_1
        fi

        repacd_NotAssociated_Brightness_1=$(config get repacd_NotAssociated_Brightness_1)
        if [ -n "$repacd_NotAssociated_Brightness_1" ]; then
            uci set repacd.NotAssociated.Brightness_1=$repacd_NotAssociated_Brightness_1
        fi

        repacd_NotAssociated_DelayOn_1=$(config get repacd_NotAssociated_DelayOn_1)
        if [ -n "$repacd_NotAssociated_DelayOn_1" ]; then
            uci set repacd.NotAssociated.DelayOn_1=$repacd_NotAssociated_DelayOn_1
        fi

        repacd_NotAssociated_DelayOff_1=$(config get repacd_NotAssociated_DelayOff_1)
        if [ -n "$repacd_NotAssociated_DelayOff_1" ]; then
            uci set repacd.NotAssociated.DelayOff_1=$repacd_NotAssociated_DelayOff_1
        fi

        repacd_NotAssociated_Name_2=$(config get repacd_NotAssociated_Name_2)
        if [ -n "$repacd_NotAssociated_Name_2" ]; then
            uci set repacd.NotAssociated.Name_2=$repacd_NotAssociated_Name_2
        fi

        repacd_NotAssociated_Trigger_2=$(config get repacd_NotAssociated_Trigger_2)
        if [ -n "$repacd_NotAssociated_Trigger_2" ]; then
            uci set repacd.NotAssociated.Trigger_2=$repacd_NotAssociated_Trigger_2
        fi

        repacd_NotAssociated_Brightness_2=$(config get repacd_NotAssociated_Brightness_2)
        if [ -n "$repacd_NotAssociated_Brightness_2" ]; then
            uci set repacd.NotAssociated.Brightness_2=$repacd_NotAssociated_Brightness_2
        fi

        # repacd.AutoConfigInProgress
        local repacd_AutoConfigInProgress
        local repacd_AutoConfigInProgress_Name_1
        local repacd_AutoConfigInProgress_Trigger_1
        local repacd_AutoConfigInProgress_Brightness_1
        local repacd_AutoConfigInProgress_DelayOn_1
        local repacd_AutoConfigInProgress_DelayOff_1
        local repacd_AutoConfigInProgress_Name_2
        local repacd_AutoConfigInProgress_Trigger_2
        local repacd_AutoConfigInProgress_Brightness_2

        repacd_AutoConfigInProgress=$(config get repacd_AutoConfigInProgress)
        if [ -n "$repacd_AutoConfigInProgress" ]; then
            uci set repacd.AutoConfigInProgress=$repacd_AutoConfigInProgress
        fi

        repacd_AutoConfigInProgress_Name_1=$(config get repacd_AutoConfigInProgress_Name_1)
        if [ -n "$repacd_AutoConfigInProgress_Name_1" ]; then
            uci set repacd.AutoConfigInProgress.Name_1=$repacd_AutoConfigInProgress_Name_1
        fi

        repacd_AutoConfigInProgress_Trigger_1=$(config get repacd_AutoConfigInProgress_Trigger_1)
        if [ -n "$repacd_AutoConfigInProgress_Trigger_1" ]; then
            uci set repacd.AutoConfigInProgress.Trigger_1=$repacd_AutoConfigInProgress_Trigger_1
        fi

        repacd_AutoConfigInProgress_Brightness_1=$(config get repacd_AutoConfigInProgress_Brightness_1)
        if [ -n "$repacd_AutoConfigInProgress_Brightness_1" ]; then
            uci set repacd.AutoConfigInProgress.Brightness_1=$repacd_AutoConfigInProgress_Brightness_1
        fi

        repacd_AutoConfigInProgress_DelayOn_1=$(config get repacd_AutoConfigInProgress_DelayOn_1)
        if [ -n "$repacd_AutoConfigInProgress_DelayOn_1" ]; then
            uci set repacd.AutoConfigInProgress.DelayOn_1=$repacd_AutoConfigInProgress_DelayOn_1
        fi

        repacd_AutoConfigInProgress_DelayOff_1=$(config get repacd_AutoConfigInProgress_DelayOff_1)
        if [ -n "$repacd_AutoConfigInProgress_DelayOff_1" ]; then
            uci set repacd.AutoConfigInProgress.DelayOff_1=$repacd_AutoConfigInProgress_DelayOff_1
        fi

        repacd_AutoConfigInProgress_Name_2=$(config get repacd_AutoConfigInProgress_Name_2)
        if [ -n "$repacd_AutoConfigInProgress_Name_2" ]; then
            uci set repacd.AutoConfigInProgress.Name_2=$repacd_AutoConfigInProgress_Name_2
        fi

        repacd_AutoConfigInProgress_Trigger_2=$(config get repacd_AutoConfigInProgress_Trigger_2)
        if [ -n "$repacd_AutoConfigInProgress_Trigger_2" ]; then
            uci set repacd.AutoConfigInProgress.Trigger_2=$repacd_AutoConfigInProgress_Trigger_2
        fi

        repacd_NotAssociated_Brightness_2=$(config get repacd_NotAssociated_Brightness_2)
        if [ -n "$repacd_NotAssociated_Brightness_2" ]; then
            uci set repacd.NotAssociated.Brightness_2=$repacd_NotAssociated_Brightness_2
        fi

        # repacd.Measuring
        local repacd_Measuring
        local repacd_Measuring_Name_1
        local repacd_Measuring_Trigger_1
        local repacd_Measuring_Brightness_1
        local repacd_Measuring_DelayOn_1
        local repacd_Measuring_DelayOff_1
        local repacd_Measuring_Name_2
        local repacd_Measuring_Trigger_2
        local repacd_Measuring_Brightness_2
        local repacd_Measuring_DelayOn_2
        local repacd_Measuring_DelayOff_2

        repacd_Measuring=$(config get repacd_Measuring)
        if [ -n "$repacd_Measuring" ]; then
            uci set repacd.Measuring=$repacd_Measuring
        fi

        repacd_Measuring_Name_1=$(config get repacd_Measuring_Name_1)
        if [ -n "$repacd_Measuring_Name_1" ]; then
            uci set repacd.Measuring.Name_1=$repacd_Measuring_Name_1
        fi

        repacd_Measuring_Trigger_1=$(config get repacd_Measuring_Trigger_1)
        if [ -n "$repacd_Measuring_Trigger_1" ]; then
            uci set repacd.Measuring.Trigger_1=$repacd_Measuring_Trigger_1
        fi

        repacd_Measuring_Brightness_1=$(config get repacd_Measuring_Brightness_1)
        if [ -n "$repacd_Measuring_Brightness_1" ]; then
            uci set repacd.Measuring.Brightness_1=$repacd_Measuring_Brightness_1
        fi

        repacd_Measuring_DelayOn_1=$(config get repacd_Measuring_DelayOn_1)
        if [ -n "$repacd_Measuring_DelayOn_1" ]; then
            uci set repacd.Measuring.DelayOn_1=$repacd_Measuring_DelayOn_1
        fi

        repacd_Measuring_DelayOff_1=$(config get repacd_Measuring_DelayOff_1)
        if [ -n "$repacd_Measuring_DelayOff_1" ]; then
            uci set repacd.Measuring.DelayOff_1=$repacd_Measuring_DelayOff_1
        fi

        repacd_Measuring_Name_2=$(config get repacd_Measuring_Name_2)
        if [ -n "$repacd_Measuring_Name_2" ]; then
            uci set repacd.Measuring.Name_2=$repacd_Measuring_Name_2
        fi

        repacd_Measuring_Trigger_2=$(config get repacd_Measuring_Trigger_2)
        if [ -n "$repacd_Measuring_Trigger_2" ]; then
            uci set repacd.Measuring.Trigger_2=$repacd_Measuring_Trigger_2
        fi

        repacd_Measuring_Brightness_2=$(config get repacd_Measuring_Brightness_2)
        if [ -n "$repacd_Measuring_Brightness_2" ]; then
            uci set repacd.Measuring.Brightness_2=$repacd_Measuring_Brightness_2
        fi

        repacd_Measuring_DelayOn_2=$(config get repacd_Measuring_DelayOn_2)
        if [ -n "$repacd_Measuring_DelayOn_2" ]; then
            uci set repacd.Measuring.DelayOn_2=$repacd_Measuring_DelayOn_2
        fi

        repacd_Measuring_DelayOff_2=$(config get repacd_Measuring_DelayOff_2)
        if [ -n "$repacd_Measuring_DelayOff_2" ]; then
            uci set repacd.Measuring.DelayOff_2=$repacd_Measuring_DelayOff_2
        fi

        # repacd.WPSTimeout
        local repacd_WPSTimeout
        local repacd_WPSTimeout_Name_1
        local repacd_WPSTimeout_Trigger_1
        local repacd_WPSTimeout_Brightness_1
        local repacd_WPSTimeout_DelayOn_1
        local repacd_WPSTimeout_DelayOff_1
        local repacd_WPSTimeout_Name_2
        local repacd_WPSTimeout_Trigger_2
        local repacd_WPSTimeout_Brightness_2

        repacd_WPSTimeout=$(config get repacd_WPSTimeout)
        if [ -n "$repacd_WPSTimeout" ]; then
            uci set repacd.WPSTimeout=$repacd_WPSTimeout
        fi

        repacd_WPSTimeout_Name_1=$(config get repacd_WPSTimeout_Name_1)
        if [ -n "$repacd_WPSTimeout_Name_1" ]; then
            uci set repacd.WPSTimeout.Name_1=$repacd_WPSTimeout_Name_1
        fi

        repacd_WPSTimeout_Trigger_1=$(config get repacd_WPSTimeout_Trigger_1)
        if [ -n "$repacd_WPSTimeout_Trigger_1" ]; then
            uci set repacd.WPSTimeout.Trigger_1=$repacd_WPSTimeout_Trigger_1
        fi

        repacd_WPSTimeout_Brightness_1=$(config get repacd_WPSTimeout_Brightness_1)
        if [ -n "$repacd_WPSTimeout_Brightness_1" ]; then
            uci set repacd.WPSTimeout.Brightness_1=$repacd_WPSTimeout_Brightness_1
        fi

        repacd_WPSTimeout_DelayOn_1=$(config get repacd_WPSTimeout_DelayOn_1)
        if [ -n "$repacd_WPSTimeout_DelayOn_1" ]; then
            uci set repacd.WPSTimeout.DelayOn_1=$repacd_WPSTimeout_DelayOn_1
        fi

        repacd_WPSTimeout_DelayOff_1=$(config get repacd_WPSTimeout_DelayOff_1)
        if [ -n "$repacd_WPSTimeout_DelayOff_1" ]; then
            uci set repacd.WPSTimeout.DelayOff_1=$repacd_WPSTimeout_DelayOff_1
        fi

        repacd_WPSTimeout_Name_2=$(config get repacd_WPSTimeout_Name_2)
        if [ -n "$repacd_WPSTimeout_Name_2" ]; then
            uci set repacd.WPSTimeout.Name_2=$repacd_WPSTimeout_Name_2
        fi

        repacd_WPSTimeout_Trigger_2=$(config get repacd_WPSTimeout_Trigger_2)
        if [ -n "$repacd_WPSTimeout_Trigger_2" ]; then
            uci set repacd.WPSTimeout.Trigger_2=$repacd_WPSTimeout_Trigger_2
        fi

        repacd_WPSTimeout_Brightness_2=$(config get repacd_WPSTimeout_Brightness_2)
        if [ -n "$repacd_WPSTimeout_Brightness_2" ]; then
            uci set repacd.WPSTimeout.Brightness_2=$repacd_WPSTimeout_Brightness_2
        fi

        # repacd.AssocTimeout
        local repacd_AssocTimeout
        local repacd_AssocTimeout_Name_1
        local repacd_AssocTimeout_Trigger_1
        local repacd_AssocTimeout_Brightness_1
        local repacd_AssocTimeout_DelayOn_1
        local repacd_AssocTimeout_DelayOff_1
        local repacd_AssocTimeout_Name_2
        local repacd_AssocTimeout_Trigger_2
        local repacd_AssocTimeout_Brightness_2

        repacd_AssocTimeout=$(config get repacd_AssocTimeout)
        if [ -n "$repacd_AssocTimeout" ]; then
            uci set repacd.AssocTimeout=$repacd_AssocTimeout
        fi

        repacd_AssocTimeout_Name_1=$(config get repacd_AssocTimeout_Name_1)
        if [ -n "$repacd_AssocTimeout_Name_1" ]; then
            uci set repacd.AssocTimeout.Name_1=$repacd_AssocTimeout_Name_1
        fi

        repacd_AssocTimeout_Trigger_1=$(config get repacd_AssocTimeout_Trigger_1)
        if [ -n "$repacd_AssocTimeout_Trigger_1" ]; then
            uci set repacd.AssocTimeout.Trigger_1=$repacd_AssocTimeout_Trigger_1
        fi

        repacd_AssocTimeout_Brightness_1=$(config get repacd_AssocTimeout_Brightness_1)
        if [ -n "$repacd_AssocTimeout_Brightness_1" ]; then
            uci set repacd.AssocTimeout.Brightness_1=$repacd_AssocTimeout_Brightness_1
        fi

        repacd_AssocTimeout_DelayOn_1=$(config get repacd_AssocTimeout_DelayOn_1)
        if [ -n "$repacd_AssocTimeout_DelayOn_1" ]; then
            uci set repacd.AssocTimeout.DelayOn_1=$repacd_AssocTimeout_DelayOn_1
        fi

        repacd_AssocTimeout_DelayOff_1=$(config get repacd_AssocTimeout_DelayOff_1)
        if [ -n "$repacd_AssocTimeout_DelayOff_1" ]; then
            uci set repacd.AssocTimeout.DelayOff_1=$repacd_AssocTimeout_DelayOff_1
        fi

        repacd_AssocTimeout_Name_2=$(config get repacd_AssocTimeout_Name_2)
        if [ -n "$repacd_AssocTimeout_Name_2" ]; then
            uci set repacd.AssocTimeout.Name_2=$repacd_AssocTimeout_Name_2
        fi

        repacd_AssocTimeout_Trigger_2=$(config get repacd_AssocTimeout_Trigger_2)
        if [ -n "$repacd_AssocTimeout_Trigger_2" ]; then
            uci set repacd.AssocTimeout.Trigger_2=$repacd_AssocTimeout_Trigger_2
        fi

        repacd_AssocTimeout_Brightness_2=$(config get repacd_AssocTimeout_Brightness_2)
        if [ -n "$repacd_AssocTimeout_Brightness_2" ]; then
            uci set repacd.AssocTimeout.Brightness_2=$repacd_AssocTimeout_Brightness_2
        fi

        # repacd.RE_MoveCloser
        local repacd_RE_MoveCloser
        local repacd_RE_MoveCloser_Name_1
        local repacd_RE_MoveCloser_Trigger_1
        local repacd_RE_MoveCloser_Brightness_1
        local repacd_RE_MoveCloser_Name_2
        local repacd_RE_MoveCloser_Trigger_2
        local repacd_RE_MoveCloser_Brightness_2

        repacd_RE_MoveCloser=$(config get repacd_RE_MoveCloser)
        if [ -n "$repacd_RE_MoveCloser" ]; then
            uci set repacd.RE_MoveCloser=$repacd_RE_MoveCloser
        fi

        repacd_RE_MoveCloser_Name_1=$(config get repacd_RE_MoveCloser_Name_1)
        if [ -n "$repacd_RE_MoveCloser_Name_1" ]; then
            uci set repacd.RE_MoveCloser.Name_1=$repacd_RE_MoveCloser_Name_1
        fi

        repacd_RE_MoveCloser_Trigger_1=$(config get repacd_RE_MoveCloser_Trigger_1)
        if [ -n "$repacd_RE_MoveCloser_Trigger_1" ]; then
            uci set repacd.RE_MoveCloser.Trigger_1=$repacd_RE_MoveCloser_Trigger_1
        fi

        repacd_RE_MoveCloser_Brightness_1=$(config get repacd_RE_MoveCloser_Brightness_1)
        if [ -n "$repacd_RE_MoveCloser_Brightness_1" ]; then
            uci set repacd.RE_MoveCloser.Brightness_1=$repacd_RE_MoveCloser_Brightness_1
        fi

        repacd_RE_MoveCloser_Name_2=$(config get repacd_RE_MoveCloser_Name_2)
        if [ -n "$repacd_RE_MoveCloser_Name_2" ]; then
            uci set repacd.RE_MoveCloser.Name_2=$repacd_RE_MoveCloser_Name_2
        fi

        repacd_RE_MoveCloser_Trigger_2=$(config get repacd_RE_MoveCloser_Trigger_2)
        if [ -n "$repacd_RE_MoveCloser_Trigger_2" ]; then
            uci set repacd.RE_MoveCloser.Trigger_2=$repacd_RE_MoveCloser_Trigger_2
        fi

        repacd_RE_MoveCloser_Brightness_2=$(config get repacd_RE_MoveCloser_Brightness_2)
        if [ -n "$repacd_RE_MoveCloser_Brightness_2" ]; then
            uci set repacd.RE_MoveCloser.Brightness_2=$repacd_RE_MoveCloser_Brightness_2
        fi

        # repacd.RE_MoveFarther
        local repacd_RE_MoveFarther
        local repacd_RE_MoveFarther_Name_1
        local repacd_RE_MoveFarther_Trigger_1
        local repacd_RE_MoveFarther_Brightness_1
        local repacd_RE_MoveFarther_Name_2
        local repacd_RE_MoveFarther_Trigger_2
        local repacd_RE_MoveFarther_Brightness_2

        repacd_RE_MoveFarther=$(config get repacd_RE_MoveFarther)
        if [ -n "$repacd_RE_MoveFarther" ]; then
            uci set repacd.RE_MoveFarther=$repacd_RE_MoveFarther
        fi

        repacd_RE_MoveFarther_Name_1=$(config get repacd_RE_MoveFarther_Name_1)
        if [ -n "$repacd_RE_MoveFarther_Name_1" ]; then
            uci set repacd.RE_MoveFarther.Name_1=$repacd_RE_MoveFarther_Name_1
        fi

        repacd_RE_MoveFarther_Trigger_1=$(config get repacd_RE_MoveFarther_Trigger_1)
        if [ -n "$repacd_RE_MoveFarther_Trigger_1" ]; then
            uci set repacd.RE_MoveFarther.Trigger_1=$repacd_RE_MoveFarther_Trigger_1
        fi

        repacd_RE_MoveFarther_Brightness_1=$(config get repacd_RE_MoveFarther_Brightness_1)
        if [ -n "$repacd_RE_MoveFarther_Brightness_1" ]; then
            uci set repacd.RE_MoveFarther.Brightness_1=$repacd_RE_MoveFarther_Brightness_1
        fi

        repacd_RE_MoveFarther_Name_2=$(config get repacd_RE_MoveFarther_Name_2)
        if [ -n "$repacd_RE_MoveFarther_Name_2" ]; then
            uci set repacd.RE_MoveFarther.Name_2=$repacd_RE_MoveFarther_Name_2
        fi

        repacd_RE_MoveFarther_Trigger_2=$(config get repacd_RE_MoveFarther_Trigger_2)
        if [ -n "$repacd_RE_MoveFarther_Trigger_2" ]; then
            uci set repacd.RE_MoveFarther.Trigger_2=$repacd_RE_MoveFarther_Trigger_2
        fi

        repacd_RE_MoveFarther_Brightness_2=$(config get repacd_RE_MoveFarther_Brightness_2)
        if [ -n "$repacd_RE_MoveFarther_Brightness_2" ]; then
            uci set repacd.RE_MoveFarther.Brightness_2=$repacd_RE_MoveFarther_Brightness_2
        fi

        # repacd.RE_LocationSuitable
        local repacd_RE_LocationSuitable
        local repacd_RE_LocationSuitable_Name_1
        local repacd_RE_LocationSuitable_Trigger_1
        local repacd_RE_LocationSuitable_Brightness_1
        local repacd_RE_LocationSuitable_Name_2
        local repacd_RE_LocationSuitable_Trigger_2
        local repacd_RE_LocationSuitable_Brightness_2

        repacd_RE_LocationSuitable=$(config get repacd_RE_LocationSuitable)
        if [ -n "$repacd_RE_LocationSuitable" ]; then
            uci set repacd.RE_LocationSuitable=$repacd_RE_LocationSuitable
        fi

        repacd_RE_LocationSuitable_Name_1=$(config get repacd_RE_LocationSuitable_Name_1)
        if [ -n "$repacd_RE_LocationSuitable_Name_1" ]; then
            uci set repacd.RE_LocationSuitable.Name_1=$repacd_RE_LocationSuitable_Name_1
        fi

        repacd_RE_LocationSuitable_Trigger_1=$(config get repacd_RE_LocationSuitable_Trigger_1)
        if [ -n "$repacd_RE_LocationSuitable_Trigger_1" ]; then
            uci set repacd.RE_LocationSuitable.Trigger_1=$repacd_RE_LocationSuitable_Trigger_1
        fi

        repacd_RE_LocationSuitable_Brightness_1=$(config get repacd_RE_LocationSuitable_Brightness_1)
        if [ -n "$repacd_RE_LocationSuitable_Brightness_1" ]; then
            uci set repacd.RE_LocationSuitable.Brightness_1=$repacd_RE_LocationSuitable_Brightness_1
        fi

        repacd_RE_LocationSuitable_Name_2=$(config get repacd_RE_LocationSuitable_Name_2)
        if [ -n "$repacd_RE_LocationSuitable_Name_2" ]; then
            uci set repacd.RE_LocationSuitable.Name_2=$repacd_RE_LocationSuitable_Name_2
        fi

        repacd_RE_LocationSuitable_Trigger_2=$(config get repacd_RE_LocationSuitable_Trigger_2)
        if [ -n "$repacd_RE_LocationSuitable_Trigger_2" ]; then
            uci set repacd.RE_LocationSuitable.Trigger_2=$repacd_RE_LocationSuitable_Trigger_2
        fi

        repacd_RE_LocationSuitable_Brightness_2=$(config get repacd_RE_LocationSuitable_Brightness_2)
        if [ -n "$repacd_RE_LocationSuitable_Brightness_2" ]; then
            uci set repacd.RE_LocationSuitable.Brightness_2=$repacd_RE_LocationSuitable_Brightness_2
        fi

        # repacd.InCAPMode
        local repacd_InCAPMode
        local repacd_InCAPMode_Name_1
        local repacd_InCAPMode_Trigger_1
        local repacd_InCAPMode_Brightness_1
        local repacd_InCAPMode_DelayOn_1
        local repacd_InCAPMode_DelayOff_1
        local repacd_InCAPMode_Name_2
        local repacd_InCAPMode_Trigger_2
        local repacd_InCAPMode_Brightness_2

        repacd_InCAPMode=$(config get repacd_InCAPMode)
        if [ -n "$repacd_InCAPMode" ]; then
            uci set repacd.InCAPMode=$repacd_InCAPMode
        fi

        repacd_InCAPMode_Name_1=$(config get repacd_InCAPMode_Name_1)
        if [ -n "$repacd_InCAPMode_Name_1" ]; then
            uci set repacd.InCAPMode.Name_1=$repacd_InCAPMode_Name_1
        fi

        repacd_InCAPMode_Trigger_1=$(config get repacd_InCAPMode_Trigger_1)
        if [ -n "$repacd_InCAPMode_Trigger_1" ]; then
            uci set repacd.InCAPMode.Trigger_1=$repacd_InCAPMode_Trigger_1
        fi

        repacd_InCAPMode_Brightness_1=$(config get repacd_InCAPMode_Brightness_1)
        if [ -n "$repacd_InCAPMode_Brightness_1" ]; then
            uci set repacd.InCAPMode.Brightness_1=$repacd_InCAPMode_Brightness_1
        fi

        repacd_InCAPMode_DelayOn_1=$(config get repacd_InCAPMode_DelayOn_1)
        if [ -n "$repacd_InCAPMode_DelayOn_1" ]; then
            uci set repacd.InCAPMode.DelayOn_1=$repacd_InCAPMode_DelayOn_1
        fi

        repacd_InCAPMode_DelayOff_1=$(config get repacd_InCAPMode_DelayOff_1)
        if [ -n "$repacd_InCAPMode_DelayOff_1" ]; then
            uci set repacd.InCAPMode.DelayOff_1=$repacd_InCAPMode_DelayOff_1
        fi

        repacd_InCAPMode_Name_2=$(config get repacd_InCAPMode_Name_2)
        if [ -n "$repacd_InCAPMode_Name_2" ]; then
            uci set repacd.InCAPMode.Name_2=$repacd_InCAPMode_Name_2
        fi

        repacd_InCAPMode_Trigger_2=$(config get repacd_InCAPMode_Trigger_2)
        if [ -n "$repacd_InCAPMode_Trigger_2" ]; then
            uci set repacd.InCAPMode.Trigger_2=$repacd_InCAPMode_Trigger_2
        fi

        repacd_InCAPMode_Brightness_2=$(config get repacd_InCAPMode_Brightness_2)
        if [ -n "$repacd_InCAPMode_Brightness_2" ]; then
            uci set repacd.InCAPMode.Brightness_2=$repacd_InCAPMode_Brightness_2
        fi

        # repacd.CL_LinkSufficient
        local repacd_CL_LinkSufficient
        local repacd_CL_LinkSufficient_Name_1
        local repacd_CL_LinkSufficient_Trigger_1
        local repacd_CL_LinkSufficient_Brightness_1
        local repacd_CL_LinkSufficient_Name_2
        local repacd_CL_LinkSufficient_Trigger_2
        local repacd_CL_LinkSufficient_Brightness_2

        repacd_CL_LinkSufficient=$(config get repacd_CL_LinkSufficient)
        if [ -n "$repacd_CL_LinkSufficient" ]; then
            uci set repacd.CL_LinkSufficient=$repacd_CL_LinkSufficient
        fi

        repacd_CL_LinkSufficient_Name_1=$(config get repacd_CL_LinkSufficient_Name_1)
        if [ -n "$repacd_CL_LinkSufficient_Name_1" ]; then
            uci set repacd.CL_LinkSufficient.Name_1=$repacd_CL_LinkSufficient_Name_1
        fi

        repacd_CL_LinkSufficient_Trigger_1=$(config get repacd_CL_LinkSufficient_Trigger_1)
        if [ -n "$repacd_CL_LinkSufficient_Trigger_1" ]; then
            uci set repacd.CL_LinkSufficient.Trigger_1=$repacd_CL_LinkSufficient_Trigger_1
        fi

        repacd_CL_LinkSufficient_Brightness_1=$(config get repacd_CL_LinkSufficient_Brightness_1)
        if [ -n "$repacd_CL_LinkSufficient_Brightness_1" ]; then
            uci set repacd.CL_LinkSufficient.Brightness_1=$repacd_CL_LinkSufficient_Brightness_1
        fi

        repacd_CL_LinkSufficient_Name_2=$(config get repacd_CL_LinkSufficient_Name_2)
        if [ -n "$repacd_CL_LinkSufficient_Name_2" ]; then
            uci set repacd.CL_LinkSufficient.Name_2=$repacd_CL_LinkSufficient_Name_2
        fi

        repacd_CL_LinkSufficient_Trigger_2=$(config get repacd_CL_LinkSufficient_Trigger_2)
        if [ -n "$repacd_CL_LinkSufficient_Trigger_2" ]; then
            uci set repacd.CL_LinkSufficient.Trigger_2=$repacd_CL_LinkSufficient_Trigger_2
        fi

        repacd_CL_LinkSufficient_Brightness_2=$(config get repacd_CL_LinkSufficient_Brightness_2)
        if [ -n "$repacd_CL_LinkSufficient_Brightness_2" ]; then
            uci set repacd.CL_LinkSufficient.Brightness_2=$repacd_CL_LinkSufficient_Brightness_2
        fi

        local repacd_CL_LinkSufficient_Brightness_2

        repacd_CL_LinkSufficient=$(config get repacd_CL_LinkSufficient)
        if [ -n "$repacd_CL_LinkSufficient" ]; then
            uci set repacd.CL_LinkSufficient=$repacd_CL_LinkSufficient
        fi

        repacd_CL_LinkSufficient_Name_1=$(config get repacd_CL_LinkSufficient_Name_1)
        if [ -n "$repacd_CL_LinkSufficient_Name_1" ]; then
            uci set repacd.CL_LinkSufficient.Name_1=$repacd_CL_LinkSufficient_Name_1
        fi

        repacd_CL_LinkSufficient_Trigger_1=$(config get repacd_CL_LinkSufficient_Trigger_1)
        if [ -n "$repacd_CL_LinkSufficient_Trigger_1" ]; then
            uci set repacd.CL_LinkSufficient.Trigger_1=$repacd_CL_LinkSufficient_Trigger_1
        fi

        repacd_CL_LinkSufficient_Brightness_1=$(config get repacd_CL_LinkSufficient_Brightness_1)
        if [ -n "$repacd_CL_LinkSufficient_Brightness_1" ]; then
            uci set repacd.CL_LinkSufficient.Brightness_1=$repacd_CL_LinkSufficient_Brightness_1
        fi

        repacd_CL_LinkSufficient_Name_2=$(config get repacd_CL_LinkSufficient_Name_2)
        if [ -n "$repacd_CL_LinkSufficient_Name_2" ]; then
            uci set repacd.CL_LinkSufficient.Name_2=$repacd_CL_LinkSufficient_Name_2
        fi

        repacd_CL_LinkSufficient_Trigger_2=$(config get repacd_CL_LinkSufficient_Trigger_2)
        if [ -n "$repacd_CL_LinkSufficient_Trigger_2" ]; then
            uci set repacd.CL_LinkSufficient.Trigger_2=$repacd_CL_LinkSufficient_Trigger_2
        fi

        repacd_CL_LinkSufficient_Brightness_2=$(config get repacd_CL_LinkSufficient_Brightness_2)
        if [ -n "$repacd_CL_LinkSufficient_Brightness_2" ]; then
            uci set repacd.CL_LinkSufficient.Brightness_2=$repacd_CL_LinkSufficient_Brightness_2
        fi

        # repacd.CL_LinkInadequat
        local repacd_CL_LinkInadequat
        local repacd_CL_LinkInadequat_Name_1
        local repacd_CL_LinkInadequat_Trigger_1
        local repacd_CL_LinkInadequat_Brightness_1
        local repacd_CL_LinkInadequat_Name_2
        local repacd_CL_LinkInadequat_Trigger_2
        local repacd_CL_LinkInadequat_Brightness_2

        repacd_CL_LinkInadequat=$(config get repacd_CL_LinkInadequat)
        if [ -n "$repacd_CL_LinkInadequat" ]; then
            uci set repacd.CL_LinkInadequat=$repacd_CL_LinkInadequat
        fi

        repacd_CL_LinkInadequat_Name_1=$(config get repacd_CL_LinkInadequat_Name_1)
        if [ -n "$repacd_CL_LinkInadequat_Name_1" ]; then
            uci set repacd.CL_LinkInadequat.Name_1=$repacd_CL_LinkInadequat_Name_1
        fi

        repacd_CL_LinkInadequat_Trigger_1=$(config get repacd_CL_LinkInadequat_Trigger_1)
        if [ -n "$repacd_CL_LinkInadequat_Trigger_1" ]; then
            uci set repacd.CL_LinkInadequat.Trigger_1=$repacd_CL_LinkInadequat_Trigger_1
        fi

        repacd_CL_LinkInadequat_Brightness_1=$(config get repacd_CL_LinkInadequat_Brightness_1)
        if [ -n "$repacd_CL_LinkInadequat_Brightness_1" ]; then
            uci set repacd.CL_LinkInadequat.Brightness_1=$repacd_CL_LinkInadequat_Brightness_1
        fi

        repacd_CL_LinkInadequat_Name_2=$(config get repacd_CL_LinkInadequat_Name_2)
        if [ -n "$repacd_CL_LinkInadequat_Name_2" ]; then
            uci set repacd.CL_LinkInadequat.Name_2=$repacd_CL_LinkInadequat_Name_2
        fi

        repacd_CL_LinkInadequat_Trigger_2=$(config get repacd_CL_LinkInadequat_Trigger_2)
        if [ -n "$repacd_CL_LinkInadequat_Trigger_2" ]; then
            uci set repacd.CL_LinkInadequat.Trigger_2=$repacd_CL_LinkInadequat_Trigger_2
        fi

        repacd_CL_LinkInadequat_Brightness_2=$(config get repacd_CL_LinkInadequat_Brightness_2)
        if [ -n "$repacd_CL_LinkInadequat_Brightness_2" ]; then
            uci set repacd.CL_LinkInadequat.Brightness_2=$repacd_CL_LinkInadequat_Brightness_2
        fi

        # repacd.CL_ActingAsRE
        local repacd_CL_ActingAsRE
        local repacd_CL_ActingAsRE_Name_1
        local repacd_CL_ActingAsRE_Trigger_1
        local repacd_CL_ActingAsRE_Brightness_1
        local repacd_CL_ActingAsRE_Name_2
        local repacd_CL_ActingAsRE_Trigger_2
        local repacd_CL_ActingAsRE_Brightness_2

        repacd_CL_ActingAsRE=$(config get repacd_CL_ActingAsRE)
        if [ -n "$repacd_CL_ActingAsRE" ]; then
            uci set repacd.CL_ActingAsRE=$repacd_CL_ActingAsRE
        fi

        repacd_CL_ActingAsRE_Name_1=$(config get repacd_CL_ActingAsRE_Name_1)
        if [ -n "$repacd_CL_ActingAsRE_Name_1" ]; then
            uci set repacd.CL_ActingAsRE.Name_1=$repacd_CL_ActingAsRE_Name_1
        fi

        repacd_CL_ActingAsRE_Trigger_1=$(config get repacd_CL_ActingAsRE_Trigger_1)
        if [ -n "$repacd_CL_ActingAsRE_Trigger_1" ]; then
            uci set repacd.CL_ActingAsRE.Trigger_1=$repacd_CL_ActingAsRE_Trigger_1
        fi

        repacd_CL_ActingAsRE_Brightness_1=$(config get repacd_CL_ActingAsRE_Brightness_1)
        if [ -n "$repacd_CL_ActingAsRE_Brightness_1" ]; then
            uci set repacd.CL_ActingAsRE.Brightness_1=$repacd_CL_ActingAsRE_Brightness_1
        fi

        repacd_CL_ActingAsRE_Name_2=$(config get repacd_CL_ActingAsRE_Name_2)
        if [ -n "$repacd_CL_ActingAsRE_Name_2" ]; then
            uci set repacd.CL_ActingAsRE.Name_2=$repacd_CL_ActingAsRE_Name_2
        fi

        repacd_CL_ActingAsRE_Trigger_2=$(config get repacd_CL_ActingAsRE_Trigger_2)
        if [ -n "$repacd_CL_ActingAsRE_Trigger_2" ]; then
            uci set repacd.CL_ActingAsRE.Trigger_2=$repacd_CL_ActingAsRE_Trigger_2
        fi

        repacd_CL_ActingAsRE_Brightness_2=$(config get repacd_CL_ActingAsRE_Brightness_2)
        if [ -n "$repacd_CL_ActingAsRE_Brightness_2" ]; then
            uci set repacd.CL_ActingAsRE.Brightness_2=$repacd_CL_ActingAsRE_Brightness_2
        fi

        local rssi_prefer_2g_bh
        rssi_prefer_2g_bh=$(config get rssi_prefer_2g_bh)

        if [ "$rssi_prefer_2g_bh" -gt -95 -a  "$rssi_prefer_2g_bh" -lt 0 ]; then
            uci set repacd.WiFiLink.RSSIThresholdPrefer2GBackhaul=$rssi_prefer_2g_bh
        elif [ -z "$rssi_prefer_2g_bh" ]; then
            rssi_prefer_2g_bh=$(uci get repacd.WiFiLink.RSSIThresholdPrefer2GBackhaul)
            config set rssi_prefer_2g_bh=$rssi_prefer_2g_bh
            config commit
        fi

        local rssi_move_far5g
        rssi_move_far5g=$(config get rssi_move_far5g)

        if [ "$rssi_move_far5g" -gt -95 -a  "$rssi_move_far5g" -lt 0 ]; then
            uci set repacd.WiFiLink.RSSIThresholdFar5g=$rssi_move_far5g
        elif [ -z "$rssi_move_far5g" ]; then
            rssi_move_far5g=$(uci get repacd.WiFiLink.RSSIThresholdFar5g)
            config set rssi_move_far5g=$rssi_move_far5g
            config commit
        fi

        local rssi_move_far2g
        rssi_move_far2g=$(config get rssi_move_far2g)

        if [ "$rssi_move_far2g" -gt -95 -a  "$rssi_move_far2g" -lt 0 ]; then
            uci set repacd.WiFiLink.RSSIThresholdFar24g=$rssi_move_far2g
        elif [ -z "$rssi_move_far2g" ]; then
            rssi_move_far2g=$(uci get repacd.WiFiLink.RSSIThresholdFar24g)
            config set rssi_move_far2g=$rssi_move_far2g
            config commit
        fi

        local RateThresholdMax5GInPercent
        RateThresholdMax5GInPercent=$(config get RateThresholdMax5GInPercent)

        if [ "$RateThresholdMax5GInPercent" -gt 0 -a  "$RateThresholdMax5GInPercent" -lt 100 ]; then
            uci set repacd.WiFiLink.RateThresholdMax5GInPercent=$RateThresholdMax5GInPercent
        elif [ -z "$RateThresholdMax5GInPercent" ]; then
            RateThresholdMax5GInPercent=$(uci get repacd.WiFiLink.RateThresholdMax5GInPercent)
            config set RateThresholdMax5GInPercent=$RateThresholdMax5GInPercent
            config commit
        fi

        local RateThresholdMin5GInPercent
        RateThresholdMin5GInPercent=$(config get RateThresholdMin5GInPercent)

        if [ "$RateThresholdMin5GInPercent" -gt 0 -a  "$RateThresholdMin5GInPercent" -lt 100 ]; then
            uci set repacd.WiFiLink.RateThresholdMin5GInPercent=$RateThresholdMin5GInPercent
        elif [ -z "$RateThresholdMin5GInPercent" ]; then
            RateThresholdMin5GInPercent=$(uci get repacd.WiFiLink.RateThresholdMin5GInPercent)
            config set RateThresholdMin5GInPercent=$RateThresholdMin5GInPercent
            config commit
        fi

        local RateThresholdPrefer2GBackhaulInPercent
        RateThresholdPrefer2GBackhaulInPercent=$(config get RateThresholdPrefer2GBackhaulInPercent)

        if [ "$RateThresholdPrefer2GBackhaulInPercent" -gt 0 -a  "$RateThresholdPrefer2GBackhaulInPercent" -lt 100 ]; then
            uci set repacd.WiFiLink.RateThresholdPrefer2GBackhaulInPercent=$RateThresholdPrefer2GBackhaulInPercent
        elif [ -z "$RateThresholdPrefer2GBackhaulInPercent" ]; then
            RateThresholdPrefer2GBackhaulInPercent=$(uci get repacd.WiFiLink.RateThresholdPrefer2GBackhaulInPercent)
            config set RateThresholdPrefer2GBackhaulInPercent=$RateThresholdPrefer2GBackhaulInPercent
            config commit
        fi

        local repacd_5GBackhaulEvalTimeShort
        repacd_5GBackhaulEvalTimeShort=$(config get 5GBackhaulEvalTimeShort)

        if [ "$repacd_5GBackhaulEvalTimeShort" -gt 0 ]; then
            uci set repacd.WiFiLink.5GBackhaulEvalTimeShort=$repacd_5GBackhaulEvalTimeShort
        elif [ -z "$repacd_5GBackhaulEvalTimeShort" ]; then
            repacd_5GBackhaulEvalTimeShort=$(uci get repacd.WiFiLink.5GBackhaulEvalTimeShort)
            config set 5GBackhaulEvalTimeShort=$repacd_5GBackhaulEvalTimeShort
            config commit
        fi

        local repacd_5GBackhaulEvalTimeLong
        repacd_5GBackhaulEvalTimeLong=$(config get 5GBackhaulEvalTimeLong)

        if [ "$repacd_5GBackhaulEvalTimeLong" -gt 0 ]; then
            uci set repacd.WiFiLink.5GBackhaulEvalTimeLong=$repacd_5GBackhaulEvalTimeLong
        elif [ -z "$repacd_5GBackhaulEvalTimeLong" ]; then
            repacd_5GBackhaulEvalTimeLong=$(uci get repacd.WiFiLink.5GBackhaulEvalTimeLong)
            config set 5GBackhaulEvalTimeLong=$repacd_5GBackhaulEvalTimeLong
            config commit
        fi

        local ManageVAPInd
        ManageVAPInd=$(config get ManageVAPInd)

        if [ -n "$ManageVAPInd" ]; then
            uci set repacd.WiFiLink.ManageVAPInd=$ManageVAPInd
        elif [ -z "$ManageVAPInd" ]; then
            ManageVAPInd=$(uci get repacd.WiFiLink.ManageVAPInd)
            config set ManageVAPInd=$ManageVAPInd
            config commit
        fi

        local EnableEthernetMonitoring
        EnableEthernetMonitoring=$(config get EthernetBackhaul)
        case $EnableEthernetMonitoring in
        1)
            uci set repacd.repacd.EnableEthernetMonitoring=1
            config commit
        ;;
        *)
            uci set repacd.repacd.EnableEthernetMonitoring=0
            config commit
        ;;
        esac

        local wla_backhaul_channel
        if [ "$orbi_project" = "Orbimini" ]; then
            wla_backhaul_channel=$(config get wla_hidden_channel)
        else
            wla_backhaul_channel=$(config get wla_2nd_hidden_channel)
        fi

        repacd_BSSIDAssociationTimeout=$(config get repacd_BSSIDAssociationTimeout)
        if [ -n "$repacd_BSSIDAssociationTimeout" ]; then
            uci set repacd.WiFiLink.BSSIDAssociationTimeout=$repacd_BSSIDAssociationTimeout
        fi

        local MaxMeasuringStateAttempts
        MaxMeasuringStateAttempts=$(config get repacd_MaxMeasuringStateAttempts)

        if [ "$MaxMeasuringStateAttempts" -gt 0 ]; then
            uci set repacd.WiFiLink.MaxMeasuringStateAttempts=$MaxMeasuringStateAttempts
        elif [ -z "$MaxMeasuringStateAttempts" ]; then
            MaxMeasuringStateAttempts=$(uci get repacd.WiFiLink.MaxMeasuringStateAttempts)
            config set repacd_MaxMeasuringStateAttempts=$MaxMeasuringStateAttempts
            config commit
        fi

        local Daisy_Chain_Enable
        Daisy_Chain_Enable=$(config get repacd_Daisy_Chain_Enable)

        if [ -n "$Daisy_Chain_Enable" ]; then
            uci set repacd.WiFiLink.DaisyChain=$Daisy_Chain_Enable
        else
            Daisy_Chain_Enable=$(uci get repacd.WiFiLink.DaisyChain)
            config set repacd_Daisy_Chain_Enable=$Daisy_Chain_Enable
            config commit
        fi

        local RateScalingFactor
        RateScalingFactor=$(config get repacd_RateScalingFactor)

        if [ "$RateScalingFactor" -gt 0 ]; then
            uci set repacd.WiFiLink.RateScalingFactor=$RateScalingFactor
        elif [ -z "$RateScalingFactor" ]; then
            RateScalingFactor=$(uci get repacd.WiFiLink.RateScalingFactor)
            config set repacd_RateScalingFactor=$RateScalingFactor
            config commit
        fi

        if [ "x`/bin/config get enable_arlo_function`" = "x1" ];then
            ifname=`awk -v input_optype=ARLO -v output_rule=ifname -f /etc/search-wifi-interfaces.awk $wifi_topology_file`
            if [ -n "$ifname" ]; then
                uci set repacd.repacd.DNI_TrafficSeparationEnabled=1
                uci set repacd.repacd.DNI_TrafficSeparationActive=1
                uci set repacd.repacd.NetworkBackhaul=backhaul
                network_arlo=$(config get i_wlg_arlo_br)
                uci set repacd.repacd.NetworkGuest=${network_arlo#"br"}
                config commit
            fi
        fi
    fi
}


wsplcd_updateDNI_config() {
    #Orbi DNI setting
    if [ "$orbi_project" = "Desktop" -o "$orbi_project" = "Orbimini" -o "$orbi_project" = "Orbipro" -o "$orbi_project" = "OrbiOutdoor" ]; then
        local wsplcd_enable
        wsplcd_enable=$(config get wsplcd_enable)

        case $wsplcd_enable in
        1)
            uci set wsplcd.config.HyFiSecurity=1
        ;;
        0)
            uci set wsplcd.config.HyFiSecurity=0
        ;;
        "")
            wsplcd_enable=$(uci get wsplcd.config.HyFiSecurity)
            config set wsplcd_enable=$wsplcd_enable
            config commit
        ;;
        esac
    fi
}

wifison_updateconf() {
    case "$1" in
        all)
            lbd_updateDNI_config
            hyd_updateDNI_config
            repacd_updateDNI_config
            wsplcd_updateDNI_config

            uci commit lbd
            uci commit hyd
            uci commit repacd
            uci commit wsplcd
        ;;

        lbd)
            lbd_updateDNI_config

            uci commit lbd
        ;;

        hyd)
            hyd_updateDNI_config

            uci commit hyd
        ;;

        repacd)
            repacd_updateDNI_config

            uci commit repacd
        ;;

        wsplcd)
            wsplcd_updateDNI_config

            uci commit wsplcd
        ;;

    esac

}

wifison_restart() {

    case "$1" in
        all)
            /etc/init.d/lbd stop
            /etc/init.d/lbd start

            /etc/init.d/hyd stop
            /etc/init.d/hyd start

            /etc/init.d/repacd stop
            /etc/init.d/repacd start
        ;;

        lbd)
            /etc/init.d/lbd stop
            /etc/init.d/lbd start
        ;;

        hyd)
            /etc/init.d/hyd stop
            /etc/init.d/hyd start
        ;;

        repacd)
            /etc/init.d/repacd stop
            /etc/init.d/repacd start
        ;;

        wsplcd)
            /etc/init.d/wsplcd stop
            /etc/init.d/wsplcd start
        ;;

    esac

}

wifison_boot () {
    if [ "x$1" = "x" ]; then
        logd&
        lbd_updateDNI_config
        hyd_updateDNI_config
        repacd_updateDNI_config
        wsplcd_updateDNI_config

        uci commit lbd
        uci commit hyd
        uci commit repacd
        uci commit wsplcd
    elif [ "x$1" = "xlbd" ]; then
        logd&
        lbd_updateDNI_config

        uci commit lbd
    fi
}

show_usage() {
    cat <<EOF
Usage: wifison <command> [<arguments>]

Commands:
    updateconf         <arguments>
            all
            lbd
            repacd
            hyd
            wsplcd

    restart         <arguments>
            all
            lbd
            repacd
            hyd
            wsplcd

    boot
EOF
}

[ -e /tmp/orbi_type ] && orbi_type=`cat /tmp/orbi_type`

case "$1" in
        updateconf) wifison_updateconf "$2";;
        restart) wifison_restart "$2";;
        boot) wifison_boot "$2";;
        *) show_usage ;;
esac
