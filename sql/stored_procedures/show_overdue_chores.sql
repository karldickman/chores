USE chores;
DROP procedure IF EXISTS show_overdue_chores;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE show_overdue_chores(from_inclusive DATETIME, until_inclusive DATETIME, include_meals BOOL)
BEGIN
	SET from_inclusive = COALESCE(from_inclusive, '1989-02-09');
	SET @date_format = '%Y-%m-%d %H:%i';
    SET @time_format = '%H:%i:%S';
	SELECT chore
			, DATE_FORMAT(due_date, @date_format) AS due_date
            , DATE_FORMAT(last_completed, @date_format) AS last_completed
            , TIME_FORMAT(SEC_TO_TIME(completed_minutes * 60), @time_format) AS completed
            , TIME_FORMAT(SEC_TO_TIME(remaining_minutes * 60), @time_format) AS remaining
			, TIME_FORMAT(SEC_TO_TIME(stdev_duration_minutes * 60), @time_format) AS std_dev
			, TIME_FORMAT(SEC_TO_TIME((remaining_minutes + 1.282 * stdev_duration_minutes) * 60), @time_format) AS `90% CI UB`
		FROM report_incomplete_chores
		WHERE due_date BETWEEN from_inclusive AND until_inclusive
			AND (include_meals = 1
				OR chore NOT IN (SELECT chore
					FROM chores
					NATURAL JOIN chore_categories
					NATURAL JOIN categories
					WHERE category = 'meals'));
	SELECT category
			, SUM(number_of_chores) AS number_of_chores
			, TIME_FORMAT(SEC_TO_TIME(SUM(backlog_hours) * 60 * 60), @time_format) AS backlog
			, TIME_FORMAT(SEC_TO_TIME(SUM(stdev_backlog_hours) * 60 * 60), @time_format) AS std_dev
			, TIME_FORMAT(SEC_TO_TIME((SUM(backlog_hours) + 1.282 * SUM(stdev_backlog_hours)) * 60 * 60), @time_format) AS `90% CI UB`
		FROM (SELECT category
				, COUNT(incomplete_chores_progress.chore_id) AS number_of_chores
				, SUM(CASE
					WHEN remaining_minutes > 0
						THEN remaining_minutes
						ELSE 0
					END) / 60 AS backlog_hours
				, SQRT(SUM(CASE
					WHEN remaining_minutes > 0
						THEN POWER(stdev_duration_minutes, 2)
						ELSE 0
					END)) / 60 AS stdev_backlog_hours
			FROM incomplete_chores_progress
			LEFT OUTER JOIN chore_categories
				ON incomplete_chores_progress.chore_id = chore_categories.chore_id
			LEFT OUTER JOIN categories
				ON chore_categories.category_id = categories.category_id
			WHERE due_date BETWEEN from_inclusive AND until_inclusive
			GROUP BY category
		UNION
		SELECT category
				, COUNT(never_measured_chores_progress.chore_id) AS number_of_chores
				, SUM(CASE
					WHEN remaining_minutes > 0
						THEN remaining_minutes
						ELSE 0
					END) / 60 AS backlog_hours
				, SUM(CASE
					WHEN remaining_minutes > 0
						THEN stdev_duration_minutes
						ELSE 0
					END) / 60 AS stdev_backlog_hours
			FROM never_measured_chores_progress
			LEFT OUTER JOIN chore_categories
				ON never_measured_chores_progress.chore_id = chore_categories.chore_id
			LEFT OUTER JOIN categories
				ON chore_categories.category_id = categories.category_id
			WHERE due_date BETWEEN from_inclusive AND until_inclusive
			GROUP BY category) AS backlog_calculations
		GROUP BY category;
END$$

DELIMITER ;
