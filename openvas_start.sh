#!/bin/bash
# Start OpenVAS stack, while making sure pre-reqs are started
# -Jack

message() {
  echo "${0}: ${@}"
}
exit_with_error() {
  message "ERROR: ${2}"
  exit ${1}
}

[ $UID -ne 0 ] && exit_with_error 2 "Not root, run this script as root!"

message "Starting OpenVAS..."
systemctl start redis || exit_with_error 1 "redis failed to start"
systemctl start openvas-scanner || exit_with_error 1 "scanner failed to start"
systemctl start openvas-manager || exit_with_error 1 "manager failed to start"
systemctl start gsad || exit_with_error 1 "GSA web UI failed to start"
