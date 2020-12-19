#!/bin/bash

usage="$(basename "$0") CHORE [DURATION] [WHEN_COMPLETED] [OPTIONS]

Record a chore completion.
Arguments:
    CHORE           The name of the chore completed.
    DURATION        How long it took to complete the chore in MM:SS.SS format.
    WHEN_COMPLETED  When the chore was completed in YYYY-MM-DD HH:MM:SS format.
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
if [[ ${#arguments[@]} -eq 1 ]]
then
	sql="CALL complete_chore('$chore', NULL, NULL, @c, @n)"
else
	# Duration
	time_components=(${arguments[1]//:/ })
	minutes=${time_components[0]}
	seconds=${time_components[1]}
	if [[ "$seconds" == "" ]]
	then
		seconds=0
	fi
	duration_minutes=$(echo "$minutes + $seconds / 60" | bc -l)
	# When completed
	when_completed=${arguments[2]//\'/\\\'}
	if [[ "$when_completed" == "" ]]
	then
		when_completed=$(date "+%F %H:%M:%S")
	fi
	procedure="complete_chore"
	if [[ $unscheduled -eq 1 ]]
	then
		procedure="complete_unscheduled_chore"
	fi
	sql="CALL $procedure('$chore', '$when_completed', $duration_minutes, @c, @n)"
fi

# Invoke SQL
chore-database "$sql" ${options[@]}
