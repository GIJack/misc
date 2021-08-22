#!/usr/bin/env python
prog_desc='''arp_watch.py
This python program/daemon for monitoring the arptables and logging
changes to file. Can optionally use arp-scan for active monitoring.

If you specify IP addresses on the command line, watch will limit to these.
Otherwise everything will be monitored.

Current table will be in /var/arp_watch/arp-table

This program needs to be run as root. you should likely start with it attached
system .service file
'''
prog_desc = prog_desc.strip()

import argparse
import signal
import sys, os
import subprocess
import time

options = {
    'progname'    : os.path.basename(sys.argv[0]),
    'logfile'     : '/var/log/arp_watch.log',
    'arp_table'   : '/var/arp_watch/arp-table',
    'activescan'  : False,
    'check_int'   : 0.5,
}

class colors:
    bold='\033[01m'
    reset='\033[0m'
    brightred='\033[91m'
    brightgreen='\033[92m'
    yellow='\033[93m'
    brightcyan='\033[96m'

def exit_with_error(code,message):
    '''Exit with an code and message'''
    print("arp_watch.py:" + colors.brightred + " ERROR: " + colors.reset + message,file=sys.stderr)
    sys.exit(code)

def report_log(text_string):
    '''print an abritrary string to the logs/console'''
    line = time.asctime() + ' ' + options['progname'] + ": " + text_string
    print(line)
    outfile = open(options['logfile'],"a")
    outfile.write(line+"\n")
    outfile.close()
        
def check_passive(address_list,in_arp_table=None):
    '''Checks current arp table against previous arp table, logs changes'''
    errors = 0
    #step one, get current arp table
    arp_table = [{},{}]  #two dicts, first is for ip-mac pairs, and second is for ip-interface pairs
    if address_list == []:
        try:
            arp_output = subprocess.check_output(["arp","-na"])
        except:
            exit_with_error(1,"Could run arp -na, please check envornment.")
        arp_output = arp_output.decode()
        arp_output = arp_output.split('\n')
        for line in arp_output:
            line = line.split()
            if len(line) < 4:
                continue
            ip_addr,mac_addr,iface = line[1],line[3],line[-1]
            ip_addr = ip_addr.strip("()")
            # update arp table, 0 is ip-mac table, 1 is ip-interface table
            arp_table[0].update({ip_addr:mac_addr})
            arp_table[1].update({ip_addr:iface})
    else:
        for address in address_list:
            try:
                arp_output = subprocess.check_output(["arp","-na", address])
            except:
                errors += 1
                continue
            arp_output = arp_output.decode()
            arp_output = arp_output.strip()
            if "no match found" in arp_output:
                continue
            arp_output = arp_output.split()
            ip_addr,mac_addr,iface = arp_output[1],arp_output[3],arp_output[-1]
            ip_addr = ip_addr.strip("()")
            arp_table[0].update({ip_addr:mac_addr})
            arp_table[1].update({ip_addr:iface})
    
    if in_arp_table == None:
        # If there is no existing arp table, all IPs are new
        for ip in arp_table[0]:
            message = "New Entry: IP_Address: " + ip + " MAC_Address: " + arp_table[0][ip] + " on Interface: " + arp_table[1][ip]
            report_log(message)
        return arp_table
    
    for ip in in_arp_table[0]:
        # Check if IP address is new
        if ip not in arp_table[0]:
            message = "New Entry: IP_Address: " + ip + " MAC_Address: " + arp_table[0][ip] + " on Interface: " + arp_table[1][ip]
            report_log(message)
        # Check if MAC address changes
        if in_arp_table[0][ip] != arp_table[0][ip]:
            message ="Mac Address Change: IP_Address: " + ip + " Old MAC_Address: " + ip_arp_table[0][ip] + " New MAC_Address: " + arp_table[0][ip] + " on interface: " + arp_table[1][ip]
            report_log(message)
        # Check if interface changed
        if in_arp_table[1][ip] != arp_table[1][ip]:
            message ="Interface Change: IP_Address: " + ip + " MAC_Address: " + arp_table[0][ip] + " on Interface " + arp_table[1][ip]
            report_log(message)
    
    return arp_table

def check_active(address_list,in_arp_table=None):
    '''Actively scan, using arp-scan, TODO'''
    message = "Active Scan, not implemented yet!"
    report_log(message)
    return [{},{}]

def main_loop(address_list):
    '''Where the action is'''
    if address_list != []:
        message = "Staring up. checking " + " ".join(address_list) + " in the ARP Table"
    else:
        message = "Staring up. Watching Everything in the ARP Table"
    report_log(message)
    
    # Setup arp table. This file only exists while program is running
    arp_table_dir = os.path.dirname(options['arp_table'])
    if os.path.exists(arp_table_dir) == False:
        os.mkdir(arp_table_dir)

    # touch test file
    arp_table_file = open(options['arp_table'],'w')
    arp_table_file.close()
    
    # initialize ARP table
    arp_table = check_passive(address_list)
    
    while True:
        # rotate arp tables
        old_arp_table = arp_table
        # Passive check
        arp_table = check_passive(address_list,old_arp_table)
        
        # Active Check
        if options['activescan'] == True:
            active_arp_table = active_scan()
            arp_table[0].update(active_arp_table[0])
            arp_table[1].update(active_arp_table[1])
        
        ## Write ARP table
        # Generate arp-table output
        output         = ""
        for ip in arp_table[0]:
            # ip address, mac address, and interface respectively from the arp table, and a new line
            line    = ip + "\t" + arp_table[0][ip] + "\t" + arp_table[1][ip] + "\n"
            output += line
        # Now write it
        arp_table_file = open(options['arp_table'],'w')
        arp_table_file.write(output)
        arp_table_file.close()
        
        time.sleep(options['check_int'])

def cleanup_and_exit(exit_code,frame):
    '''Stop program and shut down'''
    report_log("Shutting Down")
    os.remove(options['arp_table'])
    sys.exit(exit_code)

def main():
    '''main program'''
    parser = argparse.ArgumentParser(description=prog_desc,epilog="\n\n",add_help=False,formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("ip_addr", nargs="*"   , help="Optional: IP addresses to monitor.")
    parser.add_argument("-?", "--help"         , help="Show This Help Message", action="help")
    parser.add_argument("-a", "--active-scan"  , help="Actively scan with arp-scan",action="store_true")
    parser.add_argument("-l", "--log-file"     , help="Path and filename of Logfile",type=str)
    
    # parse yargs.
    args = parser.parse_args()
    # update ye options
    if args.active_scan == True:
        options['activescan'] = True
    if args.log_file != None:
        options['logfile'] = args.log_file
    
    #check if we are running as root
    if os.getuid() != 0:
        exit_with_error(2,"Not root! This program needs to be run as root! see --help for options.")
    # graceful shutdown on interrupts
    signal.signal(signal.SIGINT,cleanup_and_exit)
    signal.signal(signal.SIGTERM,cleanup_and_exit)
    
    main_loop(args.ip_addr)
    
    # When we are done
    cleanup_and_exit(0,None)

if __name__ == "__main__":
    main()
