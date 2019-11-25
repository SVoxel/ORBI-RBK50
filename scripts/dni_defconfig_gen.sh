#!/usr/bin/env bash
# 
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

TOPDIR=$(pwd)

cp $TOPDIR/config/defconfig-orbi $TOPDIR/.config

[ -f $TOPDIR/dni_home/config/defconfig-orbi ] && cat $TOPDIR/dni_home/config/defconfig-orbi >> $TOPDIR/.config

make oldconfig

