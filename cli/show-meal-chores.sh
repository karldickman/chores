#!/bin/bash

usage="$(basename "$0") [OPTIONS]

Show overdue meal chores and exit.
Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
for arg in "$@"
do
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	fi
done

date=$(date "+%F")
sql="CALL show_meal_chores('$date', TRUE)"

# Invoke SQL
chore-database "$sql" ${options[@]} --silent=false --skip-column-names=false
