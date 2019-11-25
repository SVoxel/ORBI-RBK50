#!/bin/sh

OPENSSL=$(which openssl)
CRT_FILE=server.pem
CRT_CONF=./crtconfig.conf


$OPENSSL req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $CRT_FILE -out $CRT_FILE -config $CRT_CONF

