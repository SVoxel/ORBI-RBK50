#!/bin/sh
BDPATH=/opt/bitdefender
BDNC_PATH=$BDPATH/etc/bdnc.ini
START=0

stop_services_if_running(){
pidof guster > /dev/null 2>&1
if [ $? -eq 0 ]; then
        $BDPATH/bin/bd stop > /dev/null 2>&1
        START=1
fi
}

start_if_needed(){
if [ $START -eq "1" ]; then
        $BDPATH/bin/bd start > /dev/null 2>&1
fi
}

get_server(){
grep -Fq "beta.nimbus.bitdefender.net" $BDNC_PATH > /dev/null 2>&1
if [ $? -eq 0  ]
        then
                echo "QA server"
        else
                grep -qF "nimbus.bitdefender.net" $BDNC_PATH > /dev/null 2>&1
                if [ $? -eq 0 ]
                        then
                                echo "Production server"
                        else
                                echo "Unknown server"
                        fi
        fi
}

set_server(){
if [ $1 = "production" ]; then
        stop_services_if_running
        sed -i 's/^BootstrapServer.*/BootstrapServer = nimbus.bitdefender.net/' $BDNC_PATH > /dev/null 2>&1
        echo "Changed config file to use production server"
        start_if_needed
elif [ $1 = "qa" ]; then
        stop_services_if_running
		cp -f /opt/bitdefender/etc/bdnc.ini /opt/bitdefender/lib/guster/bdnc/bdnc.ini
        sed -i 's/^BootstrapServer.*/BootstrapServer = beta.nimbus.bitdefender.net/' $BDNC_PATH > /dev/null 2>&1
        echo "Changed config file to use QA server"
        start_if_needed
else
        echo "Invalid command"
fi
}

if [ -z "$1" ]; then
        echo "Usage:"
        echo "  set_server <qa/production>      -> configures agent to use specified server"
        echo "  get_server                      -> returns the value of the server that is in use"
else
        if [ ! -f  $BDNC_PATH ]; then
                echo "Configuration file does not exist. Please check if path is configured correctly."
                exit 1
        fi
        if [ $1 = "get_server" ]; then
                get_server
        elif [ $1 = "set_server" ]; then
                if [ $2 = "qa" ]; then
                        set_server qa
                elif [ $2 = "production" ]; then
                        set_server production
                else
                        echo "Invalid command"
                fi
        else
                echo "Invalid command"
        fi
fi