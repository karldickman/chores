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
parse_options=1
show_totals="TRUE"
for arg in "$@"
do
	if [[ $parse_options -eq 0 ]] || [[ $arg != -* ]] || [[ $arg == "--" ]]
	then
		arguments[$a]=$arg
		((a++))
		if [[ $arg == "--" ]]
		then
			parse_options=0
		fi
	elif [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
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
	elif [[ $arg == -* ]]
	then
		echo "$0: invalid option -- '$arg'"
		echo "$usage"
		exit 1
	else
		options[$o]=$arg
		((o++))
	fi
done

if [[ ${#arguments} -gt 0 ]] && [[ ${arguments[0]} != "--" ]]
then
	date=${arguments[0]//\'/\\\'}
	remaining_arguments=${arguments[@]:1}
else
	date=$(date "+%F")
	remaining_arguments=${arguments[@]}
fi
sql="CALL show_meal_chores('$date', $show_totals)"

# Invoke SQL
chore-database "$sql" ${options[@]} ${remaining_arguments[@]} --column-names --silent=false
exit_status=$?
if [[ exit_status -eq 3 ]]
then
	echo "$usage"
fi
exit $exit_status
