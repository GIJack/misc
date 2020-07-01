#!/usr/bin/env bash
# Generate a hashed password for TOR remote controll
password="${@}"

while [ -z ${password} ];do
  read -s -p "Enter new TOR Password: " password
  echo ""
done

tor --hash-password "${password}"
