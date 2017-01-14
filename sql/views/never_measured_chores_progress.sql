ALTER VIEW never_measured_chores_progress
AS
SELECT chore_completions.chore_id
		, chore_completions.chore_completion_id
		, due_date
        , last_completed
        , COALESCE(duration_minutes, 0) AS completed_minutes
        , avg_duration_minutes - COALESCE(duration_minutes, 0) AS remaining_minutes
        , stdev_duration_minutes
	FROM chore_completions
    NATURAL JOIN chore_schedule
    NATURAL JOIN all_chore_durations
    LEFT OUTER JOIN chore_completion_durations
		ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
	LEFT OUTER JOIN last_chore_completion_times
		ON chore_completions.chore_id = last_chore_completion_times.chore_id
	WHERE is_completed = 0
		AND NOT EXISTS(SELECT *
				FROM chore_completions AS exists_subclause_chore_completions
                WHERE exists_subclause_chore_completions.is_completed = 1
					AND exists_subclause_chore_completions.chore_id = chore_completions.chore_id)