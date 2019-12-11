USE chores;

DROP VIEW IF EXISTS chore_completions_when_completed;

CREATE VIEW chore_completions_when_completed
AS
WITH flatten_chore_completion_times_hierarchy AS (SELECT chore_completion_id, when_completed
	FROM chore_completion_times
UNION
SELECT parent_chore_completion_id, when_completed
	FROM chore_completion_times
	NATURAL JOIN chore_completion_hierarchy),
hierarchical_chore_completion_times AS (SELECT chore_completion_id, MAX(when_completed) AS when_completed
	FROM flatten_chore_completion_times_hierarchy
    GROUP BY chore_completion_id)
SELECT chore_completion_id, when_completed
	FROM hierarchical_chore_completion_times
UNION
SELECT chore_completion_id, MAX(when_completed) AS when_completed
	FROM hierarchical_chore_sessions
    WHERE chore_completion_id NOT IN (SELECT chore_completion_id
			FROM hierarchical_chore_completion_times)
    GROUP BY chore_completion_id