#!/usr/bin/env bash
# 
# Create an emergency swap file that can quickly activatewd
#

# Swapfile size, in megabytes. Default is 16GB
SIZE=16384

# Path of emergency swap file
SWAP_FILE="/emergency_swap"

# Source for creating file
FILL_SRC="/dev/zero"

WIPE_CMD="shred -f -n 1"

help_and_exit(){
  cat 1>&2 << EOF
emergency_swap.sh:
Create, activate and reset emergency swap. Emergency swap is a ready to go swap
file that can be quickly turned on if you are in danger of running out of
memory. upon turning off, this script will wipe and reset the swapfile to
prevent data leakage. Config on the top of the script

	Usage:
	emergency_swap.sh [create|on|off]

	commands:

	init	- create the swap file, wipe and re-create if exists

	on	- turn on emergency swap

	off	- turn off and reset emergency swap. swapoff, wipe and recreate
		  swap file
EOF
  exit 2
}

message(){
  echo "emergency_swap.sh: ${@}"
}

exit_with_error(){
  echo 1>&2 "emergency_swap.sh: ERROR: ${2}"
  exit ${1}
}

warn(){
  echo 1>&2 "emergency_swap.sh: WARN: ${@}"
}

submsg(){
  echo "[+] ${@}"
}

create_swap_file(){
  local -i exit_code=0
  local -i block_size=1024k # One Megabyte
  if [ -f "${SWAP_FILE}" ];then
    message "${SWAP_FILE} exits, removing first..."
    ${WIPE_CMD} --remove "${SWAP_FILE}" || \
      exit_with_error 1 "Cannot Remove stale swap file, exiting!"
  fi

  message "Creating emergency swap"
  dd if="${FILL_SRC}" of="${SWAP_FILE}" bs=${block_size} count=${SIZE}
  exit_code+=${?}
  mkswap ${SWAP_FILE}
  exit_code+=${?}

  return ${exit_code}
}

emergency_swap_on(){
  message "Turning emergency swap on"
  swapon ${SWAP_FILE} || exit_with_error 1 "Could not swapon, root?"
}

emergency_swap_off(){
  message "Turning emergency swap off, and resetting"
  submsg "Swapoff"
  swapoff ${SWAP_FILE} || exit_with_error 1 "Could not swapoff, root?"
  submsg "Wipe"
  ${WIPE_CMD} "${SWAP_FILE}" || warn "Wipe on ${SWAP_FILE} failed"
  mkswap "${SWAP_FILE}" || exit_with_error 1 "Could not recreate swap."
}

main(){
  local command="${1}"

  case ${command} in
   init)
    create_swap_file || exit_with_error 1 "Swapfile creation failed"
   ;;
   on)
    emergency_swap_on
   ;;
   off)
    emergency_swap_off
   ;;
   *)
    help_and_exit
   ;;
  esac
}

main "${@}"
