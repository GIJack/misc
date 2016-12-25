#!/bin/sh
# Make snakeoil ssl cert 
# use as ./snakeoil_cert.sh (hostname) (key length in bits) (days 'till expiration)

#Grab variables and set defaults of blank
CERTNAME="${1}"
BITS="${2}"
DAYS="${3}"
[ -z $1 ] && CERTNAME="server"
[ -z $2 ] && BITS=4096
[ -z $3 ] && DAYS=3650

openssl req -x509 -sha256 -nodes -days ${DAYS} -newkey rsa:${BITS} -keyout "${CERTNAME}.key" -out "${CERTNAME}.crt"

