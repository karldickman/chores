ALTER VIEW incomplet_chores_progress
AS
SELECT chore_id
		, chore_completions.chore_completion_id
        , due_date
        , last_completed
        , COALESCE(duration_minutes, 0) AS completed_minutes
        , avg_duration_minutes - COALESCE(duration_minutes, 0) AS remaining_minutes
        , stdev_duration_minutes
	FROM chore_completions
    NATURAL JOIN chore_schedule
    NATURAL JOIN chore_durations
	LEFT OUTER JOIN chore_completion_durations
		ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
    WHERE is_completed = 0
