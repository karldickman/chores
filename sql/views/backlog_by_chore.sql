DROP VIEW IF EXISTS backlog_by_chore;
CREATE VIEW backlog_by_chore AS
SELECT chore_id
		, due_date
		, CASE
			WHEN remaining_minutes > 0
				THEN remaining_minutes
				ELSE 0
			END AS backlog_minutes
		, remaining_minutes AS non_truncated_backlog_minutes
		, stdev_duration_minutes
	FROM incomplete_chores_progress
	WHERE chore_completion_id NOT IN (SELECT chore_completion_id
		FROM do_not_show_in_overdue_chores)