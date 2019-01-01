#!/bin/bash

usage="$(basename "$0") [HH:]MM:SS.SS [OPTIONS]

Convert HH:MM:SS to decimal minutes.
Options:
    -h, --help      Show this help text and exit."

# Process options
i=0
for arg in "$@"
do
	if [[ $arg != -* ]]
	then
		arguments[$i]=$arg
		((i++))
	fi
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	fi
done

if [[ $# -lt 1 ]]
then
	echo "$usage"
	exit 1
fi

time_components=(${1//:/ })
minutes=${time_components[0]}
seconds=${time_components[1]}
if [[ "$seconds" == "" ]]
then
	seconds=0
fi
echo "$minutes + $seconds / 60" | bc -l
