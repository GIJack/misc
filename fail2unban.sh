#!/bin/bash
# This script
IP=$1
JAIL=$2
[ -z $2 ] && JAIL="owncloud"

help_and_exit(){
  cat 1>&2 << EOF
fail2unban.sh:

Unban a host automaticly banned with fail2ban. Run as root. If no jailname
is specified, "owncloud" is assumed.

Usage:
	# fail2unban.sh <IP> [JAILNAME]
EOF
exit 1
}

[ -z $1 ] && help_and_exit
fail2ban-client set $JAIL unbanip $IP
