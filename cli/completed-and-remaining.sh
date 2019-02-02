#!/bin/bash

usage="$(basename $0) FROM TO [OPTIONS]

Arguments:
    FROM       The lower bound date from which to show completed and remaining chores.
    TO         The upper bound date to which to show completed and remaining chores.

Options:
    -h, --help Show this help message and exit.
    --preview  Show the SQL command but do not execute.
    --verbose  Show SQL commands as they are executed."

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
		echo "The --quiet flag is not supported.";
		echo "$usage"
		exit 1
	else
		options[$o]=$arg
		((o++))
	fi
done

# Process arguments
if [[ ${#arguments} -lt 2 ]]
then
	echo "Invalid number of arguments."
	echo "$usage"
	exit 1
fi

from=${arguments[0]//\'/\\\'}
to=${arguments[1]//\'/\\\'}

# Invoke SQL
sql="CALL chores_completed_and_remaining('$from', '$to')"
chore-database "$sql" ${options[@]} --column-names --silent=false
