#!/bin/bash

usage="$(basename "$0") [OPTIONS]

Show the number of minutes spent doing chores today.

Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
o=0
for arg in "$@"
do
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	elif [[ $arg != -* ]]
	then
		echo "This script does not support arguments."
		echo "$usage"
		exit 1
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

# Invoke SQL
sql="CALL chore_duration_today()"
chore-database "$sql" ${options[@]}
