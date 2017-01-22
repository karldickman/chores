ALTER VIEW chore_completion_durations
AS
SELECT chore_completion_id
		, COUNT(chore_session_id) AS number_of_sessions
        , MAX(when_completed) AS when_completed
        , SUM(duration_minutes) AS duration_minutes
	FROM chore_completions
    NATURAL JOIN chore_sessions
    GROUP BY chore_completion_id