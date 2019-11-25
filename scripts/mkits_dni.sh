#!/bin/bash
#
# Licensed under the terms of the GNU GPL License version 2 or later.
#
# Author: Peter Tyser <ptyser@xes-inc.com>
#
# U-Boot firmware supports the booting of images in the Flattened Image
# Tree (FIT) format.  The FIT format uses a device tree structure to
# describe a kernel image, device tree blob, ramdisk, etc.  This script
# creates an Image Tree Source (.its file) which can be passed to the
# 'mkimage' utility to generate an Image Tree Blob (.itb file).  The .itb
# file can then be booted by U-Boot (or other bootloaders which support
# FIT images).  See doc/uImage.FIT/howto.txt in U-Boot source code for
# additional information on FIT images.
#

# Initializing global variables
DTB="";
FDT="";
CONFIG="";
iter=1;
DTB_COMP="none";
DTB_ADDR="";
LOAD_DTB_ADDR=""

usage() {
	echo "Usage: `basename $0` -A arch -C comp -a addr -e entry" \
		"-v version -k kernel [-D name -d dtb] -b dtb_addr" \
		"-B dtb_comp -o its_file"
	echo -e "\t-A ==> set architecture to 'arch'"
	echo -e "\t-C ==> set compression type 'comp'"
	echo -e "\t-a ==> set load address to 'addr' (hex)"
	echo -e "\t-e ==> set entry point to 'entry' (hex)"
	echo -e "\t-v ==> set kernel version to 'version'"
	echo -e "\t-k ==> include kernel image 'kernel'"
	echo -e "\t-D ==> human friendly Device Tree Blob 'name'"
	echo -e "\t-d ==> include Device Tree Blob 'dtb'"
	echo -e "\t-o ==> create output file 'its_file'"
	echo -e "\t-b ==> set dtb load address to 'dtb_addr' (hex)"
	echo -e "\t-B ==> set dtb compression type 'dtb_comp'"
	exit 1
}

# Generating FDT COnfiguration for all the dtb files
Generate_FDT () {
	FDT="$FDT
		fdt@$iter {
			description = \"${ARCH_UPPER} OpenWrt ${DEVICE} device tree blob\";
			data = /incbin/(\"${1}\");
			type = \"flat_dt\";
			arch = \"${ARCH}\";
			compression = \"${DTB_COMP}\";
			${LOAD_DTB_ADDR}
			hash@1 {
				algo = \"crc32\";
			};
			hash@2 {
				algo = \"sha1\";
			};
		};
"
}

Generate_Config () {
	CONFIG="$CONFIG
		config@$iter {
			description = \"OpenWrt\";
			kernel = \"kernel@1\";
			fdt = \"fdt@$iter\";
		};
"
}

while getopts ":A:a:C:D:d:e:k:o:v:b:B:" OPTION
do
	case $OPTION in
		A ) ARCH=$OPTARG;;
		a ) LOAD_ADDR=$OPTARG;;
		C ) COMPRESS=$OPTARG;;
		D ) DEVICE=$OPTARG;;
		d ) DTB="$DTB $OPTARG";;
		e ) ENTRY_ADDR=$OPTARG;;
		k ) KERNEL=$OPTARG;;
		o ) OUTPUT=$OPTARG;;
		v ) VERSION=$OPTARG;;
		b ) DTB_ADDR=$OPTARG;;
		B ) DTB_COMP=$OPTARG;;
		* ) echo "Invalid option passed to '$0' (options:$@)"
		usage;;
	esac
done

# Make sure user entered all required parameters
if [ -z "${ARCH}" ] || [ -z "${COMPRESS}" ] || [ -z "${LOAD_ADDR}" ] || \
	[ -z "${ENTRY_ADDR}" ] || [ -z "${VERSION}" ] || [ -z "${KERNEL}" ] || \
	[ -z "${OUTPUT}" ]; then
	usage
fi

ARCH_UPPER=`echo $ARCH | tr '[:lower:]' '[:upper:]'`
if [ -n "${DTB_ADDR}" ]; then
	LOAD_DTB_ADDR="load = <${DTB_ADDR}>;"
fi

# Conditionally create fdt information
if [ -n "${DTB}" ]; then
	for dtb in $DTB
	do
		Generate_FDT $dtb
		Generate_Config
		((iter++))
	done
else
	CONFIG="
		config@1 {
			description = \"OpenWrt\";
			kernel = \"kernel@1\";
			fdt = \"fdt@1\";
		};
"
fi

# Create a default, fully populated DTS file
DATA="/dts-v1/;

/ {
	description = \"${ARCH_UPPER} OpenWrt FIT (Flattened Image Tree)\";
	#address-cells = <1>;

	images {
		kernel@1 {
			description = \"${ARCH_UPPER} OpenWrt Linux-${VERSION}\";
			data = /incbin/(\"${KERNEL}\");
			type = \"kernel\";
			arch = \"${ARCH}\";
			os = \"linux\";
			compression = \"${COMPRESS}\";
			load = <${LOAD_ADDR}>;
			entry = <${ENTRY_ADDR}>;
			hash@1 {
				algo = \"crc32\";
			};
			hash@2 {
				algo = \"sha1\";
			};
		};
${FDT}
	};

	configurations {
		default = \"config@1\";
${CONFIG}
	};
};"

# Write .its file to disk
echo "$DATA" > ${OUTPUT}
