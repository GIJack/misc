#!/bin/sh
[ -z $1 ] && echo "specify a password";exit 1
tor --hash-password "${@}"
