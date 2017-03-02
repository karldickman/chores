DROP VIEW IF EXISTS all_chore_completion_times;
CREATE VIEW all_chore_completion_times
AS
SELECT chore_completion_id
		, when_completed
        , 'chore_sessions' AS recorded_in
    FROM chore_sessions
    NATURAL JOIN chore_completions
    WHERE chore_completion_status_id IN (3, 4)
UNION
SELECT chore_completion_id
		, when_completed
        , 'chore_completion_times' AS recorded_in
	FROM chore_completion_times
    NATURAL JOIN chore_completions
    WHERE chore_completion_status_id IN (3, 4)
		AND chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_sessions);