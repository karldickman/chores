USE chores;

DROP PROCEDURE IF EXISTS chores_completed_and_remaining;

DELIMITER $$

CREATE PROCEDURE chores_completed_and_remaining(`from` DATETIME, `until` DATETIME)
BEGIN
    SET @`now` = NOW();
    SET @`from` = `from`;
    IF @`from` IS NULL THEN
        SET @`from` = DATE(@`now`);
    END IF;
    SET @`until` = `until`;
    IF @`until` IS NULL THEN
        IF @`from` < @`now` THEN
            SET @`until` = @`now`;
        ELSE
            SET @`until` = @`from`;
        END IF;
    END IF;
    IF @`until` = DATE(@`until`) THEN
        SET @`until` = DATE_ADD(DATE(@`until`), INTERVAL 1 DAY);
    END IF;
    WITH meal_chores AS (SELECT chore_completion_id
        FROM chore_completions
        JOIN chore_categories USING (chore_id)
        WHERE category_id = 1 /*'meals'*/),
    completed_chores AS (SELECT chore_completions.chore_id
            , chore
            , chore_completions.chore_completion_id
            , due_date
            , TRUE AS is_completed
            , chore_completion_status_since AS last_completed
            , 0 AS remaining_minutes
            , 0 AS `95% CI UB`
            , chore_completion_status_id
        FROM chore_completions
        JOIN chores USING (chore_id)
        LEFT JOIN chore_completions_when_completed USING (chore_completion_id)
        LEFT JOIN hierarchical_chore_schedule AS chore_schedule USING (chore_completion_id)
        WHERE chore_completion_status_id IN (3, 4) # completed, with or without recorded duration
            AND chore_completions_when_completed.when_completed BETWEEN @`from` AND @`until`),
    time_remaining_by_chore AS (
    # Incomplete
    SELECT incomplete_chores_progress.chore_id
            , chore
            , chore_completion_id
            , due_date
            , FALSE AS is_completed
            , last_completed
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95% CI UB`
        FROM incomplete_chores_progress
        WHERE due_date < @`until`
            AND chore_completion_id NOT IN (SELECT parent_chore_completion_id
                    FROM chore_completion_hierarchy
                    JOIN chore_completions USING (chore_completion_id)
                    WHERE chore_completion_status_id = 1 /* scheduled */)
    UNION
    # Known duration
    SELECT chore_id
            , chore
            , completed_chores.chore_completion_id
            , due_date
            , is_completed
            , last_completed
            , duration_minutes
            , duration_minutes AS completed_minutes
            , remaining_minutes
            , `95% CI UB`
        FROM completed_chores
        JOIN chore_completion_durations USING (chore_completion_id)
        WHERE chore_completion_status_id = 4 /* completed */
    UNION
    # Unknown duration
    SELECT completed_chores.chore_id
            , completed_chores.chore
            , chore_completion_id
            , due_date
            , is_completed
            , last_completed
            , COALESCE(chore_durations.mean_duration_minutes, all_chore_durations.mean_duration_minutes) AS duration_minutes
            , COALESCE(chore_durations.mean_duration_minutes, all_chore_durations.mean_duration_minutes) AS completed_minutes
            , remaining_minutes
            , completed_chores.`95% CI UB`
        FROM completed_chores
        CROSS JOIN all_chore_durations
        LEFT JOIN chore_durations USING (chore_id)
        WHERE chore_completion_status_id = 3 /* completed without sufficient data */),
    meal_summary AS (SELECT DATE(due_date) AS due_date
            , MIN(is_completed) AS is_completed
            , SUM(duration_minutes) AS duration_minutes
            , SUM(completed_minutes) AS completed_minutes
            , SUM(CASE WHEN remaining_minutes > 0 THEN remaining_minutes ELSE 0 END) AS remaining_minutes
            , SUM(`95% CI UB`) AS `95% CI UB`
        FROM time_remaining_by_chore
        JOIN meal_chores USING (chore_completion_id)
        GROUP BY DATE(due_date)),
    chores_and_meals AS (SELECT time_remaining_by_chore.chore
            , due_date
            , is_completed
            , FALSE AS meal
            , period_days
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95% CI UB`
        FROM time_remaining_by_chore
        LEFT JOIN chore_completions_per_day USING (chore_id)
        WHERE chore_completion_id NOT IN (SELECT chore_completion_id
            FROM meal_chores)
    UNION ALL
    SELECT CONCAT('meals ', DATE_FORMAT(due_date, '%m-%d')) AS chore
            , due_date
            , is_completed
            , 1 AS period_days
            , TRUE AS meal
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95% CI UB`
        FROM meal_summary),
    chores_and_periods AS (SELECT chore
            , due_date
            , is_completed
            , CASE
                WHEN meal
                    THEN 'meal'
                WHEN period_days IS NOT NULL AND period_days < 7
                    THEN 'daily'
                WHEN period_days <= 14
                    THEN 'weekly'
                WHEN period_days IS NOT NULL AND period_days <= 31
                    THEN 'monthly'
                WHEN period_days IS NOT NULL AND period_days < 92
                    THEN 'quarterly'
                WHEN period_days IS NOT NULL AND period_days < 183
                    THEN 'biannual'
                WHEN period_days IS NOT NULL AND period_days < 366
                    THEN 'annual'
                ELSE 'biennial'
                END AS frequency
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95% CI UB`
        FROM chores_and_meals)
    SELECT chore
            , DATE_FORMAT(due_date, '%Y-%m-%d') AS due_date
            , is_completed
            , frequency
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95% CI UB`
        FROM chores_and_periods
        ORDER BY CASE
                WHEN frequency = 'meal'
                    THEN 0
                WHEN frequency = 'daily'
                    THEN 1
                WHEN frequency = 'weekly'
                    THEN 7
                WHEN frequency = 'monthly'
                    THEN 31
                WHEN frequency = 'quarterly'
                    THEN 91
                WHEN frequency = 'biannual'
                    THEN 182
                WHEN frequency = 'yearly'
                    THEN 365
                ELSE 730
            END
            , CASE
                WHEN frequency = 'meal'
                    THEN due_date
                ELSE 0
            END
            , is_completed
            , remaining_minutes DESC
            , duration_minutes;
END$$

DELIMITER ;
