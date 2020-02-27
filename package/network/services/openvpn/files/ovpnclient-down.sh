#!/bin/sh

/sbin/led_ring stop
/sbin/ledcontrol -n all -c amber -s on -l strong
