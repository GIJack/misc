#!/usr/bin/env bash

help_and_exit(){
  cat 1>&2 << EOF
certbot_znc_update.sh

Runonce that runs certbot, and the updates znc with Lets Encrypt! certs, so
it works with LE certs.

    USAGE:
    ./certbot_znc_update.sh [firstrun|renew|help]
EOF
  exit 4
}
### VARIABLES
# Edit this before use. This is what email your LETS ENCRYPT! certs are registered to
readonly LETSENCRYPT_EMAIL="postmaster@example.com"

### /VARIABLES

### CONSTANTS
readonly FQDN="$(hostname)"
readonly ENCRYPTION_KEY="/etc/letsencrypt/live/${FQDN}/privkey.pem"
readonly ENCRYPTION_CERT="/etc/letsencrypt/live/${FQDN}/fullchain.pem"
readonly ZNC_CERT_FILE="/var/lib/znc/.znc/znc.pem"
readonly ZNC_HOME="/var/lib/znc/"
readonly ZNC_USER="znc"
readonly DH_PARAM_FILE="/etc/ssl/private/dhparam.pem"
readonly DH_PARAM_BITS=2048
readonly TODAY=$(date +%Y%m%d) #Today's date in YYYYMMDD
readonly CERT_DATE=$(date -d "$(stat --format=%y ${ENCRYPTION_CERT})" +%Y%m%d) #Date of LE Certs in YYYYMMDD
### /CONSTANTS

message(){
  echo "certbot_znc_update.sh: ${@}"
  logger "certbot_znc_update.sh: ${@}"
}

submsg(){
  echo "[+] ${@}"
  logger "certbot_znc_update.sh: ${@}"
}

exit_with_error(){
  echo 1>&2 "certbot_znc_update.sh: ERROR: ${2}"
  logger "certbot_znc_update.sh: ERROR: ${2}"
  exit ${1}
}

init_certbot(){
  local -i errors=0
  local firewalld_service="80/tcp"
  
  firewall-cmd --add-service=${firewalld_service} --zone=public  || return 9
  firewall-cmd --reload
  certbot certonly --standalone --domains "${FQDN}" -n --agree-tos --email "${LETSENCRYPT_EMAIL}" || errors+=1
  firewall-cmd --remove-service=${firewalld_service} --zone=public || warn "IPTables rule for certbot left open. Please correct this mantually"
  firewall-cmd --reload

  # Generating DH parms is a one time thing. Technically we have some in znc.pem, but we need a stand alone file. Easiest way
  # to do this in shell is just make a new one
  openssl dhparam -out "${DH_PARAM_FILE}" ${DH_PARAM_BITS} || errors+=1
  chown 600 "${DH_PARAM_FILE}"
  return ${errors}
}

renew_certbot(){
  local -i error_code=0
  local firewalld_service="http"

  firewall-cmd --add-service=${firewalld_service} --zone=public  || return 9
  firewall-cmd --reload 
  /usr/bin/certbot -q renew || error_code=${?}
  firewall-cmd --remove-service=${firewalld_service} --zone=public || warn "IPTables rule for certbot left open. Please correct this mantually"
  firewall-cmd --reload

  return ${error_code}
}

gen_znc_pem(){
  # ZNC puts everything in a single file.
  local -i errors=0
  cat "${ENCRYPTION_KEY}" > "${ZNC_CERT_FILE}" || errors+=1
  cat "${ENCRYPTION_CERT}" >> "${ZNC_CERT_FILE}" || errors+=1
  cat "${DH_PARAM_FILE}">> "${ZNC_CERT_FILE}" || errors+=1
  chown "${ZNC_USER}":"${ZNC_USER}" "${ZNC_CERT_FILE}" || errors+=1
  chmod 600 "${ZNC_CERT_FILE}" || errors+=1
  return ${errors}
}

main(){
  declare -i ERRORS=0
  local command="${1}"

  case ${command} in
    firstrun)
      message "Initializing..."
      submsg "Registering with Lets Encrypt via certbot"
      init_certbot || ERRORS+=1
      submsg "Generating ZNC cert file"
      gen_znc_pem || ERRORS+=1
      # set permissions for ZNC user
      chown -R "${ZNC_USER}":"${ZNC_USER}" "${ZNC_HOME}"
      submsg "Restarting ZNC" || ERRORS+=1
      systemctl restart znc
      ;;
    renew)
      message "Updating Certs"
      submsg "Updating Lets Encrypt via certbot"
      renew_certbot || ERRORS+=1
      submsg "Regenerating ZNC cert file"
      gen_znc_pem || ERRORS+=1
      # Only restart ZNC if the cert has recently been reset
      local cert_age=$(( ${TODAY} - ${CERT_DATE} )) #Lets Encrypt! cert age in days
      # If the age of the cert is more
      if [ ${cert_age} -lt 1 ];then
        submsg "Restarting ZNC"
        systemctl restart znc || ERRORS+=1
       else
        submsg "Certificate not renewed recently, skipping reset"
      fi

      ;;
    *)
      help_and_exit
      ;;
  esac
  
  case ${ERRORS} in
    0)
     message "Done"
     exit 0
     ;;
    1)
     message "Done, but with 1 error"
     exit 1
     ;;
    *)
     message "Done, but with ${ERRORS} errors"
     exit 1
     ;;
  esac
  
}

main "${@}"

