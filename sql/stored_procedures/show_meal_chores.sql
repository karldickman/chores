USE chores;
DROP PROCEDURE IF EXISTS show_meal_chores;

DELIMITER $$

CREATE PROCEDURE show_meal_chores(`date` DATETIME, show_totals BIT)
BEGIN
	SET @date_format = '%Y-%m-%d %H:%i';
    SET @time_format = '%H:%i:%S';
    WITH by_chore AS (SELECT chore_completion_id
			, chore
			, due_date
            , last_completed
            , completed
            , remaining
			, std_dev
			, `90% CI UB`
		FROM report_incomplete_chores
		WHERE due_date < DATE_ADD(DATE(`date`), INTERVAL 1 DAY)
			AND chore IN (SELECT chore
				FROM chores
				NATURAL JOIN chore_categories
				NATURAL JOIN categories
				WHERE category = 'meals')
		ORDER BY due_date),
	backlog_calculations AS (SELECT COUNT(incomplete_chores_progress.chore_id) AS number_of_chores
			, SUM(completed_minutes) AS completed_minutes
			, SUM(CASE
				WHEN remaining_minutes > 0
					THEN remaining_minutes
					ELSE 0
				END) AS backlog_minutes
			, SUM(remaining_minutes) AS non_truncated_backlog_minutes
			, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stdev_backlog_minutes
		FROM incomplete_chores_progress
		WHERE due_date < DATE_ADD(DATE(`date`), INTERVAL 1 DAY)
			AND chore_id IN (SELECT chore_id
				FROM chore_categories
				NATURAL JOIN categories
				WHERE category = 'meals')
	UNION
	SELECT COUNT(never_measured_chores_progress.chore_id) AS number_of_chores
			, SUM(completed_minutes) AS completed_minutes
			, SUM(CASE
				WHEN remaining_minutes > 0
					THEN remaining_minutes
					ELSE 0
				END) AS backlog_minutes
			, SUM(remaining_minutes) AS non_truncated_backlog_minutes
			, SUM(stdev_duration_minutes) AS stdev_backlog_minutes
		FROM never_measured_chores_progress
		WHERE due_date < DATE_ADD(DATE(`date`), INTERVAL 1 DAY)
			AND chore_id IN (SELECT chore_id
				FROM chore_categories
				NATURAL JOIN categories
				WHERE category = 'meals')),
	total AS (SELECT SUM(number_of_chores) AS number_of_chores
			, SUM(completed_minutes) AS completed_minutes
			, SUM(backlog_minutes) AS backlog_minutes
			, SUM(stdev_backlog_minutes) AS stdev_backlog_minutes
			, SUM(non_truncated_backlog_minutes) + 1.282 * SUM(stdev_backlog_minutes) AS `90% CI UB`
		FROM backlog_calculations)
	SELECT chore_completion_id
			, chore
			, due_date
            , last_completed
            , completed
            , remaining
			, std_dev
			, `90% CI UB`
		FROM by_chore
	UNION ALL
    SELECT NULL AS chore_completion_id
			, 'Total' AS chore
			, NULL AS due_date
            , NULL AS last_completed
            , TIME_FORMAT(SEC_TO_TIME(completed_minutes * 60), @time_format) AS completed
            , TIME_FORMAT(SEC_TO_TIME(backlog_minutes * 60), @time_format) AS remaining
			, TIME_FORMAT(SEC_TO_TIME(stdev_backlog_minutes * 60), @time_format) AS std_dev
			, TIME_FORMAT(SEC_TO_TIME(`90% CI UB` * 60), @time_format) AS `90% CI UB`
		FROM total
        WHERE show_totals = TRUE;
END$$

DELIMITER ;