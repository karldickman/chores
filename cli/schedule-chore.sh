#!/bin/bash

usage="$(basename "$0") CHORE [DUE_DATE] [OPTIONS]

Schedule a chore to be due on a particular date.
Arguments:
    CHORE          The name of the chore completed.
    DUE_DATE       When the chore is due in YYYY-MM-DD format; today if
                   unspecified.

Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    -q, --quiet    Suppress output.
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
fi
chore=${arguments[0]//\'/\\\'}
if [[ ${#arguments[@]} -lt 2 ]]
then
	due_date=$(date --iso)
else
	due_date=${arguments[1]//\'/\\\'}
fi

sql="CALL schedule_chore('$chore', '$due_date', @c)"

# Invoke SQL
chore-database "$sql" ${options[@]}
