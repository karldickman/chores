#!/bin/bash

usage="$(basename "$0") CHORE DURATION [WHEN_COMPLETED] [OPTIONS]

Record a chore session.
Arguments:
    CHORE           The name of the chore completed.
    DURATION        How long it took to complete the chore in MM:SS.SS
	                format.
    WHEN_COMPLETED  (Optional) When the chore was completed in
	                YYYY-MM-DD HH:MM:SS format.
Options:
    -h, --help      Show this help text and exit.
    --preview       Show the SQL command to be executed.
	-v, --verbose   Show SQL commands as they are executed."

# Process options
i=0
execute=1
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
	if [[ $arg == "-v" ]] || [[ $arg == "--verbose" ]]
	then
		verbose=1
	fi
done

# Process arguments
chore=${arguments[0]//\'/\\\'}
time_components=(${arguments[1]//:/ })
minutes=${time_components[0]}
seconds=${time_components[1]}
if [[ "$seconds" == "" ]]
then
	seconds=0
fi
duration_minutes=$(echo "$minutes + $seconds / 60" | bc -l)
when_completed=${arguments[2]//\'/\\\'}
if [[ "$when_completed" == "" ]]
then
	when_completed=$(date "+%F %H:%M:%S")
fi

# Invoke SQL
sql="CALL complete_chore_session('$chore', '$when_completed', $duration_minutes, @c, @n)"
if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	mysql chores -u chores -pM2TEncult7v3TrC90SUs -e "$sql"
fi