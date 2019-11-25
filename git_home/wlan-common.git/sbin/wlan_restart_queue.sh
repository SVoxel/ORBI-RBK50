#!/bin/sh

fifofile=$1
[ -z "$fifofile" ] && {
    echo "No Fifo file provided...stop processing.."
    exit 0
}

first_sleep=20

echo "Wait $first_sleep seconds for collecting wlan restart commands" > /dev/console
sleep $first_sleep
local wlan_cmd="" prev_wlan_cmd=""
while true; do
    local pending=0
    while true; do
        read -t 1 wlan_cmd <>$fifofile
        if [ -z "$wlan_cmd" ]; then
            break
        else
            if [ "x$wlan_cmd" != "x$prev_wlan_cmd" ]; then
                prev_wlan_cmd=$wlan_cmd
                pending=$(( $pending + 1 ))
                echo "[ $wlan_cmd ]" > /dev/console
            else
                break
            fi
        fi
    done
    if [ $pending -eq 0 ]; then
        break;
    fi
    echo "$pending pending wlan restart command" > /dev/console
    wlan updateconf boot;
    wlan down;
    wlan up
done
rm -rf $fifofile

echo "wlan restart queue done" > /dev/console
