#!/bin/sh
# Test daemon. Listens on a network port and responds with hello world and 
# port number.

port=1337
while true;do
  nc -l $port << EOF
hello world
port: $port
EOF
done
