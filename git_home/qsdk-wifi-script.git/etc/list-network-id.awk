BEGIN {
    id_cnt=0
    id[id_cnt]=0
    ssid[id_cnt]=""
    flag[id_cnt]=""
    if ( list_type == "" )
        list_type="all"
}

$1 ~ /^[0-9]+$/ {
    id[id_cnt]=$1
    ssid[id_cnt]=$2
    flag[id_cnt]=$NF
    id_cnt++
}

END {
    if (id_cnt > 0) {
        list_cnt = 0
        if (list_type == "all")
            list_cnt = id_cnt
        else if (list_type == "old")
            list_cnt = id_cnt - 1

        if (list_cnt > 0)
            for (i = 0; i < list_cnt; i++){
                printf "%d ", id[i]
            }
    }
}
