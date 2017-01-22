DROP VIEW IF EXISTS report_incomplete_chores;
CREATE VIEW report_incomplete_chores AS
SELECT chore
	, chore_completion_id
	, due_date
	, last_completed
	, completed_minutes
	, remaining_minutes
	, stdev_duration_minutes
FROM (SELECT chore_id
			, chore_completion_id
			, due_date
			, last_completed
			, completed_minutes
			, remaining_minutes
			, stdev_duration_minutes
		FROM incomplete_chores_progress
	UNION ALL
	SELECT chore_id
			, chore_completion_id
			, due_date
			, last_completed
			, completed_minutes
			, remaining_minutes
			, stdev_duration_minutes
		FROM never_measured_chores_progress) AS chore_progress
	NATURAL JOIN chores;