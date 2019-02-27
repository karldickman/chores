#!/bin/bash

usage="$(basename "$0") CHORE [OPTIONS]

Show history of a chore.
Arguments:
    CHORE          The name of the chore whose history to show.

Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
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
	elif [[ $arg == "-q" ]] || [[ $arg == "--quiet" ]]
	then
		echo "--quiet flag is not supported."
		echo "$usage"
		exit 1
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
elif [[ ${#arguments[@]} -gt 1 ]]
then
	echo "Too many arguments."
	echo "$usage"
	exit 1
fi

chore=${arguments[0]//\'/\\\'}

chore-database "CALL show_chore_history('$chore')" ${options[@]} --column-names --silent=false
