#!/bin/bash

usage="$(basename "$0") CHORE [DURATION] [WHEN_COMPLETED] [OPTIONS]

Record a chore completion.
Arguments:
    CHORE                    The name of the chore completed.
    DURATION                 How long it took to complete the chore in MM:SS.SS
                             format.
    WHEN_COMPLETED           (Optional) When the chore was completed in
                             YYYY-MM-DD HH:MM:SS format.
Options:
    -h, --help               Show this help text and exit.
    --incomplete-data        Data on the chore completion is not complete.
    --preview                Show the SQL command to be executed.
    -v, --verbose            Show SQL commands as they are executed.
    --when-completed-unkown  Not known when the chore was completed."

# Process options
i=0
execute=1
verbose=0
incomplete_data=0
when_completed_known=1
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
	if [[ $arg == "--incomplete-data" ]]
	then
		incomplete_data=1
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
	if [[ $arg == "--when-completed-unknown" ]]
	then
		when_completed_known=0
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
if [[ $incomplete_data -eq 1 ]]
then
	if [[ $when_completed_known -eq 0 ]]
	then
		sql="CALL complete_chore_without_data('$chore', NULL, @c, @n)"
	else
		when_completed=${arguments[1]//\'/\\\'}
		if [[ "$when_completed" == "" ]]
		then
			when_completed=$(date "+%F %H:%M:%S")
		fi
		sql="CALL complete_chore_without_data('$chore', '$when_completed', @c, @n)"
	fi
elif [[ ${#arguments[@]} -eq 1 ]]
then
	sql="CALL complete_chore('$chore', NULL, NULL, @c, @n)"
else
	if [[ ${#arguments[@]} -lt 2 ]]
	then
		echo "Missing required argument DURATION_MINUTES."
		echo "$usage"
		exit 1
	fi
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
	sql="CALL complete_chore('$chore', '$when_completed', $duration_minutes, @c, @n)"
fi

# Invoke SQL
if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	mysql chores -u chores -pM2TEncult7v3TrC90SUs -e "$sql"
fi
