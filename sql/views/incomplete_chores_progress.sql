ALTER VIEW incomplete_chores_progress
AS
SELECT chore_id
		, chore_completions.chore_completion_id
        , due_date
        , last_completed
        , COALESCE(duration_minutes, 0) AS completed_minutes
        , chore_durations.avg_duration_minutes - COALESCE(duration_minutes, 0) AS remaining_minutes
        , COALESCE(chore_durations.stdev_duration_minutes, all_chore_durations.stdev_duration_minutes) AS stdev_duration_minutes
	FROM chore_completions
    NATURAL JOIN chore_schedule
    NATURAL JOIN chore_durations
	LEFT OUTER JOIN chore_completion_durations
		ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
	CROSS JOIN all_chore_durations
    WHERE is_completed = 0