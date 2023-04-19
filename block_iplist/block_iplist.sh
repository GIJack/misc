#!/usr/bin/env bash

### CONFIG
# One IP per line, no comments
BLOCK_LIST_FILE=/etc/iptables/block_ips.txt
BLOCK_CHAIN=DROP #If you are running something like ninja-ids, you can use LOG_DENY
### /CONFIG

help_and_exit(){
  cat 1>&2 << EOF
block_iplist.sh:
Reads IP addresses from a text file, and blocks them with iptables. One IP
address per line, no comments or other information allowed.

    USAGE:
    ./block_iplist.sh [start|stop|reload]

EOF
  exit 4
}
message(){
  echo "iptables_block_iplist.sh: ${@}"
}
submsg(){
  echo "	${@}"
}
exit_with_error(){
  echo 1>&2 "iptables_block_iplist.sh: ERROR: ${2}"
  exit ${1}
}
warn(){
  echo 1>&2 "iptables_block_iplist.sh: ${@}"
}
iptables_block(){
  # Use iptables to block and IP address
  local block_ip="${1}"
  iptables -I INPUT -s "${block_ip}" -j "${BLOCK_CHAIN}" || return 1
  iptables -I OUTPUT -s "${block_ip}" -j "${BLOCK_CHAIN}" || return 1
  iptables -I FORWARD -s "${block_ip}" -j "${BLOCK_CHAIN}" || return 1

}
iptables_clear(){
  # Remove an IP Address Block
  local block_ip="${1}"
  iptables -D INPUT -s "${block_ip}" -j "${BLOCK_CHAIN}" || return 1
  iptables -D OUTPUT -s "${block_ip}" -j "${BLOCK_CHAIN}" || return 1
  iptables -D FORWARD -s "${block_ip}" -j "${BLOCK_CHAIN}" || return 1
}

_start(){
  local -i errors=0
  for item in ${BLOCK_LIST};do
    iptables_block "${item}" || errors+=1
  done
  return ${errors}
}

_stop(){
  for item in ${BLOCK_LIST};do
    iptables_clear "${item}" || errors+=1
  done
  return ${errors}
}

_reload(){
  local -i errors=0
  _stop || errors+=${errors}
  _start || errors+=${errors}
  return ${errors}
}

main() {
   local -i errors=0
   local command="${1}"
   message "Bulk IP Address Block Tool. Loading ips from: ${BLOCK_LIST_FILE}"
   BLOCK_LIST="$(cat ${BLOCK_LIST_FILE})" || exit_with_error 1 "Could not read Block List File ${BLOCK_LIST_FILE}. Ensure this file exists and is readable, and try again"

   [ -z "${BLOCK_LIST}" ] && exit_with_error 2 "Blocklist is empty. check contents: ${BLOCK_LIST_FILE}"
   [ -z "${command}" ] && help_and_exit
   
   case "${command}" in
     start)
       submsg "Blocking IPs"
       _start || errors+=${?}
       ;;
     stop)
       submsg "Removing IP Blocks"
       _stop || errors+=${?}
       ;;
     reload)
       submsg "Reloading IP Block rules"
       _reload || errors+=${?}
       ;;
    *)
      help_and_exit
       ;;
   esac
   
   case ${errors} in
     0)
       message "Done"
       exit 0
       ;;
     1)
       message "Done but with 1 error"
       exit 1
       ;;
     *)
       message "Done, but with ${errors} errors"
       exit 1
       ;;
   esac
}

main "${@}"
