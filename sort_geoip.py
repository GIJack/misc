#!/usr/bin/env python3
# sort abritrary geoip output into usable output. Dirty nasty procedural hack.
# perhaps one day I'll clean this up into functions
# FreeBSD licensed

import socket

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
    try:
        addr = socket.gethostbyaddr(line[0])
        DNSdict[line[0]] = addr[0]
    except:
        continue

#sort by city
filterLines = sorted(filterLines, key=lambda filterLines: filterLines[3])
#sort by state
filterLines = sorted(filterLines, key=lambda filterLines: filterLines[2])
#sort by country
filterLines = sorted(filterLines, key=lambda filterLines: filterLines[1])

#CSV list

cities = set({})
outlines = []
for line in filterLines:
    outlines.append( [ line[0] , line[3], line[2], line[4], line[1] ] )
    cities.add(line[3])
    #print( line[0] + ', ' + line[3] + ', ' + line[2] + ', ' + line[4] + ', ' + line[1] )
  
for city in cities:
    count = 3
    for line in outlines:
        if line[1] == city and count > 0:
            print(line[0] + ", " + line[1] + ", " + line[2] + ", " + line[3] + ", " + line[4] )
            count -= 1
#now output
#print("IP Address" + "\t".expandtabs(6) + "Hostname" + "\t".expandtabs(33) + "Location")
#print("-------------------------------------------------------------------------------")
#for line in filterLines:
#    #start with the IP address and a tab
#    output = line[0] + "\t".expandtabs(16 - len(line[0]))
#    
#    #next is hostname
#    if line[0] in DNSdict:
#        output += DNSdict[line[0]]
#        dnslen = len(DNSdict[line[0]])
#    else:
#        output += "unresolved"
#        dnslen = 10
#    output += "\t".expandtabs(40 - dnslen)
#
#    #third we print whatever location information is available.
#    if line[1] == "US":
#        #city
#        if "N/A" not in line[3]:
#            output +=        line[3]
#        #state
#        if "N/A" not in line[2]:
#            output += ", " + line[2]
#        #zipcode
#        if "N/A" not in line[4] :
#            output += " "  + line[4]
#    else:
#        #line[3] is city.
#        if "N/A" not in line[3]:
#            output += line[3]
#    #line[1] is country
#    output += ", " + line[1]
#    print(output)
    
#print("----------")
#print("Total IPs: " + str( len(filterLines) ) )
