#!/bin/bash
#
# Search all users .bash_history for a string
# So far only .bash_history is supported. perhaps later I'll support other files

# GI_Jack - GPLv3

HISTORY=".bash_history"
PASSWD="/etc/passwd"

help_and_exit(){
  cat 1>&2 << EOF
  grep_all_history.sh:

This script greps through everyone's shell history file looking for certain
strings.

  usage:
	$ ./grep_history <string>
EOF
exit 1
}

[ -z $1 ] && help_and_exit
SRCH="$1"

for line in $(cat ${PASSWD});do
  unset output
  username=$(echo $line | cut -d ":" -f 1 )
  homedir=$( echo $line | cut -d ":" -f 6 )
  filename="${homedir}/${HISTORY}"
  [ -f "$filename" ] && output=$(grep -e "${SRCH}" -f "${filename}")
  if [ ! -z $output ];then
    echo "${username} ${filename}: "
    echo "${output}"
  fi
done
