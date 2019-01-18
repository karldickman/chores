USE chores;
DROP PROCEDURE IF EXISTS show_overdue_chores;

DELIMITER $$

CREATE PROCEDURE show_overdue_chores(from_inclusive DATETIME, until_inclusive DATETIME)
BEGIN
	SET from_inclusive = COALESCE(from_inclusive, '1989-02-09');
    SET until_inclusive = COALESCE(until_inclusive, '2161-10-11');
	SET @date_format = '%Y-%m-%d %H:%i';
    SET @time_format = '%H:%i:%S';
	SELECT chore_completion_id
			, chore
			, due_date
            , last_completed
            , completed
            , remaining
			, std_dev
			, `90% CI UB`
		FROM report_incomplete_chores
		WHERE due_date BETWEEN from_inclusive AND until_inclusive
			AND chore_completion_id NOT IN (SELECT chore_completion_id
					FROM do_not_show_in_overdue_chores)
		ORDER BY remaining, std_dev;
	SELECT SUM(number_of_chores) AS number_of_chores
			, TIME_FORMAT(SEC_TO_TIME(SUM(backlog_minutes) * 60), @time_format) AS backlog
			, TIME_FORMAT(SEC_TO_TIME(SUM(stdev_backlog_minutes) * 60), @time_format) AS std_dev
			, TIME_FORMAT(SEC_TO_TIME((SUM(non_truncated_backlog_minutes) + 1.282 * SUM(stdev_backlog_minutes)) * 60), @time_format) AS `90% CI UB`
		FROM (SELECT COUNT(chore_id) AS number_of_chores
				, SUM(backlog_minutes) AS backlog_minutes
				, SUM(non_truncated_backlog_minutes) AS non_truncated_backlog_minutes
				, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stdev_backlog_minutes
			FROM backlog_by_chore
			WHERE due_date BETWEEN from_inclusive AND until_inclusive
		UNION
		SELECT COUNT(chore_id) AS number_of_chores
				, SUM(backlog_minutes) AS backlog_minutes
				, SUM(non_truncated_backlog_minutes) AS non_truncated_backlog_minutes
				, SUM(stdev_duration_minutes) AS stdev_backlog_minutes
			FROM never_measured_chores_backlog
			WHERE due_date BETWEEN from_inclusive AND until_inclusive)
		AS backlog_calculations;
END$$

DELIMITER ;
