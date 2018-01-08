DROP VIEW IF EXISTS report_incomplete_chores;
CREATE VIEW report_incomplete_chores AS
SELECT chore
	, chore_completion_id
	, DATE_FORMAT(due_date, '%Y-%m-%d %H:%i') AS due_date
	, DATE_FORMAT(last_completed, '%Y-%m-%d %H:%i') AS last_completed
	, TIME_FORMAT(SEC_TO_TIME(completed_minutes * 60), '%H:%i:%S') AS completed
	, TIME_FORMAT(SEC_TO_TIME(remaining_minutes * 60), '%H:%i:%S') AS remaining
	, TIME_FORMAT(SEC_TO_TIME(stdev_duration_minutes * 60), '%H:%i:%S') AS std_dev
    , TIME_FORMAT(SEC_TO_TIME((remaining_minutes + 1.282 * stdev_duration_minutes) * 60), '%H:%i:%S') AS `90% CI UB`
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