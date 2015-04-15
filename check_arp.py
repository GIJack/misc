#!/usr/bin/env python
# This script checks certian IPs for collisions and mac address changes passively by watching the arp cache
# USAGE: ./check_arp.py <list of IPs to watch>
# Jack @ nyi.net, Licensed under the FreeBSD license https://www.freebsd.org/copyright/freebsd-license.html
import sys
import subprocess
import time

###########config#######################
global config                          #
class config:                          #
    uselog         = False             #
    logfile        = "passive_arp.log" #
    check_interval = .333              #
###########end config###################

address_list   = sys.argv[1:]
global progname
progname       = sys.argv[0]
collisions_previous = {}
global errors
errors         = 0
global mactable
mactable       = {}

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
        if "no match found" in str(rawinput):
            continue
        for line in rawinput:
            maclist.append( line.split()[3] )
        #If there is more than one mac address per IP, raise the alarm, we have a collision
        if len(maclist) > 1:
            collisions[address] = maclist
            if address not in collisions_previous:
                print(maclist)
                report_collision(address,maclist)

        #now check if the mac address has changed.
        try:
            if mactable[address] != maclist and address in mactable:
                repot_macchange( address, maclist, mactable[address] )
        except KeyError:
            if len(maclist) >= 1:
                report_log( "Added IP " +address+" with mac(s) " + " ".join(maclist) )

        #update the mactable with the new address
        mactable[address] = maclist
            
    return collisions

def check_active(collisions_previous,address_list):
    '''This function uses arp-scan to actively look for collisions'''
    collisions = {}
    for address in address_list:
        try:
            rawinput = str(subprocess.check_output(["arp-scan",address])).split('\\n')
        except:
            errors += 1
            continue
        for i in range(4):
            rawinput.pop()
        del(rawinput[0:2])
        maclist = []
        for line in rawinput:
            maclist.append( line.split('\\t')[1] )
        if len(maclist) > 1:
            collisions[address] = maclist
            if address not in collisions_previous:
                report_collision(address,maclist)
    return collisions


def check_active(collisions_previous,address_list):
    '''This function uses arp-scan to actively look for collisions'''
    

def report_collision(address,maclist):
    '''report a collision as it happens, output to either logfile or console'''
    line = time.asctime() + " " + progname +": Collision of " + address + " between " + " ".join(maclist) 
    print(line)
    if config.uselog == True:
        outfile = open(config.logfile,"a")
        outfile.write(line+"\n")
        outfile.close()
        
def report_macchange(address,newmac,oldmac):
    '''report a collision as it happens, output to either logfile or console'''
    line = time.asctime() +' '+ progname +": Mac Address for " + address + " changed from" + " ".join(oldmac) + " to " + " ".join(newmac)
    print(line)
    if config.uselog == True:
        outfile = open(config.logfile,"a")
        outfile.write(line+"\n")
        outfile.close()
        
def report_log(textString):
    '''print an abritrary string to the logs/console'''
    line = time.asctime() +' '+ progname + ": " + textString
    print(line)
    if config.uselog == True:
        outfile = open(config.logfile,"a")
        outfile.write(line+"\n")
        outfile.close()

def _start(address_list):
    '''Start listening for ARP collisions'''
    report_log("Staring up checking "+" ".join(address_list)+" for IP collisions")
    while True:
        collisions = check_passive(collisions_previous,address_list)
        for line in collisions:
            if line not in collisions_previous:
                collisions_previous[line] = collisions[line]
        time.sleep(config.check_interval)

def _stop(exit_code,frame):
    '''Stop program and shut down'''
    report_log("shutting down")
    sys.exit(exit_code)

def main():
    '''main program'''
    import signal
    if len(sys.argv) < 2:
        report_log("You need at least one IP to check")
        _stop(1,None)
    signal.signal(signal.SIGINT,_stop)
    signal.signal(signal.SIGTERM,_stop)
    _start(address_list)

if __name__ == "__main__":
    main()
