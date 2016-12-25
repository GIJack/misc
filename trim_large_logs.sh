#!/bin/bash
# A script to keep file sizes of logs under control by trimming excessively
# sized logs.
# - GI_Jack

# Colon(:) seperated list of directories that contain logs you want trimmed.
LOGDIRS="/var/log/:"
# Size to trigger trimming. Default is One Gigabyte. Uses same format as find
# use k,M,G, for kilo-, mega-, and giga- bytes.
MIN_SIZE=1G
KEEP_LINES=1000
# Uncomment N= to delete logs older than N days
#N=30

SNAME=$(basename "${0}")

help_and_exit(){
  cat 2>&1 << EOF
	$SNAME
A script to keep file sizes of logs under control by trimming excessively
sized logs.

Trims large gigabyte size log files that fill up the disk. Takes one optional
argument, a colon seperated list of directories. Logs are trimmed by saving
the last 1000 lines. Config at top of script.

	# ./trim_large_logs.sh (/path/to/dir1:/path/to/dir2)
EOF
  exit 1
}

message(){
  echo "${SNAME}: ${@}"
}

warn(){
  message 2>&1 "WARN: ${@}"
}

exit_with_error(){
  message 2>&1 "ERROR: ${2}"
  exit $1
}

trim_large_logs(){
  #trims logs one directory at a time
  local logdir="${1}"
  local file_list=$(find "${logdir}" -size +${MIN_SIZE})

  for file in ${file_list};do
    tail -${KEEP_LINES} "${file}" > "${file}"
  done
}

trim_old_logs(){
  #trims logs one directory at a time
  local logdir="${1}"
  local file_list=$(find "${logdir}" -size +${MIN_SIZE})

  for file in ${file_list};do
    find "${logdir}" -type f -mtime +${N} -delete
  done
}

main(){
  IFS_SAVE="${IFS}"
  IFS=":"
  [ "${1}" == --help ] && help_and_exit
  [ ! -z $1 ] && LOGDIRS="${1}"
  set -f ${LOGDIRS}
  message "Trimming logs in $# directories."
  IFS="${IFS_SAVE}"
  for dir in ${@};do
    if [ -d "${dir}" ];then
      trim_large_logs "${dir}" || warn "Large Log trim in ${dir} FAILED!"
      if [ ! -z ${N} ];then
        trim_old_logs "${dir}" || warn "Old Log trim in ${dir} FAILED!"
      fi
     else
      warn "${dir} is not a directory, skipping.."
    fi
  done
}

main "${@}"
