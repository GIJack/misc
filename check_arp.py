#!/usr/bin/env python
import sys
import subprocess
import time
import signal

#config
class config:
    daemon         = False
    logfile        = "passive_arp.log"
    check_interval = .333
global config
##end config

address_list   = sys.argv[1:]
global progname
progname       = sys.argv[0]
collisions_previous = {}
global errors
errors         = 0

def check_passive(collisions_previous,address_list):
    '''This function checks and returns a dictionary of collisions to the user'''
    collisions = {}
    for address in address_list:
        maclist = []
        try:
            rawinput = str(subprocess.check_output(["arp","-na", address])).split('\\n?')
        except:
            errors += 1
            continue
        for line in rawinput:
            maclist.append( line.split()[3] )
        if len(maclist) > 1:
            collisions[address] = maclist
            if address not in collisions_previous:
                print(maclist)
                report_collision(address,maclist)
    return collisions

def report_collision(address,maclist):
    '''This function outputs to either console, or log, depending on config'''
    line = time.asctime() + " " + progname +": Collision of " + address + " between " + " ".join(maclist) 
    print(line)
    if config.daemon == True:
        outfile = open(config.logfile,"a")
        outfile.write(line)
        
def report_log(textString):
    '''This function either prints to console, log or both'''
    line = time.asctime() + progname + ": " + textString
    print(line)
    if config.daemon == True:
        outfile = open(config.logfile,"a")
        outfile.write(line)

def _start(address_list):
    report_log("Staring up checking "+" ".join(address_list)+" for IP collisions")
    while True:
        collisions = check_passive(collisions_previous,address_list)
        for line in collisions:
            if line not in collisions_previous:
                collisions_previous[line] = collisions[line]
        time.sleep(config.check_interval)

def _stop(exit_code,frame):
    report_log("shutting down")
    sys.exit(exit_code)

def main():
    if len(sys.argv) < 2:
        report_log("You need at least one IP to check")
        _stop(1,None)
    signal.signal(signal.SIGINT,_stop)
    _start(address_list)

if __name__ == "__main__":
    main()
