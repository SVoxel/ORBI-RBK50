BEGIN {
    FS=":"
    rec_id=0
}

{
    # optype:opmode:wifidev:ifname:section:conf_prefix
    rec_optype[rec_id]=$1
    rec_opmode[rec_id]=$2
    rec_wifi_dev[rec_id]=$3
    rec_ifname[rec_id]=$4
    rec_section[rec_id]=$5
    rec_conf_prefix[rec_id]=$6
    # Assume every entry is matched first
    rec_matched[rec_id]=1
    rec_id++
}

END {
    # input_ifname
    matched_id = -1
    if (input_ifname != "" ) {
        for (i = 0; i < rec_id; i++){
            if (rec_ifname[i] == input_ifname){
                matched_id = i
                rec_matched[i] = 0
            }
        }
    } else if (input_section != "" ) {
        for (i = 0; i < rec_id; i++){
            if (rec_section[i] == input_section){
                matched_id = i
                rec_matched[i] = 0
            }
        }
    } else {
        if (input_optype != "")
            search_rule="optype+"
        if (input_opmode != "")
            search_rule=search_rule"opmode+"
        if (input_wifidev != "")
            search_rule=search_rule"wifidev+"
        for (i = 0; i < rec_id; i++){
            if (match(search_rule, "optype"))
                if (rec_optype[i] != input_optype)
                    continue
            if (match(search_rule, "opmode"))
                if (rec_opmode[i] != input_opmode)
                    continue
            if (match(search_rule, "wifidev"))
                if (rec_wifi_dev[i] != input_wifidev)
                    continue
            matched_id = i
        }
    }
    if (matched_id == -1)
        exit

    # search_rule: optype_opmode, optype, opmode
    # Filter out not matched entry
    if (match(search_rule, "optype")) {
        for (i = 0; i < rec_id; i++){
            if (rec_optype[i] != rec_optype[matched_id]){
                rec_matched[i] = 0
            }
        }
    }
    if (match(search_rule, "opmode")) {
        for (i = 0; i < rec_id; i++){
            if (rec_opmode[i] != rec_opmode[matched_id] && rec_matched[i] == 1){
                rec_matched[i] = 0
            }
        }
    }
    if (match(search_rule, "wifidev")) {
        for (i = 0; i < rec_id; i++){
            if (rec_wifi_dev[i] != rec_wifi_dev[matched_id] && rec_matched[i] == 1){
                rec_matched[i] = 0
            }
        }
    }

    # Output result by rule
    # output_rule: ifname, prefix, opmode, optype

    if (output_rule == "opmode"){
        printf "%s", rec_opmode[matched_id]
    } else if (output_rule == "optype"){
        printf "%s", rec_optype[matched_id]
    } else if (output_rule == "prefix"){
        printf "%s", rec_conf_prefix[matched_id]
    } else if (output_rule == "section"){
        printf "%s", rec_section[matched_id]
    } else {
        for (i = 0; i < rec_id; i++){
            if (rec_matched[i]){
                if (output_rule == "ifname") {
                    printf "%s ", rec_ifname[i]
                }
            }
        }
    }
}
