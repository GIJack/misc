#!/usr/bin/env python3
# ToxDNS lookup script, requires python3, and python-dns(
# http://www.dnspython.org/)
# Use as tox_dig user@example.com
# Written by GI_Jack <iamjacksemail@hackermail.com>
# Licensed under the GPLv3 or any later version
# https://www.gnu.org/copyleft/gpl.html
# Except the TOX development team, which is explicitly and exclusively given the
# "WTFPL – Do What the Fuck You Want to Public License" http://www.wtfpl.net/

#exits 0 for success, 1 for error, 2 for help

def get_ToxID(address):
    '''input a ToxDNS address, get back a ToxID'''
    try:
        import dns.resolver
    except:
        return(-1,"cannot load python dns module, please check if it is installed.")
    try:
        user,domain = address.split('@')
    except:
        return(-1,address+" is not a valid ToxDNS name, format is user@example.com")
    try:
        rawdata = str(dns.resolver.query(user+'._tox.'+domain,'txt')[0])
    except dns.resolver.NXDOMAIN:
        return(-1,address+" does not have a ToxID associated with it")
    except:
        return(-1,"python dns gave a non-specific failure")
    rawdata = rawdata.strip('"')
    # splitting the dns return into segments, version comes first[0], in all
    # versions    
    toxver = rawdata.split(';')[0]
    if   toxver == "v=tox1":
        outdata = _tox1(rawdata)
    elif toxver == "v=toxv":
        outdata = _tox2(rawdata)
    elif toxver == "v=tox3":
        outdata = _tox3(rawdata)
    else:
        return(-1,"DNS returned invalid data: "+address)

    return outdata

def _tox1(record):
    '''Lookup a ToxDNS version1 Record '''
    # ToxID is the second entry on version one records, it should be identified
    # by id=
    try:
        toxid = record.split(';')[1]
    except:
        return(-1,"Cannot get address from record: "+address)

    if toxid.find("id=") == 0 :
        toxid = toxid.rstrip('\\')
        toxid = toxid.lstrip('id=')
    else:
        return(-1,"DNS returned invalid data: "+address)

    return toxid

def _tox2(record):
    return(-2,"not implemented")

def _tox3(record):
    return(-2,"not implemented")

def tox_dig_help():
    import sys
    print('''tox_dig: small Python script that returns a ToxID from ToxDNS using the standard unix dig command
	USAGE: tox_dig userid@toxdomain, EXAMPLE: tox_dig test@toxme.se'''
)
    sys.exit(2)

#main program is now a function
def main():
    import sys
    #get input, if there run with no arguments display help
    script_name = sys.argv[0].lower()
    try:
        address = sys.argv[1].lower()
    except:
        tox_dig_help()

    #HALP! if someone requests help, display help intead lookup
    if address == "help":
        tox_dig_help()

    output = get_ToxID(address)

    # If there is an error from the function it will return a tupple with the
    # first element[0] being -1 and the second element [1] being the error
    # message
    if output[0] == -1:
        print("tox_dig: Error",output[1])
        sys.exit(1)
    elif output[0] == -2:
        tox_dig_help()
    else:
        #we have data and no errors, output to user
        print(address+" "+output)

if __name__ == "__main__":
    main()
