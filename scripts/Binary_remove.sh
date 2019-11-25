#!/bin/bash
TOPDIR=$1
TARGET_ROOT=$2

BINARY_LIST=$TOPDIR/Binary_removal_list

if [ "x$1" != "x" -a "x$2" != "x" ]; then
	for BINARY in $(cat $BINARY_LIST)
	do
		if [ "x$BINARY" != "x" -a -e "$TARGET_ROOT/$BINARY" ]; then
			rm -rf "$TARGET_ROOT/$BINARY"
		fi
	done
fi


