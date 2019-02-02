USE chores;
DROP PROCEDURE IF EXISTS chores_completed_and_remaining;

DELIMITER $$

CREATE PROCEDURE chores_completed_and_remaining(`from` DATE, `until` DATE)
BEGIN
	SET @until = DATE_ADD(DATE(`until`), INTERVAL 1 DAY);
	WITH meal_chores AS (SELECT chore_completion_id
		FROM chore_completions
		NATURAL JOIN chores
		NATURAL JOIN chore_categories
		NATURAL JOIN categories
		WHERE category = 'meals'),
	hierarchical_chore_schedule AS (SELECT chore_completion_id, due_date
		FROM chore_schedule
	UNION
    SELECT chore_completions.chore_completion_id, due_date
		FROM chore_completions
        NATURAL JOIN chore_completion_hierarchy
        INNER JOIN chore_schedule
			ON parent_chore_completion_id = chore_schedule.chore_completion_id
        WHERE chore_completions.chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_schedule)),
    time_remaining_by_chore AS (SELECT incomplete_chores.chore_id
			, chore_completion_id
			, due_date
			, FALSE AS is_completed
			, last_completed
			, avg_duration_minutes AS duration_minutes
			, completed_minutes
			, remaining_minutes
			, incomplete_chores.stdev_duration_minutes
			, `90% CI UB`
		FROM incomplete_chores
		INNER JOIN chore_durations
			ON incomplete_chores.chore_id = chore_durations.chore_id
		WHERE due_date < @until
			AND chore_completion_id NOT IN (SELECT parent_chore_completion_id
					FROM chore_completion_hierarchy
					NATURAL JOIN chore_completions
					WHERE chore_completion_status_id = 1)
	UNION
	SELECT chore_completions.chore_id
			, chore_completions.chore_completion_id
			, due_date
			, TRUE AS is_completed
			, chore_completion_status_since AS last_completed
			, COALESCE(duration_minutes, avg_duration_minutes) AS duration_minutes
			, COALESCE(duration_minutes, avg_duration_minutes) AS completed_minutes
			, 0 AS remaining_minutes
			, 0 AS stdev_duration_minutes
			, 0 AS `90% CI UB`
		FROM chore_completions
        LEFT OUTER JOIN chore_completions_when_completed
			ON chore_completions.chore_completion_id = chore_completions_when_completed.chore_completion_id
		LEFT OUTER JOIN hierarchical_chore_schedule AS chore_schedule
			ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
		LEFT OUTER JOIN chore_completion_durations
			ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
		LEFT OUTER JOIN chore_durations
			ON chore_completions.chore_id = chore_durations.chore_id
		WHERE chore_completion_status_id IN (3, 4) # completed
			AND chore_completions_when_completed.when_completed BETWEEN `from` AND @until
            AND chore_completions.chore_completion_id NOT IN (SELECT parent_chore_completion_id
					FROM chore_completion_hierarchy
                    INNER JOIN chore_completions
						ON parent_chore_completion_id = chore_completions.chore_completion_id
					WHERE chore_completion_status_id = 4)),
	meal_summary AS (SELECT due_date
			, MIN(is_completed) AS is_completed
			, SUM(duration_minutes) AS duration_minutes
			, SUM(completed_minutes) AS completed_minutes
			, SUM(remaining_minutes) AS remaining_minutes
			, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stdev_duration_minutes
		FROM time_remaining_by_chore
        NATURAL JOIN meal_chores
        GROUP BY due_date),
	chores_and_meals AS (SELECT chore
			, due_date
            , is_completed
            , FALSE AS meal
			, frequency IS NOT NULL AND frequency <= 7 AND frequency_unit_id = 1 /*Days*/ AS weekly
			, duration_minutes
			, completed_minutes
			, remaining_minutes
			, stdev_duration_minutes
			, `90% CI UB`
		FROM time_remaining_by_chore
		NATURAL JOIN chores
		LEFT OUTER JOIN chore_frequencies
			ON time_remaining_by_chore.chore_id = chore_frequencies.chore_id
		WHERE chore_completion_id NOT IN (SELECT chore_completion_id
			FROM meal_chores)
	UNION
    SELECT CONCAT('meals ', DATE_FORMAT(due_date, '%m-%d')) AS chore
			, due_date
            , is_completed
            , TRUE AS meal
			, TRUE AS weekly
			, duration_minutes
			, completed_minutes
			, remaining_minutes
			, stdev_duration_minutes
			, remaining_minutes + (1.282 * stdev_duration_minutes) AS `90% CI UB`
		FROM meal_summary)
	SELECT chore
			, DATE_FORMAT(due_date, '%Y-%m-%d') AS due_date
            , is_completed
            , weekly
            , ROUND(duration_minutes, 2) AS duration
            , ROUND(completed_minutes, 2) AS completed
            , ROUND(remaining_minutes, 2) AS remaining
            , ROUND(stdev_duration_minutes, 2) AS stdev_duration
            , ROUND(`90% CI UB`, 2) AS `90% CI UB`
		FROM chores_and_meals
		ORDER BY meal DESC
			, weekly DESC
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