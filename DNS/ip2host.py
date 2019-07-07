#!/usr/bin/python3

import os
import re
import socket
import threading
import officeTasks as OT
from easyThread import EasyThread

def ourThread(self, ip):
    try:
        f = socket.gethostbyaddr(ip)
        hList.append((f[0], ip))
    except:
        hList.append(('N/A', ip))

## Prep
OT.gnr.sweep('output')
os.mkdir('output')
hList = []
ipList = []

## User choices
dList, tgtList = OT.gnr.fileMenu('txt')
print('\n' + dList)
fName = tgtList[int(input('File to parse?\n'))]

with open(fName, 'r') as iFile:
    fContents = iFile.read().splitlines()
ipSet = set()
ipCapture = re.compile('\\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b')
for i in fContents:
    f = re.findall(ipCapture, i)
    for ip in f:
        ipSet.add(ip)

for i in ipSet:
    data = '.'.join(i)
    ipList.append(data)

## Add our function to EasyThread
EasyThread.theThread = ourThread

## Instantiate using #s other than defaults
et = EasyThread(jobList = ipList, nThread = 15)

## Start the work
et.easyLaunch()

## Record your findings
OT.csv.csvGen('output/host2ip.csv', ['hostname', 'ip'], hList)
