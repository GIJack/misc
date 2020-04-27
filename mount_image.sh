#!/usr/bin/env bash

command="${1}"
filename="${2}"
loop_dev=loop1
mount_point="${HOME}/mnt"
ROOT_METHOD="sudo"

help_and_exit(){
  cat 1>&2 << EOF
mount_image.sh:

Mount and dismount qemu images

USAGE: mount_image.sh <command> <file.img>

Commands: mount umount

EOF
  exit 2
}
message(){
  echo "mount_image.sh: ${@}"
}

exit_with_error(){
  echo 1>&2 "mount_image: ERROR: ${2}"
  exit ${1}
}

as_root(){
  # execute a command as root.
  case $ROOT_METHOD in
   sudo)
    sudo ${@}
    ;;
   uid)
    ${@}
    ;;
  esac
}

_mount-img() {
  local -i local_exit=0
  message "Mounting ${filename} on ${loop_dev} on ${mount_point}"
  as_root losetup -P ${loop_dev} "${filename}"
  local_exit+=${?}
  as_root mount /dev/${loop_dev}p1 ${mount_point}
  local_exit+=${?}
  return ${local_exit}
}

_umount-img() {
  local -i local_exit=0
  message "UnMounting ${mount_point} on ${loop_dev}"
  as_root umount ${mount_point}
  local_exit+=${?}
  as_root losetup -d /dev/${loop_dev}
  local_exit+=${?}
  return ${local_exit}
}

main() {
  case ${command} in
    mount)
      [ -z ${filename} ] && help_and_exit
      _mount-img || exit_with_error 1 "Could not mount ${filename}"
      ;;
    umount)
      _umount-img || exit_with_error 1 "Could Not unmount ${mount_point}"
      ;;
    *)
      help_and_exit
      ;;
  esac
}

main "${@}"
