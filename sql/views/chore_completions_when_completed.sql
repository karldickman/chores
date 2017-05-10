DROP VIEW IF EXISTS chore_completions_when_completed;
CREATE VIEW chore_completions_when_completed
AS
SELECT chore_completion_id, MAX(when_completed) AS when_completed
	FROM (SELECT chore_completion_id, when_completed
			FROM chore_completion_durations
		UNION
		SELECT chore_completion_id, when_completed
			FROM chore_completion_times
			WHERE chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_sessions)
		UNION
		SELECT parent_chore_completion_id, when_completed
			FROM chore_completion_durations
			NATURAL JOIN chore_completion_hierarchy
		UNION
		SELECT parent_chore_completion_id, when_completed
			FROM chore_completion_times
            NATURAL JOIN chore_completion_hierarchy
			WHERE chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_sessions)) AS combined_completions
	GROUP BY chore_completion_id