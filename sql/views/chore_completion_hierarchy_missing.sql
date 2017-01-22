CREATE VIEW chore_completion_hierarchy_missing
AS
SELECT chore_completions.chore_completion_id AS parent_chore_completion_id
		, chores.chore AS parent_chore
        , chore_schedule.due_date AS parent_due_date
        , potential_children.chore_completion_id AS child_chore_completion_id
        , chore_children.chore AS child_chore
        , potential_children_schedule.due_date AS child_due_date
	FROM chore_completions
    INNER JOIN chores
		ON chore_completions.chore_id = chores.chore_id
    INNER JOIN chore_schedule
		ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
    INNER JOIN chore_hierarchy
		ON chore_completions.chore_id = chore_hierarchy.parent_chore_id
	INNER JOIN chores AS chore_children
		ON chore_hierarchy.chore_id = chore_children.chore_id
	INNER JOIN chore_completions AS potential_children
		ON chore_hierarchy.chore_id = potential_children.chore_id
	INNER JOIN chore_schedule AS potential_children_schedule
		ON potential_children.chore_completion_id = potential_children_schedule.chore_completion_id
        AND DATE(chore_schedule.due_date) = DATE(potential_children_schedule.due_date)
	WHERE chore_completions.chore_completion_id NOT IN (SELECT parent_chore_completion_id
			FROM chore_completion_hierarchy)
		AND potential_children.chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_completion_hierarchy)