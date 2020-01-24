#!/bin/bash

usage="$(basename "$0") DUE_DATE [OPTIONS]

Schedule all meal chores to be due on a particular date.
Arguments:
    DUE_DATE       When the chore is due in
                   YYYY-MM-DD format.
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
	echo "Missing required argument DUE_DATE."
	echo "$usage"
	exit 1
fi

due_date=${arguments[0]}

# Invoke SQL
chore-schedule "make breakfast" "$due_date" ${options[@]}
chore-schedule "make lunch" "$due_date" ${options[@]}
chore-schedule "make dinner" "$due_date" ${options[@]}
chore-schedule "breakfast dishes" "$due_date" ${options[@]}
chore-schedule "lunch dishes" "$due_date" ${options[@]}
chore-schedule "dinner dishes" "$due_date" ${options[@]}
