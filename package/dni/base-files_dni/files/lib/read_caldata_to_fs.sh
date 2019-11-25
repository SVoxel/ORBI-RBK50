#!/bin/sh
#
# Copyright (c) 2015 The Linux Foundation. All rights reserved.
# Copyright (C) 2011 OpenWrt.org

. /lib/ipq806x.sh

do_load_ipq4019_board_bin()
{
    local board=$(ipq806x_board_name)
    local mtdblock=$(find_mtd_part 0:ART)

    local apdk="/tmp"

    if [ -z "$mtdblock" ]; then
        # read from mmc
        mtdblock=$(find_mmc_part 0:ART)
    fi

    [ -n "$mtdblock" ] || return

    flash_type=`cat /flash_type`
    # load board.bin
    case "$board" in
            ap-dk0*)
                    mkdir -p ${apdk}
		    if [ "x$flash_type" == "xEMMC" ];then
			    dd if=${mtdblock} of=${apdk}/wifi0.caldata bs=32 count=377 skip=128
			    dd if=${mtdblock} of=${apdk}/wifi1.caldata bs=32 count=377 skip=640
			    dd if=${mtdblock} of=${apdk}/wifi2.caldata bs=32 count=377 skip=1152
		    elif [ "x$flash_type" == "xNOR_FLASH" ];then
			    dd if=${mtdblock} of=${apdk}/wifi0.caldata bs=32 count=377 skip=128
			    dd if=${mtdblock} of=${apdk}/wifi1.caldata bs=32 count=377 skip=640
			    dd if=${mtdblock} of=${apdk}/wifi2.caldata bs=32 count=377 skip=1152
		    elif [ "x$flash_type" == "xNAND_FLASH" ];then
			    nanddump -l 53248 -f ${apdk}/WifiFullCaldata.bin $(echo $mtdblock | sed 's,block,,') 2>/dev/null
			    nanddump -s 4096 -l 12064 -f ${apdk}/wifi0.caldata $(echo $mtdblock | sed 's,block,,') 2>/dev/null
			    nanddump -s 20480 -l 12064 -f ${apdk}/wifi1.caldata $(echo $mtdblock | sed 's,block,,') 2>/dev/null
			    nanddump -s 36864 -l 12064 -f ${apdk}/wifi2.caldata $(echo $mtdblock | sed 's,block,,') 2>/dev/null
		    fi

            ;;
            ap16* | ap148*)
                    mkdir -p ${apdk}
                    dd if=${mtdblock} of=${apdk}/wifi0.caldata bs=32 count=377 skip=128
                    dd if=${mtdblock} of=${apdk}/wifi1.caldata bs=32 count=377 skip=640
                    dd if=${mtdblock} of=${apdk}/wifi2.caldata bs=32 count=377 skip=1152
            ;;
    esac
}

