#!/bin/bash

usage="$(basename $0) [FROM=TODAY] [TO=TODAY] [OPTIONS]

Report on chore burndown between the specified dates.
Arguments:
    FROM        The lower bound date from which to show completed and remaining chores.
    TO          The upper bound date to which to show completed and remaining chores.

Options:
    -h, --help  Show this help message and exit.
    --preview   Show the SQL command but do not execute.
    --to=TO     The upper bound date to which to show completed and remaining chores.
    --verbose   Show SQL commands as they are executed."

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
	elif [[ $arg == "--to" ]]
	then
		echo "The --to flag must have an argument."
		echo "$usage"
		exit 1
	elif [[ $arg == --to=* ]]
	then
		to=$(echo $arg|cut -d= -f2)
		to=${to//\'/\\\'}
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
if [[ $to == "" ]]
then
	if [[ ${#arguments[@]} -lt 2 ]]
	then
		to=$(date --iso-8601)
	else
		to=${arguments[1]//\'/\\\'}
	fi
fi

# Invoke SQL
sql="CALL chore_burndown('$from', '$to')"
chore-database "$sql" ${options[@]}
