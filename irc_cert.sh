#!/usr/bin/env bash

help_and_exit(){
  cat 1>&2 << EOF
irc_cert.sh:
This script generates SSL Certificates for IRC, and can grab fingerprints from
existing certs.

The name of an existing key is the location of the .pem file without the .pem
extension. File MUST have a .pem extension

    USAGE:
    ./irc_cert.sh [gen|fingerprint|help] <key name>
EOF
  exit 4
}
### CONFIG
KEY_SIZE=4096 # in bits
KEY_NAME="IRC_USER"
EXP_TIME=1096 # in days
### CONFIG

exit_with_error(){
  echo 1>&2 "irc_cert.sh: ERROR: ${2}"
  exit ${1}
}
message(){
  echo "irc_cert.sh: ${@}"
}

gen_new_key(){
  local key_file="${1}"
  openssl req -x509 -new -newkey rsa:${KEY_SIZE} -sha256 -days ${EXP_TIME} -nodes -out "${key_file}" -keyout "${key_file}"
  return ${?}
}

get_fingerprint(){
  local key_file="${1}"
  openssl x509 -in "${key_file}" -noout -fingerprint -sha512 | awk -F= '{gsub(":",""); print tolower ($2)}'
}

main(){
  [ -z "${1}" ] && help_and_exit
  local command="${1}"
  [ ! -z "${2}" ] && KEY_NAME="${2}"
  local out_file="${KEY_NAME}.pem"
  
  case ${command} in
    gen)
      message "Generating New Key ${KEY_NAME}"
      gen_new_key "${out_file}" || exit_with_error 1 "Key Generation FAILED!"
      get_fingerprint "${out_file}" || exit_with_error 1 "Could not get fingerprint"
      ;;
    fingerprint)
      [ ! -f ${out_file} ] && exit_with_error 1 "Could not find key at ${out_file}, see help"
      message "Fingerprint for ${KEY_NAME}:"
      get_fingerprint "${out_file}" || exit_with_error 1 "Could not get fingerprint"
      ;;
    *)
     help_and_exit
     ;;
  esac
}

main "${@}"
