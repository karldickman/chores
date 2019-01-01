#!/bin/bash

usage="$(basename "$0") CHORE [OPTIONS]

Record a chore completion.
Arguments:
    CHORE          The name of the chore completed.
Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command to be executed.
    -q, --quiet    Suppress output.
    -v, --verbose  Show SQL commands as they are executed."

# Process options
i=0
execute=1
quiet=0
verbose=0
for arg in "$@"
do
	if [[ $arg != -* ]]
	then
		arguments[$i]=$arg
		((i++))
	fi
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	fi
	if [[ $arg == "--preview" ]]
	then
		execute=0
		verbose=1
	fi
	if [[ $arg == "-q" ]] || [[ $arg == "--quiet" ]]
	then
		quiet=1
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
chore=${arguments[0]//\'/\\\'}

# Invoke SQL
sql="CALL skip_chore('$chore', @c, @n)"


if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	if [[ $quiet -eq 0 ]]
	then
		sql="$sql;SELECT @c;"
	fi
	mysql chores -u chores -pM2TEncult7v3TrC90SUs -e "$sql" --silent --skip-column-names
fi
