#!/bin/bash

usage="$(basename "$0") [DUE_DATE] [OPTIONS]

Show overdue meal chores and exit.
Arguments:
    DUE_DATE       Show any chores whose due date is on or before this date.

Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    --skip-totals  Do not show a total row in the output table.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
a=0
o=0
show_totals="TRUE"
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

date=${arguments[0]//\'/\\\'}
if [[ "$date" == "" ]]
then
	date=$(date "+%F")
fi
sql="CALL show_meal_chores('$date', $show_totals)"

# Invoke SQL
chore-database "$sql" ${options[@]} --column-names --silent=false
exit_status=$?
if [[ exit_status -eq 3 ]]
then
	echo "$usage"
fi
exit $exit_status

