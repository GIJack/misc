#!/usr/bin/env bash
# get a new Exit Node, and with it IP, from TOR

NODE_ADDRESS=127.0.0.1
NODE_PASSWORD=""

main() {
  while [ -z $NODE_PASSWORD ];do
   read -s -p "Enter TOR Password: " NODE_PASSWORD
   echo ""
  done
  printf "AUTHENTICATE \"${NODE_PASSWORD}\"\r\nSIGNAL NEWNYM\r\n" | nc ${NODE_ADDRESS} 9051
}

help_and_exit(){
  cat 1>&2 << EOF
tor_new_ip.sh:

Tell the TOR daemon to start using a new path, and with it, new Exit IP.

	OPTIONS:
	
	-p, --password	Specify the control password
	
	-h, --host	IP/Hostname of the TORnode

EOF
  exit 1
}

switch_checker() {
  while [ ! -z "$1" ];do
   case "$1" in
    --help|-\?)
     help_and_exit
     ;;
    --password|-p)
     NODE_PASSWORD="${2}"
     shift
     ;;
    --host|-h)
     NODE_ADDRESS="${2}"
     shift
     ;;
    *)
     PARMS+="${1}"
     ;;
   esac
   shift
  done
}

switch_checker "${@}"
main ${PARAMS}
