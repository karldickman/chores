USE chores;

DROP PROCEDURE IF EXISTS show_meal_chores;

DELIMITER $$

CREATE PROCEDURE show_meal_chores(`date` DATETIME, show_totals BIT)
BEGIN
    WITH relevant_chore_completions AS (SELECT chore_completion_id
        FROM chore_completions
        JOIN chore_schedule USING (chore_completion_id)
        JOIN chore_categories USING (chore_id)
        WHERE due_date < DATE_ADD(DATE(`date`), INTERVAL 1 DAY)
            AND category_id = 1 /* meals */),
    backlog_calculations AS (SELECT COUNT(chore_completion_id) AS number_of_chores
            , SUM(completed_minutes) AS completed_minutes
            , SUM(remaining_minutes) AS non_truncated_remaining_minutes
            , SUM(CASE
                WHEN remaining_minutes > 0
                    THEN remaining_minutes
                ELSE 0
                END) AS remaining_minutes
            , SUM(`95%ile`) AS `95%ile`
        FROM incomplete_chores_progress
        JOIN relevant_chore_completions USING (chore_completion_id)),
    total AS (SELECT number_of_chores
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM backlog_calculations
        WHERE number_of_chores > 0),
    by_chore_and_total AS (SELECT FALSE AS is_total
            , chore
            , order_hint
            , due_date
            , last_completed
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM incomplete_chores_progress
        JOIN chores USING (chore_id)
        LEFT JOIN chore_order USING (chore_id)
        JOIN relevant_chore_completions USING (chore_completion_id)
    UNION ALL
    SELECT TRUE AS is_total
            , 'Total' AS chore
            , NULL AS order_hint
            , NULL AS due_date
            , NULL AS last_completed
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM total
        WHERE show_totals)
    SELECT chore
            , COALESCE(DATE_FORMAT(due_date, '%Y-%m-%d'), '') AS due_date
            , COALESCE(DATE_FORMAT(last_completed, '%Y-%m-%d %H:%i'), '') AS last_completed
            , format_duration(completed_minutes) AS completed
            , format_duration(remaining_minutes) AS remaining
            , format_duration(`95%ile`) AS `95%ile`
        FROM by_chore_and_total
        ORDER BY is_total, due_date, order_hint;
END$$

DELIMITER ;
