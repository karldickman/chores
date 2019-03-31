USE chores;

DROP VIEW IF EXISTS incomplete_measured_chores_progress;

CREATE VIEW incomplete_measured_chores_progress
AS
SELECT chore_completions.chore_completion_id
		, chore_completions.chore_id
        , due_date
        , last_completed
        , times_completed
        , COALESCE(duration_minutes, 0) AS completed_minutes
        , chore_durations.avg_duration_minutes - COALESCE(duration_minutes, 0) AS remaining_minutes
        , COALESCE(chore_durations.stdev_duration_minutes, all_chore_durations.stdev_duration_minutes) AS stdev_duration_minutes
	FROM chore_completions
    NATURAL JOIN chore_schedule
	LEFT OUTER JOIN last_chore_completion_times
		ON chore_completions.chore_id = last_chore_completion_times.chore_id
	LEFT OUTER JOIN chore_completion_durations
		ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
    INNER JOIN chore_durations
		ON chore_completions.chore_id = chore_durations.chore_id
	CROSS JOIN all_chore_durations
    WHERE chore_completion_status_id = 1