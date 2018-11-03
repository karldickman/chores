USE chores;
DROP PROCEDURE IF EXISTS chores_completed_and_remaining;

DELIMITER $$

CREATE PROCEDURE chores_completed_and_remaining(`from` DATE, `until` DATE)
BEGIN
	SET @until = DATE_ADD(DATE(`until`), INTERVAL 1 DAY);
	WITH time_remaining_by_chore AS (SELECT incomplete_chores.chore_id
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
			AND chore_completion_id NOT IN (SELECT chore_completion_id
					FROM do_not_show_in_overdue_chores)
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
		LEFT OUTER JOIN chore_schedule
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
					WHERE chore_completion_status_id = 4))
	SELECT chore
			, due_date
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
		ORDER BY weekly DESC, is_completed, remaining_minutes DESC, duration_minutes;
END$$

DELIMITER ;