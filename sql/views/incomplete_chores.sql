USE chores;

DROP VIEW IF EXISTS incomplete_chores;

CREATE VIEW incomplete_chores
AS
WITH chore_progress AS (SELECT chore_id
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
	FROM never_measured_chores_progress)
SELECT chore_id
		, chore_completion_id
		, due_date
		, last_completed
        , completed_minutes
		, remaining_minutes
		, stdev_duration_minutes
        , remaining_minutes + (1.282 * stdev_duration_minutes) AS `90% CI UB`
	FROM chore_progress