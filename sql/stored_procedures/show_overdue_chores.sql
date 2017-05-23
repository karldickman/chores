USE chores;
DROP PROCEDURE IF EXISTS show_overdue_chores;

DELIMITER $$
USE chores$$
CREATE PROCEDURE show_overdue_chores(from_inclusive DATETIME, until_inclusive DATETIME)
BEGIN
	SET from_inclusive = COALESCE(from_inclusive, '1989-02-09');
    SET until_inclusive = COALESCE(until_inclusive, '2161-10-11');
	SET @date_format = '%Y-%m-%d %H:%i';
    SET @time_format = '%H:%i:%S';
	SELECT chore_completion_id
			, chore
			, DATE_FORMAT(due_date, @date_format) AS due_date
            , DATE_FORMAT(last_completed, @date_format) AS last_completed
            , TIME_FORMAT(SEC_TO_TIME(completed_minutes * 60), @time_format) AS completed
            , TIME_FORMAT(SEC_TO_TIME(remaining_minutes * 60), @time_format) AS remaining
			, TIME_FORMAT(SEC_TO_TIME(stdev_duration_minutes * 60), @time_format) AS std_dev
			, TIME_FORMAT(SEC_TO_TIME((remaining_minutes + 1.282 * stdev_duration_minutes) * 60), @time_format) AS `90% CI UB`
		FROM report_incomplete_chores
		WHERE due_date BETWEEN from_inclusive AND until_inclusive
			AND chore NOT IN (SELECT chore
				FROM chores
				NATURAL JOIN chore_categories
				NATURAL JOIN categories
				WHERE category = 'meals')
			AND chore_completion_id NOT IN (SELECT parent_chore_completion_id
				FROM chore_completion_hierarchy
                NATURAL JOIN chore_completions
                WHERE chore_completion_status_id = 1)
		ORDER BY remaining_minutes, stdev_duration_minutes;
	SELECT SUM(number_of_chores) AS number_of_chores
			, TIME_FORMAT(SEC_TO_TIME(SUM(backlog_minutes) * 60), @time_format) AS backlog
			, TIME_FORMAT(SEC_TO_TIME(SUM(stdev_backlog_minutes) * 60), @time_format) AS std_dev
			, TIME_FORMAT(SEC_TO_TIME((SUM(non_truncated_backlog_minutes) + 1.282 * SUM(stdev_backlog_minutes)) * 60), @time_format) AS `90% CI UB`
		FROM (SELECT COUNT(incomplete_chores_progress.chore_id) AS number_of_chores
				, SUM(CASE
					WHEN remaining_minutes > 0
						THEN remaining_minutes
						ELSE 0
					END) AS backlog_minutes
				, SUM(remaining_minutes) AS non_truncated_backlog_minutes
				, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stdev_backlog_minutes
			FROM incomplete_chores_progress
			WHERE due_date BETWEEN from_inclusive AND until_inclusive
				AND chore_id NOT IN (SELECT chore_id
					FROM chore_categories
					NATURAL JOIN categories
					WHERE category = 'meals')
				AND chore_completion_id NOT IN (SELECT parent_chore_completion_id
					FROM chore_completion_hierarchy
					NATURAL JOIN chore_completions
					WHERE chore_completion_status_id = 1)
		UNION
		SELECT COUNT(never_measured_chores_progress.chore_id) AS number_of_chores
				, SUM(CASE
					WHEN remaining_minutes > 0
						THEN remaining_minutes
						ELSE 0
					END) AS backlog_minutes
				, SUM(remaining_minutes) AS non_truncated_backlog_minutes
				, SUM(stdev_duration_minutes) AS stdev_backlog_minutes
			FROM never_measured_chores_progress
			WHERE due_date BETWEEN from_inclusive AND until_inclusive
				AND chore_id NOT IN (SELECT chore_id
					FROM chore_categories
					NATURAL JOIN categories
					WHERE category = 'meals')
				AND chore_completion_id NOT IN (SELECT parent_chore_completion_id
					FROM chore_completion_hierarchy
					NATURAL JOIN chore_completions
					WHERE chore_completion_status_id = 1)) AS backlog_calculations;
END$$

DELIMITER ;