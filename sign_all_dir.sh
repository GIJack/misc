#!/usr/bin/env bash

# exit codes 4-help, 2-user error, 1-program error

help_and_exit(){
  cat 1>&2 << EOF
	sign_all_dir.sh:
Sign all files in a directory with GPG.

	Usage:
	$ sign_all_dir.sh <GPG_KEY>

EOF
  exit 4
}

main() {
    if [ -z $1 ];then
      help_and_exit
     else
      local gpg_key="${1}"
    fi

    for file in *;do
      gpg -u ${gpg_key} -b ${file}
    done
}

main "${@}"
