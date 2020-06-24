#!/usr/bin/env bash
# Generate a hashed password for TOR remote controll
password="${@}"

while [ -z ${password} ];do
  read -p "Enter new TOR Password: " password
done

tor --hash-password "${password}"
