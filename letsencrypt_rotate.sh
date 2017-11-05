#!/bin/bash
# This script should be run by cron everyime letsencrypt updates scripts.
# Does post rotate proccessing. All services should have an appropriate
# systemd unit.
# - GI_Jack GPLv3

#space seperated list of systemd units
services="nginx ejabberd"
#Hostname
hostname="yourletsncryptdomain.sucks"

### Per Service Functions ###
## you NEED a service_NAME for every service in services= above. If there is
## nothing to do, simply put "true" or return.

service_ejabberd(){
  # use lets encrypt certs for ejabberd
  cat /etc/letsencrypt/live/${hostname}/{privkey,fullchain}.pem > /etc/ejabberd/ejabberd.pem
  chown ejabberd:ejabberd /etc/ejabberd/ejabberd.pem
  chmod 640 /etc/ejabberd/ejabberd.pem
}

service_nginx(){
  true
}

### End Per Service Functions ###

main(){
  for i in ${services};do
    service_${i}
    systemctl restart ${i}
  done
}
main
