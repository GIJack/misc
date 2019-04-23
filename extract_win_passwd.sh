#!/bin/bash

# This script scans for windows paritions, and then dumps NT passwords with
# samdump2

# GPLv3 - GI_Jack

#Name and location of windows password files. Should not need to change this
### CONFIG ###
SAM_FILE="sam"
SYSTEM_FILE="SYSTEM"
WIN_PASSWD_DIR="/WINDOWS/system32/config/"
ROOT_METHOD="sudo"
### /CONFIG ###

DEP_LIST="dialog samdump2"
WIN_TITLE="EXTRACT WINDOWS PASSWORD"
DISK_PARTS=""
SELECT_PARTS=""
NT_PARTS=""
declare -A PART_FSTYPE
declare -A PART_DESC

help_and_exit(){
  cat 1>&2 << EOF
extract_win_passwd.sh:

This script dumps Windows passwords from selected disk partition. Takes no
parameters, but opens a dialog menu to ask for disk partions to use.

Results are written one file per parition and tar gz'd into win_passwds.tar.gz

needs to be either run as root, or have a working sudo

EOF
  exit 2
}

message(){
  echo "extract_win_passwd.sh: ${@}"
}

warn(){
  echo 1>&2 "extract_win_passwd.sh: WARN: ${@}"
}

exit_with_error(){
  echo 1>&2 "extract_win_passwd.sh: ERROR: ${2}"
  exit ${1}
}

check_sudo(){
  # Check if this script can run sudo correctly.
  local -i success
  local sudouser=""
  sudouser=$( sudo whoami )
  if [ ${sudouser} == "root" ];then
    echo true
   else
    echo false
  fi
}

as_root(){
  # execute a command as root.
  case $ROOT_METHOD in
   sudo)
    sudo $@
    ;;
   uid)
    $@
    ;;
  esac
}

enum_disk_parts(){
  DISK_PARTS=$(lsblk -ln | grep part | cut -f 1 -d " ")
  local fstype
  local disk_size
  local mount_point
  local disk_label
  for part in ${DISK_PARTS};do
    # fill array with name to partition type data
    fstype=$(lsblk -f /dev/${part}|tail -1| cut -d " " -f 2)
    PART_FSTYPE[${part}]="$fstype"
    disk_size=$(lsblk -ln |grep ${part}|awk '{print $4}')
    #mount_point=$(lsblk -ln |grep ${part}|awk '{print $7}')
    disk_label=$(lsblk -lo name,label |grep ${part} |awk '{print $2}')
    # Fill in description array with disksize, label, and mountpoint
    PART_DESC[${part}]="${disk_size} ${disk_label}"
  done
}

check_deps(){
  #This function checks dependencies
  for dep in ${DEP_LIST};do
    which ${dep} &> /dev/null
    if [ $? -ne 0 ];then
      exit_with_error 4 "$dep is not in \$PATH! This is needed to run. Quitting"
    fi
  done
}

welcome_banner(){
  local welcome_msg="
This script targets invidual disk partitions looking for Windows password files.
In the next screen you will be asked to select windows disk partitions.

Results will be written to files and compressed into win_passwords.tar.gz in
current direction

"
  dialog --backtitle "${WIN_TITLE}" --msgbox "${welcome_msg}" 10 50
}

ask_user_parts(){
  # This function makes a dialog menu to ask what disks to use.
  local tempfile=$(mktemp) || exit_with_error 1 "Cannot make temp file"
  local part_list=""
  local item_desc=""
  local user_choice=""

  # make item list of dialog below
  for item in ${DISK_PARTS};do
    item_desc="${PART_FSTYPE[${item}]} ${PART_DESC[${item}]}"
    #part_list="${part_list} \"${item}\" \"${item} ${item_desc}\" off \\"
    part_list+="${item} \"${item} ${item_desc}\" off \\"
  done
  #dialog asks user
  cat > ${tempfile} << EOF
dialog --backtitle "${WIN_TITLE}" --visit-items --buildlist "Select Disk Parition(s) to Check:" 20 50 5 \
${part_list}

EOF
  bash ${tempfile} 2>&1
  rm ${tempfile}
}

extract_pw_hash(){
  # This function extracts password hashes from selected hard disks
  local tmpdir=$(mktemp -d)
  local parts="${SELECT_PARTS}"
  local mountpoint=""
  local mounted=""
  local samfile=""
  local systemfile=""
  local outfile="win_passwds.tar.gz"

  for part in ${parts};do
    # check if mounted
    mountpoint=$( mount | grep ${part} | cut -d " " -f3 )

    # If file system is already mounted, then use the current mount, otherwise
    # mount it to a temp directory
    if [ -z ${mountpoint} ];then
      mounted="false"
      mountpoint=$(mktemp -d)
      as_root mount /dev/${part} ${mountpoint}
     else
      mounted="true"
    fi

    samfile="${mountpoint}/${WIN_PASSWD_DIR}/${SAM_FILE}"
    systemfile="${mountpoint}/${WIN_PASSWD_DIR}/${SYSTEM_FILE}"
    outfile="${tmpdir}/${part}.passwd"

    # Check for needed files on the system
    if [ ! -f "${samfile}" ];then
      warn "SAM file NOT FOUND for ${part} on ${mountpoint}, skipping..."
      continue
     elif [ ! -f "${systemfile}" ];then
      warn "SYSTEM file NOT FOUND for ${part} on ${mountpoint}, skipping..."
      continue
    fi

    # Now attempt recovery
    samdump2 -o "${outfile}" "${systemfile}" "${samfile}" || \
      warn "could not get password"
    #cleanup
    if [ ${mounted} == "false" ]; then
      as_root umount /dev/${part}
      rmdir ${mountpoint}
    fi
  done

  # Now compress all output files into a gzip'd tar file
  tar zcf "${outfile}" ${tmpdir} || exit_with_error 2 "Cannot output passwords!"
  # clean up
  rm -r ${tmpdir}
}

main(){
  [ "${1}" == "--help" ] && help_and_exit
  check_deps
  local can_sudo=$(check_sudo)

  if [ ${UID} -eq 0 ];then
    ROOT_METHOD="uid"
   elif [ ${can_sudo} == "true" ];then
    ROOT_METHOD="sudo"
   else
    exit_with_error 4 "Cannot gain root! This program needs root to work Exiting..."
  fi

  [ ${can_sudo} != "true" ] && ROOT_METHOD="UID"
  message "Looking for presence of windows password files"
  enum_disk_parts
  SELECT_PARTS=$(ask_user_parts)
  extract_pw_hash
}

main "$@"
