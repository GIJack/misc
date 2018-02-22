#!/bin/bash
#
# Cylinder-Head-Sector to Logical Block Addressing converter.
#
# This script converts a set of co-ordinates from CHS to LBA for use with
# recovery and forensic scripts that might need this.
#

declare -i CYLINDER
declare -i HEAD
declare -i SECTOR

exit_with_error(){
  echo "chs2lba.sh: ERROR: ${@:2}"
  exit ${1}
}

help_and_exit(){
  cat 1>&2 << EOF
chs2lba.sh - convert CHS corindates into LBA sector count.

	USAGE:

	$ chs2lbah.sh <cylinder> <head> <sector>

All three must be intergers

EOF
exit 2
}

main() {
  # Check for input errors
  [ -z ${1} ] && help_and_exit
  [[ *help* = ${1} ]] && help_and_exit
  [ -z ${2} -o -z ${3} ] && exit_with_error 1 "cylinder, head and sector must be specified --help"
  CYLINDER=${1}
  HEAD=${2}
  SECTOR=${3}

  # Do the math: https://stackoverflow.com/questions/32642016/chs-to-lba-mapping-disk-storage
  local -i bytes_cylinder=$((${CYLINDER} * 256))
  local -i bytes_head=$((${HEAD} * 63 ))
  local -i lba_sector=$((${bytes_cylinder} + ${bytes_head} + ${SECTOR} ))

  #output
  echo ${lba_sector}
}

main $@
