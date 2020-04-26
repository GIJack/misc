#!/usr/bin/env bash
#
#  See help_and_exit() below
#
command="${1}"
filename="${2}"
loop_dev=loop1
mount_point="${HOME}/mnt"
ROOT_METHOD="sudo"

help_and_exit(){
  cat 1>&2 << EOF
mount_image.sh:

Script is designed to mount and unmount QEMU single partition disk images for
manipulation in a chroot.

USAGE: mount_image.sh <command> <file.img>

Commands: mount umount

EOF
  exit 2
}
message(){
  echo "mount_image.sh: ${@}"
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
  message "UnMounting ${filename} from ${mount_point} on ${loop_dev}"
  as_root umount ${mount_point}
  local_exit+=${?}
  as_root losetup -d /dev/${loop_dev}
  local_exit+=${?}
  return ${local_exit}
}

main() {
  [ -z ${filename} ] && help_and_exit
  case ${command} in
    mount)
      _mount-img || exit_with_error 1 "Could not mount ${filename}"
      ;;
    umount)
      _umount-img || exit_with_error 1 "Could Not unmount ${filename}"
      ;;
    *)
      help_and_exit
      ;;
  esac
}

main "${@}"
