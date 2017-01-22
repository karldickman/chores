ALTER VIEW chore_completion_durations
AS
SELECT chore_completion_id
		, COUNT(chore_session_id) AS number_of_sessions
        , MAX(when_completed) AS when_completed
        , SUM(duration_minutes) AS duration_minutes
	FROM (SELECT chore_completion_id
				, chore_session_id
				, when_completed
				, duration_minutes
			FROM chore_completions
			NATURAL JOIN chore_sessions
		UNION
		SELECT parent_chore_completion_id
				, chore_session_id
				, when_completed
				, duration_minutes
			FROM chore_completion_hierarchy
			NATURAL JOIN chore_sessions
			INNER JOIN chore_completions
				ON parent_chore_completion_id = chore_completions.chore_completion_id
			NATURAL JOIN chores
			WHERE measure_duration_recursively) AS recursive_chore_sessions
    GROUP BY chore_completion_id