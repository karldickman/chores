SET @sunday_midnight = '2018-10-22 00:00:00';
SET @saturday = DATE_ADD(@sunday, INTERVAL -2 DAY);
WITH time_remaining_by_chore AS (SELECT chore_id
		, chore_completion_id
        , due_date
        , FALSE AS is_completed
        , last_completed
        , avg_duration_minutes AS duration_minutes
        , completed_minutes
        , remaining_minutes
        , stdev_duration_minutes
        , `90% CI UB`
	FROM incomplete_chores
    NATURAL JOIN chore_durations
    WHERE due_date < @sunday_midnight
UNION
SELECT chore_id
		, chore_completion_id
        , due_date
        , TRUE AS is_completed
        , chore_completion_status_since AS last_completed
        , avg_duration_minutes AS duration_minutes
        , avg_duration_minutes AS completed_minutes
        , 0 AS remaining_minutes
        , 0 AS stdev_duration_minutes
        , 0 AS `90% CI UB`
	FROM chore_completions
    NATURAL JOIN chore_schedule
    NATURAL JOIN chore_durations
    WHERE chore_completion_status_id IN (3, 4) # completed
		AND chore_completion_status_since BETWEEN @saturday AND @sunday_midnight)
SELECT chore
		, due_date
        , frequency = 7 AND frequency_unit_id = 1 /*Days*/ AS weekly
        , duration_minutes
        , completed_minutes
        , remaining_minutes
        , stdev_duration_minutes
        , `90% CI UB`
	FROM time_remaining_by_chore
    NATURAL JOIN chores
    LEFT OUTER JOIN chore_frequencies
		ON time_remaining_by_chore.chore_id = chore_frequencies.chore_id
	WHERE chore_completion_id NOT IN (SELECT chore_completion_id
			FROM do_not_show_in_overdue_chores)
	ORDER BY weekly DESC, is_completed, remaining_minutes DESC, duration_minutes