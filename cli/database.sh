#!/bin/bash

usage="$(basename "$0") SQL_COMMAND [SQL_COMMAND...] [OPTIONS]

Execute one or more SQL commands in the chores database.
Arguments:
    SQL_COMMAND     SQL command to be excuted.

Options:
    --column-names  Write column names in results.
    -h, --help      Show this help text and exit.
    --line-numbers  Write line numbers for errors.
    --preview       Show the SQL command but do not execute.
    -q, --quiet     Suppress output.
    --silent        Boolean.  Indicates whether --silent flag should be passed to mysql command.
    -v, --verbose   Show SQL commands as they are executed."

# Process arguments
i=0
execute=1
mysql_column_names="--skip-column-names"
mysql_line_numbers="--skip-line-numbers"
mysql_silent="--silent"
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
	elif [[ $arg == "--column-names" ]]
	then
		mysql_column_names=$arg
	elif [[ $arg == "--line-numbers" ]]
	then
		mysql_line_numbers=$arg
	elif [[ ${arg,,} == --silent=false ]]
	then
		mysql_silent=""
	else
		echo "Unknown option $arg."
		exit 3
	fi
done

if [[ ${#commands[@]} -eq 0 ]]
then
	echo "Missing required argument SQL_COMMAND."
	echo "$usage"
	exit 3
fi

for sql in "${commands[@]}"
do
	if [[ $verbosity -eq 2 ]]
	then
		echo "$sql"
	fi
	if [[ $execute -eq 1 ]]
	then
		if [[ $verbosity -gt 0 ]] && [[ $sql == *@c* ]]
		then
			sql="$sql;SELECT @c"
		fi
		mysql --login-path=chores chores -e "$sql" $mysql_column_names $mysql_line_numbers $mysql_silent
	fi
done
