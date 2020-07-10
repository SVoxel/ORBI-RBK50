#!/bin/sh

config set checking_fw_trigger=1
config set soap_setting=GetDevInfo
config commit
echo "Check Firmware"
killall -SIGUSR1 soap_agent

