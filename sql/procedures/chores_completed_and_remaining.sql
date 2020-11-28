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
    SET @days_unit_id = 1;
    SET @months_unit_id = 2;
    WITH meal_chores AS (SELECT chore_completion_id
        FROM chore_completions
        NATURAL JOIN chores
        NATURAL JOIN chore_categories
        NATURAL JOIN categories
        WHERE category = 'meals'),
    completed_chores AS (SELECT chore_completions.chore_id
            , chore_completions.chore_completion_id
            , due_date
            , TRUE AS is_completed
            , chore_completion_status_since AS last_completed
            , 0 AS remaining_minutes
            , 0 AS stdev_duration_minutes
            , 0 AS `95% CI UB`
            , chore_completion_status_id
        FROM chore_completions
        LEFT OUTER JOIN chore_completions_when_completed
            ON chore_completions.chore_completion_id = chore_completions_when_completed.chore_completion_id
        LEFT OUTER JOIN hierarchical_chore_schedule AS chore_schedule
            ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
        WHERE chore_completion_status_id IN (3, 4)
            AND chore_completions_when_completed.when_completed BETWEEN @`from` AND @`until`),
    time_remaining_by_chore AS (
    # Incomplete
    SELECT incomplete_chores.chore_id
            , chore_completion_id
            , due_date
            , FALSE AS is_completed
            , last_completed
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , stdev_duration_minutes
            , `95% CI UB`
        FROM incomplete_chores
        WHERE due_date < @`until`
            AND chore_completion_id NOT IN (SELECT parent_chore_completion_id
                    FROM chore_completion_hierarchy
                    NATURAL JOIN chore_completions
                    WHERE chore_completion_status_id = 1 /* scheduled */)
    UNION
    # Known duration
    SELECT chore_id
            , completed_chores.chore_completion_id
            , due_date
            , is_completed
            , last_completed
            , duration_minutes
            , duration_minutes AS completed_minutes
            , remaining_minutes
            , stdev_duration_minutes
            , `95% CI UB`
        FROM completed_chores
        INNER JOIN chore_completion_durations
            ON completed_chores.chore_completion_id = chore_completion_durations.chore_completion_id
        WHERE chore_completion_status_id = 4 /* completed */
    UNION
    # Unknown duration
    SELECT completed_chores.chore_id
            , chore_completion_id
            , due_date
            , is_completed
            , last_completed
            , COALESCE(chore_durations.avg_duration_minutes, all_chore_durations.avg_duration_minutes) AS duration_minutes
            , COALESCE(chore_durations.avg_duration_minutes, all_chore_durations.avg_duration_minutes) AS completed_minutes
            , remaining_minutes
            , completed_chores.stdev_duration_minutes
            , `95% CI UB`
        FROM completed_chores
        CROSS JOIN all_chore_durations
        LEFT OUTER JOIN chore_durations
            ON completed_chores.chore_id = chore_durations.chore_id
        WHERE chore_completion_status_id = 3 /* completed without sufficient data */),
    meal_summary AS (SELECT DATE(due_date) AS due_date
            , MIN(is_completed) AS is_completed
            , SUM(duration_minutes) AS duration_minutes
            , SUM(completed_minutes) AS completed_minutes
            , SUM(CASE WHEN remaining_minutes > 0 THEN remaining_minutes ELSE 0 END) AS remaining_minutes
            , SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stdev_duration_minutes
        FROM time_remaining_by_chore
        NATURAL JOIN meal_chores
        GROUP BY DATE(due_date)),
    chores_and_meals AS (SELECT chore
            , due_date
            , is_completed
            , FALSE AS meal
            , frequency
            , frequency_unit_id
            , frequency IS NOT NULL AND frequency <= 14 AND frequency_unit_id = @days_unit_id AS weekly
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , stdev_duration_minutes
            , `95% CI UB`
        FROM time_remaining_by_chore
        NATURAL JOIN chores
        LEFT OUTER JOIN chore_frequencies
            ON time_remaining_by_chore.chore_id = chore_frequencies.chore_id
        WHERE chore_completion_id NOT IN (SELECT chore_completion_id
            FROM meal_chores)
    UNION ALL
    SELECT CONCAT('meals ', DATE_FORMAT(due_date, '%m-%d')) AS chore
            , due_date
            , is_completed
            , 1 AS frequency
            , @days_unit_id AS frequency_unit_id 
            , TRUE AS meal
            , TRUE AS weekly
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , stdev_duration_minutes
            , remaining_minutes + (1.645 * stdev_duration_minutes) AS `95% CI UB`
        FROM meal_summary)
    SELECT chore
            , DATE_FORMAT(due_date, '%Y-%m-%d') AS due_date
            , is_completed
            , CASE
                WHEN meal
                    THEN 'meal'
                WHEN frequency IS NOT NULL
                        AND frequency < 7
                        AND frequency_unit_id = @days_unit_id
                    THEN 'daily'
                WHEN weekly
                    THEN 'weekly'
                WHEN frequency IS NOT NULL
                        AND (frequency <= 31 AND frequency_unit_id = @days_unit_id
                        OR frequency = 1 AND frequency_unit_id = @months_unit_id)
                    THEN 'monthly'
                WHEN frequency IS NOT NULL
                        AND frequency <= 91
                        AND frequency_unit_id = @days_unit_id
                    THEN 'quarterly'
                WHEN frequency IS NOT NULL
                        AND frequency <= 182
                        AND frequency_unit_id = @days_unit_id
                    THEN 'biannual'
                WHEN frequency IS NOT NULL
                        AND frequency <= 365
                        AND frequency_unit_id = @days_unit_id
                    THEN 'annual'
                ELSE 'biennial'
                END AS frequency
            , duration_minutes
            , completed_minutes
            , remaining_minutes
            , stdev_duration_minutes
            , `95% CI UB`
        FROM chores_and_meals
        ORDER BY CASE
                WHEN meal
                    THEN 0
                WHEN frequency IS NOT NULL
                        AND frequency < 7
                        AND frequency_unit_id = @days_unit_id
                    THEN 1
                WHEN weekly
                    THEN 7
                WHEN frequency IS NOT NULL
                        AND (frequency <= 31 AND frequency_unit_id = @days_unit_id
                        OR frequency = 1 AND frequency_unit_id = @months_unit_id)
                    THEN 31
                WHEN frequency IS NOT NULL
                        AND frequency <= 91
                        AND frequency_unit_id = @days_unit_id
                    THEN 91
                WHEN frequency IS NOT NULL
                        AND frequency <= 182
                        AND frequency_unit_id = @days_unit_id
                    THEN 182
                WHEN frequency IS NOT NULL
                        AND frequency <= 365
                        AND frequency_unit_id = @days_unit_id
                    THEN 365
                ELSE 730
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
