#!/usr/bin/env bash
## Filename: b64.sh
## A base64 bruteforce decoder

## Usage:
## Try the string from left to right: ./b64.sh <base64 encoded string>
## Try the string in reverse, and then run left to right: ./b64.sh <base64 encoded string> -r

## Reasoning for usage:
## Base64 is a block-based format in which every 4 bytes of
## encoded data translates into 3 bytes of decoded data.

## Show me why:
## echo "This is a test" | base64
## Resultant output is: VGhpcyBpcyBhIHRlc3QK
## echo "VGhpcyBpcyBhIHRlc3QK" | base64 -d
## Resultant output is: This is a test
## echo "124VGhpcyBpcyBhIHRlc3QK" | base64 -d
## Resultant output is: ×n\È\ÈH\base64: truncated base64 input

## Bug
## For whatever reason, short strings get screwed up with this
## Temporarily removing strings portion

eng--()
{
## Run through all possibilities from left to right
## Lop off one character on the left at a time
## This is how we see if padding was a factor
until [[ $inc -eq $orig_length ]]; do
##Squish
#	ans=$(echo ${x:$inc} | base64 -d | strings)
	ans=$(echo ${x:$inc} | base64 -d)
	echo "Attempt $count -- Index $inc" >> output
	echo -e "$ans\n" >> output
	let inc++
	let count++
done
}

## This will allow us to try things backwards
if [[ $2 = "-r" ]]; then
	x=$(echo $1 | rev)
else
	x=$1
fi

## Setup the environment
orig_length=$(echo $x | wc -m)
count=1
inc=0

eng-- 2>/dev/null
