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
    SET @meal_chore_category_id = 1;
    WITH time_remaining_by_chore_completion AS (SELECT chore_id
            , chore
            , chore_completion_id
            , due_date
            , is_completed
            , when_completed
            , central_tendency_duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM chores.time_remaining_by_chore
        WHERE is_completed AND when_completed BETWEEN @`from` AND @`until`
            OR NOT is_completed AND due_date < @`until`),
    time_remaining_by_chore AS (SELECT chore_id
            , due_date
            , MIN(is_completed) AS is_completed
            , SUM(central_tendency_duration_minutes) AS central_tendency_duration_minutes
            , SUM(completed_minutes) AS completed_minutes
            , SUM(remaining_minutes) AS remaining_minutes
            , SUM(`95%ile`) AS `95%ile`
        FROM time_remaining_by_chore_completion
        GROUP BY chore_id, due_date),
    meal_chores AS (SELECT chore_completion_id
        FROM chore_completions
        JOIN chore_categories USING (chore_id)
        WHERE category_id = @meal_chore_category_id),
    meal_summary AS (SELECT DATE(COALESCE(due_date, when_completed)) AS due_date
            , MIN(is_completed) AS is_completed
            , MAX(when_completed) AS when_completed
            , SUM(central_tendency_duration_minutes) AS central_tendency_duration_minutes
            , SUM(completed_minutes) AS completed_minutes
            , SUM(CASE WHEN remaining_minutes > 0 THEN remaining_minutes ELSE 0 END) AS remaining_minutes
            , SUM(`95%ile`) AS `95%ile`
        FROM time_remaining_by_chore_completion
        JOIN meal_chores USING (chore_completion_id)
        GROUP BY DATE(COALESCE(due_date, when_completed))),
    chores_and_meals AS (SELECT chores.chore
            , due_date
            , is_completed
            , FALSE AS meal
            , period_days
            , central_tendency_duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM time_remaining_by_chore
        JOIN chores USING (chore_id)
        LEFT JOIN chore_periods_days USING (chore_id)
        WHERE chore_id NOT IN (SELECT chore_id
            FROM chore_categories
            WHERE category_id = @meal_chore_category_id)
    UNION ALL
    SELECT CONCAT('meals ', DATE_FORMAT(due_date, '%m-%d')) AS chore
            , due_date
            , is_completed
            , 1 AS period_days
            , TRUE AS meal
            , central_tendency_duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM meal_summary)
    SELECT chore
            , DATE_FORMAT(due_date, '%Y-%m-%d') AS due_date
            , is_completed
            , CASE
                WHEN meal
                    THEN 'meal'
                ELSE frequency_category
                END AS frequency
            , central_tendency_duration_minutes AS duration_minutes
            , completed_minutes
            , remaining_minutes
            , `95%ile`
        FROM chores_and_meals
        LEFT JOIN frequency_category_ranges
            ON period_days > minimum_period_days AND period_days < maximum_period_days
            OR period_days = minimum_period_days AND minimum_period_inclusive
            OR period_days = maximum_period_days AND maximum_period_inclusive
        ORDER BY CASE
                WHEN meal
                    THEN 0
                ELSE COALESCE(maximum_period_days, 9999)
            END
            , CASE
                WHEN meal
                    THEN due_date
                ELSE 0
            END
            , is_completed
            , remaining_minutes DESC
            , duration_minutes;
END$$

DELIMITER ;
