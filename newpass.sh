#!/bin/bash
#generates a new password with mkpassword,use as newpass <min length> <max length>
# defaults between 20 and 30 characters
min=20
max=30

if [ ! -z $2 ];then
    max=$2
    min=$1
  elif [ ! -z $1 ];then
    min=$1
    max=$1
fi

makepasswd --minchars=${min} --maxchars=${max}

