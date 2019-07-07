#!/usr/bin/python3

import csv
import os
import socket
import officeTasks as OT
from easyThread import EasyThread

def ourThread(self, host):
    try:
        ipAddress = socket.gethostbyname(host)
        hList.append((host, ipAddress))
    except:
        hList.append((host, 'N/A'))

## Prep
OT.gnr.sweep('output')
os.mkdir('output')
hList = []

## User choices
dList, tgtList = OT.gnr.fileMenu('txt')
print('\n' + dList)
fName = tgtList[int(input('File to parse?\n'))]

with open(fName, 'r') as iFile:
    fContents = list(set(iFile.read().splitlines()))

## Add our function to EasyThread
EasyThread.theThread = ourThread

## Instantiate using #s other than defaults
et = EasyThread(jobList = fContents, nThread = 15)

## Start the work
et.easyLaunch()

## Record your findings
OT.csv.csvGen('output/host2ip.csv', ['hostname', 'ip'], hList)
