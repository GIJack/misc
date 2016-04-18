#!/bin/bash
#
# This script reads and/or strips the metadata header from .su3 package files
# used by the i2p privacy network. As specified: https://geti2p.net/spec/plugin
#
# - GI Jack, licensed under GPLv3

#some size variables
declare -i SIGLENGTH
declare -i VERLENGTH
declare -i IDLENGTH
declare -i HEADLENGTH

BRIGHT=$(tput bold)
BRIGHT_RED=$(tput setaf 1;tput bold)
BRIGHT_YELLOW=$(tput setaf 3;tput bold)
NOCOLOR=$(tput sgr0)

# the famous Ninja OS full four fingered fist.
message() {
    echo "${BRIGHT}i2package.sh${NOCOLOR}: $@"
}
exit_with_error() {
    message "${BRIGHT_RED}!ERROR!${NOCOLOR} ${2}" 1>&2
    exit $1
}
cont_with_warn() {
    message "${BRIGHT_YELLOW}Warn:${NOCOLOR} ${@}" 1>&2
}
help_and_exit() {
    echo "${BRIGHT}su3_package.sh${NOCOLOR}:" 1>&2
    cat 1>&2 << EOF
	Reads from the .su3 package format used by the I2P privacy networking
for distributing software.

	Usage:
	i2package.sh [--options] <filename>

	Options:

	-s, --strip	remove .su3 header leaving an otherwise usable zip or
			xml file.

	-h, --header	print header information.
EOF
exit 1
}

enum_header_meta(){
  # fill metadata into variables.
  local infile="${1}"

  #yeah, this is a regular zip file, but with some wierd shit added as a header.
  # nooo, they couldn't just use an index file like normal people.
  SIGLENGTH=$(dd if="${infile}" skip=10 bs=2 count=1 | printf "%d")
  VERLENGTH=$(dd if="${infile}" skip=13 bs=1 count=1 | printf "%d")
  IDLENGTH=$(dd if="${infile}" skip=15 bs=1 count=1 | printf "%d")
  HEADLENGTH=$(( $SIGLENGTH + $VERLENGTH + $HEADLENGTH ))
}

strip_header() {
  # strip the headers off giving us a file usable by other files
  local infile="${1}"
  local outfile="${infile%.su3}.zip"

  enum_header_meta
  dd if="${infile}" of="${outfile}" bs=$HEADLENGTH skip=1
}

print_meta_info() {
  # Fill global variables with information from a .su3 header.
  local infile="${1}"
  message ".su3 header file info for ${infile}"

}


