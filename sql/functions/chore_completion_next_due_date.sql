-- DROP FUNCTION chore_completion_next_due_date;
DELIMITER $$
CREATE FUNCTION chore_completion_next_due_date(completed_chore_completion_id INT)
RETURNS DATETIME
READS SQL DATA
BEGIN
    DECLARE schedule_from_date_for_completion DATETIME;
    DECLARE next_due_date DATETIME;
    DECLARE next_due_date_any_day_of_week DATETIME;
    DECLARE day_of_week INT;
    DECLARE time_of_day TIME;
	SELECT schedule_from_date
		INTO schedule_from_date_for_completion
		FROM chore_completions_schedule_from_dates
		WHERE chore_completion_id = completed_chore_completion_id;
	# Next due date for chore that is on one or more specific month-days, e.g. April 15
	IF EXISTS(SELECT *
		FROM chore_completions
		JOIN chore_due_dates USING (chore_id)
		WHERE chore_completion_id = completed_chore_completion_id)
	THEN
		SELECT MIN(STR_TO_DATE(CONCAT(
				YEAR(schedule_from_date_for_completion)
					+ (chore_due_dates.`month` < MONTH(schedule_from_date_for_completion)
						OR (chore_due_dates.`month` = MONTH(schedule_from_date_for_completion)
							AND chore_due_dates.`day` <= DAYOFMONTH(schedule_from_date_for_completion))),
				'-', chore_due_dates.`month`, '-', chore_due_dates.`day`), '%Y-%m-%d'))
			INTO next_due_date
			FROM chore_completions
			JOIN chore_due_dates USING (chore_id)
			WHERE chore_completion_id = completed_chore_completion_id;
    # Next due date if chore occurs on specific day of week, e.g. Wednesday
	ELSEIF EXISTS(SELECT *
		FROM chore_completions
		JOIN chore_day_of_week USING (chore_id)
		WHERE chore_completion_id = completed_chore_completion_id
			AND chore_id NOT IN (SELECT chore_id
					FROM chore_frequencies))
	THEN
		SELECT MIN(DATE(schedule_from_date_for_completion) + INTERVAL (CASE
				WHEN WEEKDAY(schedule_from_date_for_completion) = chore_day_of_week.day_of_week
					THEN 7
				ELSE (chore_day_of_week.day_of_week - WEEKDAY(schedule_from_date_for_completion) + 7) % 7
				END) DAY)
			INTO next_due_date
			FROM chore_completions
			JOIN chore_day_of_week USING (chore_id)
			WHERE chore_completion_id = completed_chore_completion_id;
	ELSE
		SELECT CASE
				WHEN frequency_unit_id = 1 # day
					THEN DATE(schedule_from_date_for_completion) + INTERVAL frequency DAY
				WHEN frequency_unit_id = 2 # month
					THEN DATE(schedule_from_date_for_completion) + INTERVAL frequency MONTH
				END
                INTO next_due_date_any_day_of_week
			FROM chore_completions
			JOIN chore_frequencies USING (chore_id)
			WHERE chore_completion_id = completed_chore_completion_id;
		SELECT COALESCE(chore_day_of_week.day_of_week, CASE
				WHEN chore_frequencies.frequency >= 7 AND chore_frequencies.frequency_unit_id = 1
						OR chore_frequencies.frequency > 0.25 AND chore_frequencies.frequency_unit_id = 2
					THEN 5
				END)
                INTO day_of_week
			FROM chore_completions
			JOIN chore_frequencies USING (chore_id)
			LEFT JOIN chore_day_of_week USING (chore_id)
			WHERE chore_completion_id = completed_chore_completion_id;
		IF day_of_week IS NOT NULL
        THEN
			SET next_due_date = nearest_day_of_week(next_due_date_any_day_of_week, day_of_week);
		ELSE
			SET next_due_date = next_due_date_any_day_of_week;
        END IF;
	END IF;
    # Get time of day
    WITH `schedule` AS (SELECT chore_id, chore_completion_id, due_date
		FROM chore_completions
		JOIN chore_schedule USING (chore_completion_id)),
	repetitions AS (SELECT the_completion.chore_id, COUNT(other_completions.chore_completion_id) + 1 AS repetition
		FROM `schedule` AS the_completion
		LEFT JOIN `schedule` AS other_completions
			ON the_completion.chore_id = other_completions.chore_id
			AND DATE(the_completion.due_date) = DATE(other_completions.due_date)
			AND the_completion.due_date > other_completions.due_date
		WHERE the_completion.chore_completion_id = completed_chore_completion_id
		GROUP BY the_completion.chore_completion_id)
	SELECT `time` INTO time_of_day
		FROM chore_time_of_day
		JOIN repetitions USING (chore_id, repetition);
	RETURN CAST(ADDTIME(next_due_date, COALESCE(time_of_day, 0)) AS DATETIME);
END $$
