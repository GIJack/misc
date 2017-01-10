#!/bin/bash
# This script
IP=$1
JAIL=$2
[ -z $2 ] && JAIL="owncloud"
fail2ban-client set $JAIL unbanip $IP
