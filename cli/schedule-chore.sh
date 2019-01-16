#!/bin/bash

usage="$(basename "$0") CHORE DUE_DATE [OPTIONS]

Schedule a chore to be due on a particular date.
Arguments:
    CHORE          The name of the chore completed.
    DUE_DATE       When the chore is due in
                   YYYY-MM-DD format.
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
	fi
	if [[ $arg != -* ]]
	then
		arguments[$i]=$arg
		((i++))
	fi
	if [[ $arg == "--preview" ]]
	then
		execute=0
		verbose=1
	fi
	if [[ $arg == "-v" ]] || [[ $arg == "--verbose" ]]
	then
		verbose=1
	fi
done

# Process arguments
if [[ ${#arguments[@]} -lt 1 ]]
then
	echo "Missing required argument CHORE."
	echo "$usage"
	exit 1
fi
if [[ ${#arguments[@]} -lt 2 ]]
then
	echo "Missing required argument DUE_DATE."
	echo "$usage"
	exit 1
fi

chore=${arguments[0]//\'/\\\'}
due_date=${arguments[1]//\'/\\\'}
sql="CALL schedule_chore('$chore', '$due_date', @c)"

# Invoke SQL
if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	mysql --login-path=chores chores -e "$sql"
fi
