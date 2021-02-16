#!/bin/bash

usage="$(basename "$0") CHORE [WHEN_COMPLETED] [OPTIONS]

Record a chore completion of unknown duration.
Arguments:
    CHORE           The name of the chore completed.
    WHEN_COMPLETED  (Optional) When the chore was completed in
                    YYYY-MM-DD HH:MM:SS format.
Options:
    -h, --help      Show this help text and exit.
    --preview       Show the SQL command to be executed.
    -q, --quiet     Suppress output.
    --unscheduled   The completed chore was not scheduled.
    -v, --verbose   Show SQL commands as they are executed."

# Process options
a=0
o=0
unscheduled=0
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
	elif [[ $arg == "--unscheduled" ]]
	then
		unscheduled=1
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
when_completed=${arguments[1]//\'/\\\'}
if [[ "$when_completed" == "UNKNOWN" ]]
then
	when_completed="NULL"
else
	if [[ "$when_completed" == "" ]]
	then
		when_completed=$(date "+%F %H:%M:%S")
	fi
	when_completed="'$when_completed'"
fi
if [[ $unscheduled -eq 1 ]]
then
	sql="CALL create_chore_completion('$chore', @c); CALL record_chore_completed(@c, $when_completed, 3, FALSE);"
else
	sql="CALL complete_chore_without_data('$chore', $when_completed, @c, @n)"
fi

# Invoke SQL
chore-database "$sql" ${options[@]}
