#!/bin/bash
# This script should be run by cron everyime letsencrypt updates scripts.
# Does post rotate proccessing. All services should have an appropriate
# systemd unit. You can specify a pre restart function
# - GI_Jack GPLv3

### CONFIG ###
#space seperated list of systemd units
SERVICES="nginx ejabberd"
#Hostname
HOSTNAME="yourletsncryptdomain.sucks"
### /CONFIG ###

### Per Service Functions ###
## If service_$SERVICENAME is present, it will be executed when the service is
## rotated

service_ejabberd(){
  # use lets encrypt certs for ejabberd
  cat /etc/letsencrypt/live/${HOSTNAME}/{privkey,fullchain}.pem > /etc/ejabberd/ejabberd.pem
  chown ejabberd:ejabberd /etc/ejabberd/ejabberd.pem
  chmod 640 /etc/ejabberd/ejabberd.pem
}

### /Per Service Functions ###

main(){
  for service in ${SERVICES};do
    [ $(type -t service_${i}) == "function" ] && service_${i}
    systemctl restart ${i}
  done
}
main
