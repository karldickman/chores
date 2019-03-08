#!/bin/bash

usage="$(basename $0) FROM [TO] [OPTIONS]

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

if [[ ${#arguments[@]} -eq 0 ]]
then
	from=$(date --iso-8601)
else
	from=${arguments[0]//\'/\\\'}
fi
if [[ ${#arguments[@]} -lt 2 ]]
then
	to=$(date --iso-8601)
else
	to=${arguments[1]//\'/\\\'}
fi

# Invoke SQL
sql="CALL chores_completed_and_remaining('$from', '$to')"
chore-database "$sql" ${options[@]}
