#!/bin/bash

usage="$(basename "$0") SQL_COMMAND [SQL_COMMAND...] [OPTIONS]

Execute one or more SQL commands in the chores database.
Arguments:
    SQL_COMMAND    SQL command to be excuted.

Options:
    -h, --help     Show this help text and exit.
    --preview      Show the SQL command but do not execute.
    -q, --quiet    Suppress output.
    -v, --verbose  Show SQL commands as they are executed."

# Process arguments
i=0
execute=1
verbosity=1
for arg in "$@"
do
	if [[ $arg == "-h" ]] || [[ $arg == "--help" ]]
	then
		echo "$usage"
		exit
	elif [[ $arg != -* ]]
	then
		commands[$i]=$arg
		((i++))
	elif [[ $arg == "--preview" ]]
	then
		execute=0
		verbosity=2
	elif [[ $arg == "-q" ]] || [[ $arg == "--quiet" ]]
	then
		if [[ $verbosity -eq 2 ]]
		then
			echo "--verbose and --quiet cannot be used together."
			echo "$usage"
			exit 1
		fi
		verbosity=0
	elif [[ $arg == "-v" ]] || [[ $arg == "--verbose" ]]
	then
		if [[ $verbosity -eq 0 ]]
		then
			echo "--verbose and --quiet cannot be used together."
			echo "$usage"
			exit 1
		fi
		verbosity=2
	else
		echo "Unknown option $arg."
		echo "$usage"
		exit 1
	fi
done

for sql in "${commands[@]}"
do
	if [[ $verbosity -eq 2 ]]
	then
		echo "$sql"
	fi
	if [[ $execute -eq 1 ]]
	then
		if [[ $verbosity -gt 0 ]]
		then
			sql="$sql;SELECT @c"
		fi
		mysql --login-path=chores chores -e "$sql" --silent --skip-column-names
	fi
done
