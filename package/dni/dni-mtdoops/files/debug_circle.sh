#!/bin/sh
mkdir /tmp/debug_circle
cp -rf /mnt/circle/shares/usr/bin/tracking /tmp/debug_circle/
cp /tmp/circled.log /tmp/debug_circle/
iptables -t nat -nvL > /tmp/debug_circle/iptables
iptables -t filter -nvL >> /tmp/debug_circle/iptables
iptables -t mangle -nvL >> /tmp/debug_circle/iptables
iptables -nvL >> /tmp/debug_circle/iptables
cp /mnt/circle/shares/VERSION /tmp/debug_circle/
cp /mnt/circle/shares/BUILT /tmp/debug_circle/
ps -www |grep circle > /tmp/debug_circle/circle_process
/usr/bin/circled -v > /tmp/debug_circle/circled_version
ipset --list > /tmp/debug_circle/ipset
cd /tmp
zip -r debug_circle.zip debug_circle
