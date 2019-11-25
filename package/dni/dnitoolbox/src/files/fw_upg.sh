#! /bin/sh

if [ $# -ne 1 ] || [ ! -f $1 ]; then
	printf "Usage:	${0##*/} <firmware_file>\n" >&2
	exit 1
fi

boot_part=$(artmtd -r boot_part | grep -o [12])

if [ "$boot_part" = "2" ]; then
	fw_dev=$(part_dev firmware)
	new_boot_part=1
else
	fw_dev=$(part_dev firmware2)
	new_boot_part=2
fi

# before firmware update, it will execute /sbin/run-ramfs, we should copy
# action scripts to /tmp to ensure it keep valid during upgrading.
cp -rf /usr/etc/firmware_update /tmp/

/usr/sbin/firmware_update \
	-d $fw_dev \
	-p $(cat /module_name) \
	-i $(cat /hw_id) \
	-0 /tmp/firmware_update/pre_action.sh \
	-1 /tmp/firmware_update/do_action.sh \
	-2 /tmp/firmware_update/post_action.sh \
	$1

ret=$?
if [ $ret -eq 0 ]; then
	artmtd -w boot_part $new_boot_part
fi

exit $ret
