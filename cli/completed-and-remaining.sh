#!/bin/bash

usage="$(basename $0) [FROM=TODAY] [TO=TODAY] [OPTIONS]

Of all the chores overdue as of FROM, shows the progress made as of TO.
Arguments:
  FROM        The lower bound date from which to show completed and remaining
              chores.
  TO          The upper bound date to which to show completed and remaining
              chores.

Options:
  -h, --help  Show this help message and exit.
  --preview   Show the SQL command but do not execute.
  --to=TO     The upper bound date to which to show completed and remaining
              chores.
  --verbose   Show SQL commands as they are executed."

# Process options
a=0
o=0
parse_options=1
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
		echo "The --quiet flag is not supported.";
		echo "$usage"
		exit 1
	elif [[ $arg == "--to" ]]
	then
		echo "The --to flag must have an argument."
		echo "$usage"
		exit 1
	elif [[ $arg == --to=* ]]
	then
		to=$(echo $arg|cut -d= -f2)
		to=${to//\'/\\\'}
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

if [[ ${#arguments[@]} -eq 0 ]]
then
	from="NULL"
else
	from="'${arguments[0]//\'/\\\'}'"
fi
if [[ ${#arguments[@]} -lt 2 ]]
then
	to="NULL"
else
	to="'${arguments[1]//\'/\\\'}'"
	remaining_arguments=${arguments[@]:2}
fi

# Invoke SQL
sql="CALL chores_completed_and_remaining($from, $to)"
chore-database "$sql" ${options[@]} ${remaining_arguments[@]} --column-names --silent=false
