USE chores;

DROP VIEW IF EXISTS hierarchical_chore_schedule;

CREATE VIEW hierarchical_chore_schedule
AS 
SELECT chore_completion_id, due_date
	FROM chore_schedule
UNION
SELECT chore_completions.chore_completion_id, due_date
	FROM chore_completions
	NATURAL JOIN chore_completion_hierarchy
	INNER JOIN chore_schedule
		ON parent_chore_completion_id = chore_schedule.chore_completion_id
	WHERE chore_completions.chore_completion_id NOT IN (SELECT chore_completion_id
			FROM chore_schedule)