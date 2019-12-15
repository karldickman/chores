USE chores;

DROP VIEW IF EXISTS hierarchical_chore_completion_times;

CREATE VIEW hierarchical_chore_completion_times
AS
WITH flatten_chore_completion_times_hierarchy AS (SELECT 'chore_completion_times' AS `source`
		, chore_completion_id
		, when_completed
	FROM chore_completion_times
UNION
SELECT 'chore_completion_hierarchy' AS `source`
		, parent_chore_completion_id
		, when_completed
	FROM chore_completion_times
	NATURAL JOIN chore_completion_hierarchy)
SELECT chore_completion_id
		, MAX(when_completed) AS when_completed
	FROM flatten_chore_completion_times_hierarchy
    GROUP BY chore_completion_id;
