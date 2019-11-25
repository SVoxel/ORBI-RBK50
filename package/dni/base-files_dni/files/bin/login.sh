#!/bin/sh
# Copyright (C) 2006-2010 OpenWrt.org

cat << EOF
 === LOGIN ===============================
  Please enter your account and password,
  It's the same with DUT GUI
 ------------------------------------------
EOF
IFS= ;
echo -n "telnet account:"
read telnet_account
echo -n "telnet password:"
read telnet_passwd
if [ "$telnet_passwd" = "" ] ;then
read telnet_passwd
fi
telnet_passwd_hashed=$(/usr/sbin/hash-data -e "$telnet_passwd")
if [ -n "$telnet_passwd_hashed" ]; then
	telnet_passwd="$telnet_passwd_hashed"
fi
if [ "$telnet_account" = "$(/bin/config get http_username)" ] && [ "$telnet_passwd" = "$(/bin/config get http_passwd)" ] ;then
cat << EOF
=== IMPORTANT ============================
 Use 'passwd' to set your login password
 this will disable telnet and enable SSH
------------------------------------------
EOF
	exec /bin/ash --login
else
	echo "The account or password is not correct"
	exit 0
fi
