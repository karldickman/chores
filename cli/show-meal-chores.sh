#!/bin/bash

usage="$(basename "$0") [OPTIONS]

Show overdue meal chores and exit.
Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    --skip-totals  Do not show a total row in the output table.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
o=0
show_totals="TRUE"
for arg in "$@"
do
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	elif [[ $arg == "-q" ]] || [[ $arg == "--quiet" ]]
	then
		echo "The --quiet flag is not supported."
		echo "$usage"
		exit
	elif [[ $arg == "--skip-totals" ]]
	then
		show_totals="FALSE";
	else
		options[$o]=$arg
		((o++))
	fi
done

date=$(date "+%F")
sql="CALL show_meal_chores('$date', $show_totals)"

# Invoke SQL
chore-database "$sql" ${options[@]} --silent=false --skip-column-names=false
if [[ $? -ne 0 ]]
then
	echo "$usage"
	exit $?
fi
