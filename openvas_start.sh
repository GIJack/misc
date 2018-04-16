#!/bin/bash
# Start OpenVAS stack, while making sure pre-reqs are started
# -Jack

_SERVICES=(redis openvas-scanner openvas-manager gsad)

message() {
  echo "${0}: ${@}"
}
exit_with_error() {
  message "ERROR: ${2}"
  exit ${1}
}

main(){
  [ $UID -ne 0 ] && exit_with_error 2 "Not root, run this script as root!"
  message "Starting OpenVAS..."

  for item in ${_SERVICES[@]};do
    systemctl start $item} || exit_with_error 1 "${item} failed to start"
  done

  message "Done!"
}

main "${@}"
