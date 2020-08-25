#!/bin/sh
# Test daemon. Gives a prints "hello world" and gives port number it is
# listening on. Useful for testing network connections and setup

port=1337
while true;do
  nc -l $port << EOF
hello world
port: $port
EOF
done
