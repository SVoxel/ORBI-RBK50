#! /bin/sh

# command to write firmware image to flash

# ${1} is path of firmware partition device
# ${2} is path of firmware image file
# e.g.: do_imgwrite.sh /dev/mtd8 /tmp/XXX.img
nandwrite --input-skip=128 -p -m -q ${1} ${2}
