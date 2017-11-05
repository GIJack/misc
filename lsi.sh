#!/bin/bash
#
# Script Overhauled and extended by GI_Jack
#
# Calomel.org 
#     https://calomel.org/megacli_lsi_commands.html
#     LSI MegaRaid CLI 
#     lsi.sh @ Version 0.05-Jack1
#
# description: MegaCLI script to configure and monitor LSI raid cards.

# Full path to the MegaRaid CLI binary
MegaCli="/usr/local/sbin/MegaCli64"

# The identifying number of the enclosure.
# Use MegaCli64 -PDlist -a0 | grep "Enclosure Device" or ./lsi.sh enclosures 
# to see what your number is and set this variable. 
ENCLOSURE="8"

# Email Address for checkNEmail Command
EMAIL="raidadmin@localhost"

help_and_exit() {
cat 1>&2 << EOF
            OBPG  .:.  lsi.sh $arg1 $arg2
--------------------------------------------------------------------------------
status		= Status of Virtual drives (volumes)
drives		= Status of hard drives
ident \$slot	= Blink light on drive (need slot number)
good \$slot	= Simply makes the slot "Unconfigured(good)" (need slot number)
replace \$slot	= Replace "Unconfigured(bad)" drive (need slot number)
progress	= Status of drive rebuild
errors		= Show drive errors which are non-zero
bat		= Battery health and capacity
batrelearn	= Force BBU re-learn cycle
logs		= Print card logs
checkNemail	= Check volume(s) and send email on raid errors
allinfo		= Print out all settings and information about the card
settime		= Set the raid card's time to the current system time
setdefaults	= Set preferred default settings for new raid setup
		~~~~~
enclosures	= list the enclosures
driveinfo \$N	= info on a specific drive
createarray	= create an array: lsi.sh createarray <type> <drives>
secureerase \$N	= securely erase a disk
expand		= expand capacitiy of array(s)

EOF
exit 1
}
message(){
  echo "lsi.sh: ${@}"
}
exit_with_error(){
  message 1>&2 "ERROR: ${2}"
  exit ${1}
}
warn(){
  message 1>&2 "WARN: ${@}"
}

cmd_status(){
  # General status of all RAID virtual disks or volumes and if PATROL disk
  # check is running.
  local -i errors=0
  $MegaCli -LDInfo -Lall -aALL -NoLog
  errors+=$?
  echo "###############################################"
  $MegaCli -AdpPR -Info -aALL -NoLog
  errors+=$?
  echo "###############################################"
  $MegaCli -LDCC -ShowProg -LALL -aALL -NoLog
  errors+=$?
  return $errors
}

cmd_drives(){
  # Shows the state of all drives and if they are online, unconfigured or
  # missing.
  $MegaCli -PDlist -aALL -NoLog | egrep 'Slot|state' | awk '/Slot/{if (x)print x;x="";}{x=(!x)?$0:x" -"$0;}END{print x;}' | sed 's/Firmware state://g'
}

cmd_ident() {
  # Use to blink the light on the slot in question. Hit enter again to turn
  # the blinking light off.
  $MegaCli  -PdLocate -start -physdrv[$ENCLOSURE:${1}] -a0 -NoLog || \
   warn "blinking light returns error code"
  logger "${HOSTNAME} - identifying enclosure $ENCLOSURE, drive ${1}"
  message "identifying enclosure $ENCLOSURE, drive ${1}"
  read -p "Press [Enter] key to turn off light..."
  $MegaCli  -PdLocate -stop -physdrv[$ENCLOSURE:${1}] -a0 -NoLog || \
   warn "blinking light returns error code"
}

# When a new drive is inserted it might have old RAID headers on it. This
# method simply removes old RAID configs from the drive in the slot and make
# the drive "good." Basically, Unconfigured(bad) to Unconfigured(good). We use
# this method on our FreeBSD ZFS machines before the drive is added back into
# the zfs pool.0
cmd_good(){
  local -i errors=0
  # set Unconfigured(bad) to Unconfigured(good)
  $MegaCli -PDMakeGood -PhysDrv[$ENCLOSURE:$2] -a0 -NoLog
  errors+=$?
  # clear 'Foreign' flag or invalid raid header on replacement drive
  $MegaCli -CfgForeign -Clear -aALL -NoLog
  errors+=$?
  return $errors
}

# Use to diagnose bad drives. When no errors are shown only the slot numbers
# will print out. If a drive(s) has an error you will see the number of errors
# under the slot number. At this point you can decided to replace the flaky
# drive. Bad drives might not fail right away and will slow down your raid with
# read/write retries or corrupt data. 
cmd_errors(){
  echo "Slot Number: 0"; $MegaCli -PDlist -aALL -NoLog | egrep -i 'error|fail|slot' | egrep -v ' 0'
}

# status of the battery and the amount of charge. Without a working Battery
# Backup Unit (BBU) most of the LSI read/write caching will be disabled
# automatically. You want caching for speed so make sure the battery is ok.
cmd_bat(){
  $MegaCli -AdpBbuCmd -aAll -NoLog
}

# Force a Battery Backup Unit (BBU) re-learn cycle. This will discharge the
# lithium BBU unit and recharge it. This check might take a few hours and you
# will want to always run this in off hours. LSI suggests a battery relearn
# monthly or so. We actually run it every three(3) months by way of a cron job.
# Understand if your "Current Cache Policy" is set to "No Write Cache if Bad
# BBU" then write-cache will be disabled during this check. This means writes
# to the raid will be VERY slow at about 1/10th normal speed. NOTE: if the
# battery is new (new bats should charge for a few hours before they register)
# or if the BBU comes up and says it has no charge try powering off the machine
# and restart it. This will force the LSI card to re-evaluate the BBU. Silly
# but it works.
cmd_batrelearn(){
  $MegaCli -AdpBbuCmd -BbuLearn -aALL -NoLog
}

# Use to replace a drive. You need the slot number and may want to use the
# "drives" method to show which drive in a slot is "Unconfigured(bad)". Once
# the new drive is in the slot and spun up this method will bring the drive
# online, clear any foreign raid headers from the replacement drive and set the
# drive as a hot spare. We will also tell the card to start rebuilding if it
# does not start automatically. The raid should start rebuilding right away
# either way. NOTE: if you pass a slot number which is already part of the raid
# by mistake the LSI raid card is smart enough to just error out and _NOT_
# destroy the raid drive, thankfully.
cmd_replace(){
  local -i errors=0
  logger "${HOSTNAME} - REPLACE enclosure $ENCLOSURE, drive ${1}"
  message "REPLACE enclosure $ENCLOSURE, drive ${1}"
  # set Unconfigured(bad) to Unconfigured(good)
  $MegaCli -PDMakeGood -PhysDrv[$ENCLOSURE:${1}] -a0 -NoLog
  errors+=$?
  # clear 'Foreign' flag or invalid raid header on replacement drive
  $MegaCli -CfgForeign -Clear -aALL -NoLog
  errors+=$?
  # set drive as hot spare
  $MegaCli -PDHSP -Set -PhysDrv [$ENCLOSURE:${1}] -a0 -NoLog
  errors+=$?
  # show rebuild progress on replacement drive just to make sure it starts
  $MegaCli -PDRbld -ShowProg -PhysDrv [$ENCLOSURE:${1}] -a0 -NoLog
  errors+=$?
  return $errors
}

# Print all the logs from the LSI raid card. You can grep on the output.
cmd_logs(){
  $MegaCli -FwTermLog -Dsply -aALL -NoLog
}

# Use to query the RAID card and find the drive which is rebuilding. The script
# will then query the rebuilding drive to see what percentage it is rebuilt and
# how much time it has taken so far. You can then guess-ti-mate the
# completion time.
cmd_progress(){
  DRIVE=$($MegaCli -PDlist -aALL -NoLog | egrep 'Slot|state' | awk '/Slot/{if (x)print x;x="";}{x=(!x)?$0:x" -"$0;}END{print x;}' | sed 's/Firmware state://g' | egrep build | awk '{print $3}')
  $MegaCli -PDRbld -ShowProg -PhysDrv [$ENCLOSURE:$DRIVE] -a0 -NoLog
}

# Use to check the status of the raid. If the raid is degraded or faulty the
# script will send email to the address in the $EMAIL variable. We normally add
# this method to a cron job to be run every few hours so we are notified of any
# issues.
cmd_checknemail(){
  # Check if raid is in good condition
  local drives_status=""
  local gen_status=$(cmd_status)
  STATUS=$($MegaCli -LDInfo -Lall -aALL -NoLog | egrep -i 'fail|degrad|error') || 
   logger $("$HOSTNAME cannot get RAID card status";message "Cannot get RAID card status")

  # On bad raid status send email with basic drive information
  if [ "$STATUS" ]; then
    drives_status=$($MegaCli -PDlist -aALL -NoLog | egrep 'Slot|state' | awk '/Slot/{if (x)print x;x="";}{x=(!x)?$0:x" -"$0;}END{print x;}' | sed 's/Firmware state://g')
    echo $message_body | mail -s "${HOSTNAME} - RAID Notification" $EMAIL << EOF

Array Status
------------
$gen_status

Drives
------
$drives_status
EOF
  fi
}

# Use to print all information about the LSI raid card. Check default options,
# firmware version (FW Package Build), battery back-up unit presence, installed
# cache memory and the capabilities of the adapter. Pipe to grep to find the
# term you need.
cmd_allinfo(){
  $MegaCli -AdpAllInfo -aAll -NoLog
}

# Update the LSI card's time with the current operating system time. You may
# want to setup a cron job to call this method once a day or whenever you
# think the raid card's time might drift too much. 
cmd_setting(){
  local -i errors=0
  $MegaCli -AdpGetTime -aALL -NoLog
  errors+=$?
  $MegaCli -AdpSetTime $(date +%Y%m%d) $(date +%H:%M:%S) -aALL -NoLog
  errors+=$?
  $MegaCli -AdpGetTime -aALL -NoLog
  errors+=$?
  return $errors
}

# These are the defaults we like to use on the hundreds of raids we manage. You
# will want to go through each option here and make sure you want to use them
# too. These options are for speed optimization, build rate tweaks and PATROL
# options. When setting up a new machine we simply execute the "setdefaults"
# method and the raid is configured. You can use this on live raids too.
cmd_setdefaults(){
  local -i errors=0
  # Read Cache enabled specifies that all reads are buffered in cache memory. 
  $MegaCli -LDSetProp -Cached -LAll -aAll -NoLog
  errors+=$?
  # Adaptive Read-Ahead if the controller receives several requests to sequential sectors
  $MegaCli -LDSetProp ADRA -LALL -aALL -NoLog
  errors+=$?
  # Hard Disk cache policy enabled allowing the drive to use internal caching too
  $MegaCli -LDSetProp EnDskCache -LAll -aAll -NoLog
  errors+=$?
  # Write-Back cache enabled
  $MegaCli -LDSetProp WB -LALL -aALL -NoLog
  errors+=$?
  # Continue booting with data stuck in cache. Set Boot with Pinned Cache Enabled.
  $MegaCli -AdpSetProp -BootWithPinnedCache -1 -aALL -NoLog
  errors+=$?
  # PATROL run every 672 hours or monthly (RAID6 77TB @60% rebuild takes 21 hours)
  $MegaCli -AdpPR -SetDelay 672 -aALL -NoLog
  errors+=$?
  # Check Consistency every 672 hours or monthly
  $MegaCli -AdpCcSched -SetDelay 672 -aALL -NoLog
  errors+=$?
  # Enable autobuild when a new Unconfigured(good) drive is inserted or set to hot spare
  $MegaCli -AdpAutoRbld -Enbl -a0 -NoLog
  errors+=$?
  # RAID rebuild rate to 60% (build quick before another failure)
  $MegaCli -AdpSetProp \{RebuildRate -60\} -aALL -NoLog
  errors+=$?
  # RAID check consistency rate to 60% (fast parity checks)
  $MegaCli -AdpSetProp \{CCRate -60\} -aALL -NoLog
  errors+=$?
  # Enable Native Command Queue (NCQ) on all drives
  $MegaCli -AdpSetProp NCQEnbl -aAll -NoLog
  errors+=$?
  # Sound alarm disabled (server room is too loud anyways)
  $MegaCli -AdpSetProp AlarmDsbl -aALL -NoLog
  errors+=$?
  # Use write-back cache mode even if BBU is bad. Make sure your machine is on UPS too.
  $MegaCli -LDSetProp CachedBadBBU -LAll -aAll -NoLog
  errors+=$?
  # Disable auto learn BBU check which can severely affect raid speeds
  OUTBBU=$(mktemp /tmp/output.XXXXXXXXXX)
  echo "autoLearnMode=1" > $OUTBBU
  $MegaCli -AdpBbuCmd -SetBbuProperties -f $OUTBBU -a0 -NoLog
  errors+=$?
  rm -rf $OUTBBU
  return $errors
}

### commands added by GI_Jack ###
cmd_enclosures(){
  message "Enclosures Available:"
  $MegaCli -PDlist -a0|grep -A4 "Enclosure Device ID"
}

# Print information on a specific drive
cmd_driveinfo(){
   local -i errors=$?
   local drive=${1}
   $MegaCli -PDInfo -PhysDrv [${ENCLOSURE}:${drive}] -aALL | grep -A2 "Enclosure Device ID"
   errors+=$?
   $MegaCli -PDInfo -PhysDrv [${ENCLOSURE}:${drive}] -aALL | grep -A5 "Raw Size:"
   errors+=$?
   $MegaCli -PDInfo -PhysDrv [${ENCLOSURE}:${drive}] -aALL | grep "Inquiry Data:"
   errors+=$?
   return $errors
}

# Create a RAID array usage
# cmd_createarray <type> <disks> 
cmd_createarray(){
  local -i n=${#}
  local -i type=${1}
  local disks="${@: 2}"
  local array=""
  for disk in ${disks};do
    array+=" [${ENCLOSURE}:${disk}]"
  done
  message "Creating RAID${type} Array on ENCLOSURE ${ENCLOSURE} spanning disks ${disks}..."
  ${MegaCli} -CfgLdAdd -r${type} ${array} -a${n}
}

# security erase of a drive
# cmd_secureerase <disk#>
cmd_secureerase(){
  local disk=${1}
  ${MegaCli} -SecureErase Start Standard [${ENCLOSURE}:${disk}] -a0
}

# migrate to larger disk sizes
cmd_expand(){
  ${MegaCli} -LdExpansion -p100 -Lall -aAll
}
### End Jack's Commands ###

main(){
  COMMAND="$1"
  [ -z $1 ] && COMMAND="help"
  COMMAND=${COMMAND,,}
  shift
  case ${COMMAND} in
   help|--help)
     help_and_exit
     ;;
   *)
     #[[ *${COMMAND}* != ${COMMANDLIST[@]} ]] && exit_with_error 1 "No such command $COMMAND, see help"
     cmd_${COMMAND} "${@}" || exit_with_error $? "${COMMAND} failed, exit status(${?})"
     ;;
  esac
}
main ${@}

### EOF ###
