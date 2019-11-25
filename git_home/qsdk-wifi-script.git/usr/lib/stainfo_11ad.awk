#! /usr/bin/awk -f

#
# Parse modified output of "iw <DEVICE> station dump".
#
# Information of each connected device is separated from others by empty line.
#

# Use empty line as record separator and newline as field separator
BEGIN {
    RS = ""
    FS = "\n"
}

{
    #
    # $1: String containing MAC address.
    #     Example: "Station 04:ce:14:0a:0c:43 (on wlan0)"
    #
    # $7: String containing Tx bitrate
    #     Example: "	tx bitrate:	27.5 MBit/s MCS 0"
    #

    sub(/^Station /, "", $1)
    sub(/ .*$/, "", $1)

    sub(/^\ttx bitrate:\t/, "", $7)
    sub(/ .*$/, "", $7)

    printf "%s\t%sMbps\t0\n", $1, $7
}
