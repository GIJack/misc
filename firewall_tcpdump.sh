#!/usr/bin/env bash
# exit codes 0-success, 1-script error, 2-user error, 4-help

help_and_exit(){
  cat 1>&2 << EOF
${BRIGHT}firewall_tcpdump.sh${NOCOLOR}:
This iptables/tcpdump wrapper that allows you to use tcpdump with INPUT chain
firewalled. Opens a port on the firewall, runs tcpdump, closes the port when
tcpdump is closed. 

	${BRIGHT}USAGE${NOCOLOR}:
	firewall_tcpdump.sh <tcpdump statement>
EOF
  exit 4
}

PORT=0
PROTO=""
BRIGHT=$(tput bold)
NOCOLOR=$(tput sgr0) #reset to default colors
BRIGHT_RED=$(tput setaf 1;tput bold)
BRIGHT_YELLOW=$(tput setaf 3;tput bold)
BRIGHT_CYAN=$(tput setaf 6;tput bold)

exit_with_error(){
  echo 1>&2 "firewall_tcpdump.sh: ${BRIGHT_RED}ERROR${NOCOLOR}: ${2}"
  exit ${1}
}
message(){
  echo "firewall_tcpdump.sh: ${@}"
}
check_port_and_proto() {
  local item="${1,,}"
  case ${item} in
   port)
    PORT=${2}
    shift
    ;;
   tcp)
    PROTO="tcp"
    ;;
   udp)
    PROTO="udp"
    ;;
   icmp)
    PROTO="icmp"
  esac
  shift
  item="${1,,}"
}

main() {
  # Sanity Check
  [ $1 == "--help" ] && help_and_exit 
  [ -z $PROTO ] && PROTO="tcp"
  iptables -A INPUT -m $PROTO -p ${PROTO} --dport ${PORT}
  tcpdump ${@}
  iptables -D INPUT -m $PROTO -p ${PROTO} --dport ${PORT}
}

check_port_and_proto "${@}"
main "${@}"
