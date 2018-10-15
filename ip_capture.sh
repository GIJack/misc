#!/system/xbin/bash
#
# Run this on android with nexmon to capture and save packets for a file
# GPLv3 - GI_Jack: All American Zero

save_loc=/storage/emulated/0/Download/
outfile_base="mon_cap"
iface=wlan0

cap_file=$(mktemp)
time_stamp=$(date +%Y%m%d_%H%M%S)

declare -i exit_code=0

cleanup_and_exit(){
  cp "${cap_file}" "${save_loc}/${outfile_base}_${time_stamp}.pcap"
  rm "${cap_file}"
  exit
}

main() {
  trap cleanup_and_exit SIGTERM SIGINT

  tcpdump -i ${iface} -w ${cap_file} &
  pid=$!
  wait ${pid}
}

main "${@}"
