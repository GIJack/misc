#!/usr/bin/env python3

import dns.reversename

#read the file
inFile    = open("traces.geoip","r")
fileLines = str(inFile.read())
inFile.close()
fileLines =  fileLines.split('\n')

filterLines = []
DNSdict = {}        

#get lines that have locations
for line in fileLines:
    try:
        line = line.split(',')
        line[0] = line[0].strip('GeoIP City Edition')
        line[1] = line[1].strip('Rev 1: ')
        if 'N/A' not in line[2]:
            filterLines.append(line)
    except:
        continue
    #now try DNS lookups:
    #try:
    try:
        addr = dns.reversename.from_address( line[0] )
        if "in-addr.arpa" not in addr.to_text():
            DNSdict[line[0]] = addr.to_text()
    except:
        continue

#now output
print("IP Address" + "\t".expandtabs(6) + "Hostname" + "\t".expandtabs(25) + "Location")
print("-------------------------------------------------------------------------------")
for line in filterLines:
    #start with the IP address and a tab
    output = line[0] + "\t".expandtabs(16 - len(line[0]))
    
    #next is hostname
    if line[0] in DNSdict:
        output += DNSdict[line[0]]
        dnslen = len(DNSdict[line[0]])
    else:
        output += "unresolved"
        dnslen = 10
    output += "\t".expandtabs(32 - dnslen)

    #third we print whatever location information is available.
    if line[1] == "US":
        if "N/A" not in line[3]:
            output +=        line[3]
        if "N/A" not in line[2]:
            output += ", " + line[2]
        if "N/A" not in line[4] :
            output += " "  + line[4]
    else:
        if "N/A" not in line[3]:
            output += line[3]

    output += ", " + line[1]
    print(output)
    
print("----------")
print("Total IPs: " + str( len(filterLines) ) )
