USE chores;

DROP VIEW IF EXISTS chore_completions_when_completed;

CREATE VIEW chore_completions_when_completed
AS
WITH when_completed AS (SELECT 'chore_completion_times' AS `source`
		, chore_completion_id
		, when_completed
	FROM hierarchical_chore_completion_times
UNION
SELECT 'chore_sessions' AS `source`
		, chore_completion_id
		, MAX(when_completed) AS when_completed
	FROM hierarchical_chore_sessions
    WHERE chore_completion_id NOT IN (SELECT chore_completion_id
			FROM hierarchical_chore_completion_times)
    GROUP BY chore_completion_id)
SELECT `source`
		, chore_completion_id
        , when_completed
	FROM when_completed
    NATURAL JOIN chore_completions
    WHERE chore_completion_status_id != 1; # scheduled