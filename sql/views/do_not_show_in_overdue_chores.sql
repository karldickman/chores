DROP VIEW IF EXISTS do_not_show_in_overdue_chores;
CREATE VIEW do_not_show_in_overdue_chores AS
SELECT chore_completion_id
	FROM chore_completions
	NATURAL JOIN chores
	NATURAL JOIN chore_categories
	NATURAL JOIN categories
	WHERE category = 'meals'
UNION
SELECT parent_chore_completion_id
	FROM chore_completion_hierarchy
	NATURAL JOIN chore_completions
	WHERE chore_completion_status_id = 1