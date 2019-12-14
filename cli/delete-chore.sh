#!/bin/bash

usage="$(basename "$0") CHORE [OPTIONS]

Delete a chore completion.
Arguments:
    CHORE          The name of the chore completion to delete.

Options:
    -h, --help     Show this hep text and exit.
    --preview      Show the SQL command to be executed.
    --quiet        Suppress output.
    -v, --verbose  Show the SQL commands as they are excuted."

# Process options
a=0
o=0
execute=1
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
	elif [[ $arg == "--preview" ]]
	then
		execute=0
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

# Invoke SQL
if [[ $execute -eq 1 ]]
then
	chore_completion_id=$(chore-get-completion-id "$chore")
	sql="SET @c = $chore_completion_id;CALL delete_chore_completion($chore_completion_id)"
	chore-database "$sql" ${options[@]}
else
	chore-get-completion-id "$chore" --preview
	echo "CALL delete_chore_completion(@c)"
fi
