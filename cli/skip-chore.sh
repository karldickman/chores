#!/bin/bash

usage="$(basename "$0") CHORE [CHORE] [OPTIONS]

Record a chore completion.
Arguments:
    CHORE          The name of the chore skipped.
Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    -q, --quiet    Suppress output.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
a=0
o=0
for arg in "$@"
do
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	elif [[ $arg != -* ]]
	then
		arguments[$a]=$arg
		((a++))
	else
		options[$o]=$arg
		((o++))
	fi
done

# Process arguments
if [[ ${#arguments[@]} -lt 1 ]]
then
	echo "Missing required argument CHORE."
	echo "$usage"
	exit 1
fi
for chore in "${arguments[@]}"
do
	chore=${chore//\'/\\\'}
	sql="CALL skip_chore('$chore', @c, @n)"
	chore-database "$sql" ${options[@]}
done
