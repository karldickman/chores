DROP VIEW IF EXISTS all_chore_completion_times;
CREATE VIEW all_chore_completion_times
AS
SELECT chore_id
		, when_completed
    FROM chore_sessions
    NATURAL JOIN chore_completions
    NATURAL JOIN chores
    WHERE is_completed = 1
UNION
SELECT chore_id
		, when_completed
	FROM chore_completion_times
    NATURAL JOIN chore_completions
    NATURAL JOIN chores
    WHERE is_completed = 1
		AND chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_sessions);