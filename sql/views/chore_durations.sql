ALTER VIEW chore_durations
AS
SELECT chore_id
		, COUNT(chore_completion_id) AS times_completed
        , AVG(1.0 * number_of_sessions) AS avg_number_of_sessions
        , MAX(when_completed) AS last_completed
        , AVG(duration_minutes) AS avg_duration_minutes
        , CASE WHEN COUNT(chore_completion_id) > 1 THEN STD(duration_minutes) END AS stdev_duration_minutes
	FROM chore_completion_durations
    NATURAL JOIN chore_completions
    WHERE is_completed = 1
    GROUP BY chore_id