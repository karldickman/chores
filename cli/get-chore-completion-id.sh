#!/bin/bash

usage="$(basename "$0") CHORE [OPTIONS]

Get the most recent completion identifier of the specified chore.
Arguments:
    CHORE          The name of the chore whose completion identifier to get.
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
	elif [[ $arg != -* ]]
	then
		arguments[$i]=$arg
		((i++))
	elif [[ $arg == "--preview" ]]
	then
		execute=0
		verbose=1
	elif [[ $arg == "-v" ]] || [[ $arg == "--verbose" ]]
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
chore=${arguments[0]//\'/\\\'}

# Invoke SQL
sql="CALL get_chore_completion('$chore', @c)"

if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	sql="$sql;SELECT @c;"
	mysql --login-path=chores chores -e "$sql" --silent --skip-column-names
fi
