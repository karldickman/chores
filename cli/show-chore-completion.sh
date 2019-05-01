#!/bin/bash

usage="$(basename "$0") CHORE_COMPLETION_ID [OPTIONS]

Show chore completion information.
Arguments:
	CHORE_COMPLETION_ID  The database identifier of the chore completion to show.

Options:
    -h, --help           Show this help text and exit.
    -I, --interactive    Accept chore completion id interactively.
    --preview            Show the SQL command to be executed.
    -v, --verbose        Show SQL commands as they are executed."

# Process options
a=0
o=0
interactive=0
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
	elif [[ $arg == "-I" ]] || [[ $arg == "--interactive" ]]
	then
		interactive=1
	elif [[ $arg == "-q" ]] || [[ $arg == "--quiet" ]]
	then
		echo "The --quiet flag is not supported."
		echo "$usage"
		exit
	else
		options[$o]=$arg
		((o++))
	fi
done

if [[ $interactive -eq 1 ]]
then
	read chore_completion_id
elif [[ ${#arguments[@]} -lt 1 ]]
then
	echo "Missing required argument CHORE_COMPLETION_ID"
	echo "$usage"
	exit 1
else
	chore_completion_id=${arguments[0]}
fi
sql="CALL show_chore_completion($chore_completion_id)"

# Invoke SQL
chore-database "$sql" ${options[@]} --column-names --silent=false
exit_status=$?
if [[ $exit_status -eq 3 ]]
then
	echo "$usage"
fi
exit $exit_status
