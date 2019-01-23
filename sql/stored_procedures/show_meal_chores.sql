USE chores;
DROP PROCEDURE IF EXISTS show_meal_chores;

DELIMITER $$

CREATE PROCEDURE show_meal_chores(`date` DATETIME, show_totals BIT)
BEGIN
    WITH relevant_chore_completions AS (SELECT chore_completion_id
		FROM chore_completions
        NATURAL JOIN chore_schedule
        NATURAL JOIN chore_categories
		NATURAL JOIN categories
		WHERE due_date < DATE_ADD(DATE(`date`), INTERVAL 1 DAY)
			AND category = 'meals'),
	backlog_calculations AS (SELECT COUNT(chore_completion_id) AS number_of_chores
			, SUM(completed_minutes) AS completed_minutes
            , SUM(remaining_minutes) AS non_truncated_backlog_minutes
			, SUM(CASE
				WHEN remaining_minutes > 0
					THEN remaining_minutes
				ELSE 0
                END) AS backlog_minutes
			, SQRT(SUM(POWER(CASE WHEN times_completed > 0 THEN stdev_duration_minutes ELSE 0 END, 2)))
				 + SUM(CASE WHEN times_completed = 0 THEN stdev_duration_minutes ELSE 0 END) AS stdev_backlog_minutes
		FROM incomplete_chores_progress
        NATURAL JOIN relevant_chore_completions),
	total AS (SELECT number_of_chores
			, completed_minutes
			, backlog_minutes
			, stdev_backlog_minutes
			, non_truncated_backlog_minutes + 1.282 * stdev_backlog_minutes AS `90% CI UB`
		FROM backlog_calculations),
	by_chore_and_total AS (SELECT FALSE AS is_total
			, chore
            , order_hint
			, due_date
            , last_completed
            , completed_minutes
            , remaining_minutes
			, stdev_duration_minutes
			, `90% CI UB`
		FROM incomplete_chores
        NATURAL JOIN chores
        LEFT OUTER JOIN chore_order
			ON incomplete_chores.chore_id = chore_order.chore_id
        NATURAL JOIN relevant_chore_completions
	UNION ALL
    SELECT TRUE AS is_total
			, 'Total' AS chore
            , NULL AS order_hint
			, NULL AS due_date
            , NULL AS last_completed
            , completed_minutes
            , backlog_minutes
			, stdev_backlog_minutes
			, `90% CI UB`
		FROM total
        WHERE show_totals = TRUE)
	SELECT chore
			, COALESCE(DATE_FORMAT(due_date, '%Y-%m-%d'), '') AS due_date
            , COALESCE(DATE_FORMAT(last_completed, '%Y-%m-%d %H:%i'), '') AS last_completed
            , format_duration(completed_minutes) AS completed
            , format_duration(remaining_minutes) AS remaining
			, format_duration(stdev_duration_minutes) AS std_dev
			, format_duration(`90% CI UB`) AS `90% CI UB`
		FROM by_chore_and_total
        ORDER BY is_total, due_date, order_hint;
END$$

DELIMITER ;