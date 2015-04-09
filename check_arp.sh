#!/bin/bash
# This script checks certian IPs for collisions passively by checking the arp cache
# USAGE" ./check_arp.sh <list of IPs to watch>
# Jack @ nyi.net, Licensed under the FreeBSD license https://www.freebsd.org/copyright/freebsd-license.html

############SETTINGS##################
#Output to logfile instead of stdout #
#also, run in the background         #
daemon="no"                          # 
logfile="${PWD}/passive_arp.log"     #
# Time in seconds to poll the arp    #
# cache                              #
check_interval=.333                  #
#load settings from an external file #
#. /path/to/settings/file            #
###########END-SETTINGS###############

address_list=(${@})
progname="${0}"
ERRORS=0
collisions=()
collisions_previous=()

function check_passive() {
    #reset this every cycle.
    collisions=()
    for address in ${address_list[@]};do
        #first make an array with all the MAC addresses on the arp table for a given IP.
        maclist=($(arp -na|grep ${address}|cut -d " " -f 4))
        ERRORS=$(($ERRORS+$?))
        # IP addresses should only have on MAC address.
        if [ ${#maclist[@]} -gt 1 ];then
            #add it to the array of current collisions
            collisions[${address}]="${maclist[@]}"
           #If this exact collision has happened already, don't report it again.
            if [ collisions_previous[${address}] != collisions[${address} ];
                echo "${progname}: COLLISION! on ${address} between ${maclist}"
                collisions_previous[${address}]="${maclist[@]}"
            fi
        fi
    done
}

function _stop() {
    echo "${progname}: shutting down"
    exit ${1}
}

function _start() {
    echo "${progname}: Starting up, checking ${address_list[@]} for IP collisions"
    while true;do
        check_passive
        sleep $check_interval
    done
}

function main() {
    if [ ${#} -lt "1" ];then
        echo "${progname}: You need at least one IP to check"
        _stop 1
    fi
    trap "_stop ${ERRORS}" SIGTERM SIGINT
    _start
}

if [ $daemon == "yes" ];then
    main >> $logfile &
else
    main
fi
