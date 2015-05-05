#!/usr/bin/env python3

#read the file
inFile    = open("traces.geoip","r")
fileLines = str(inFile.read())
inFile.close()
fileLines =  fileLines.split('\n')

filterLines = []

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

#now output
print("IP Address" + "\t".expandtabs(16) + "Location")

for line in filterLines:
    output = line[0] + "\t".expandtabs(16 - len(line[0]))
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
print("Total IPs: " + str(len(filterLines)) )
