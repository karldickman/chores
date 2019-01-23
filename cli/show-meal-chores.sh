#!/bin/bash

usage="$(basename "$0") [OPTIONS]

Show overdue meal chores and exit.
Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
i=0
execute=1
verbose=0
for arg in "$@"
do
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	elif [[ $arg == "--preview" ]]
	then
		execute=0
		verbose=1
	elif [[ $arg == "-v" ]] || [[ $arg == "--verbose" ]]
	then
		verbose=1
	fi
done

date=$(date "+%F")
sql="CALL show_meal_chores('$date')"

# Invoke SQL
if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	mysql --login-path=chores chores -e "$sql"
fi
