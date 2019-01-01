#!/bin/bash

usage="$(basename "$0") [WHEN_COMPLETED] [OPTIONS]

Record a chore completion.
Arguments:
    WHEN_COMPLETED           (Optional) When the chore was completed in
                             YYYY-MM-DD HH:MM:SS format.
Options:
    --dishwasher             The time spent emptying the drainer in MM:SS.SS
                             format.
    --drainer                The time spent emptying the drainer in MM:SS.SS
                             format.
    -h, --help               Show this help text and exit.
    --preview                Show the SQL command to be executed.
    -v, --verbose            Show SQL commands as they are executed."

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
	if [[ $arg == --dishwasher* ]]
	then
		dishwasher=$(echo $arg | cut -d= -f2)
	fi
	if [[ $arg == --drainer* ]]
	then
		drainer=$(echo $arg | cut -d= -f2)
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

# Duration
if [[ $dishwasher != "" ]]
then
	dishwasher_minutes=$(hms2dec $dishwasher)
else
	dishwasher_minutes="NULL"
fi
if [[ $drainer != "" ]]
then
	drainer_minutes=$(hms2dec $drainer)
else
	drainer_minutes="NULL"
fi
# When completed
when_completed=${arguments[0]//\'/\\\'}
if [[ "$when_completed" == "" ]]
then
	when_completed=$(date "+%F %H:%M:%S")
fi
sql="CALL put_away_dishes('$when_completed', $drainer_minutes, $dishwasher_minutes, @c, @n)"

# Invoke SQL
if [[ $verbose -eq 1 ]]
then
	echo "$sql"
fi
if [[ $execute -eq 1 ]]
then
	mysql --login-path=chores chores -e "$sql"
fi
