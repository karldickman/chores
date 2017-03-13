CREATE VIEW chores_to_schedule
AS
SELECT chore_id, schedule_on, next_due_date
	FROM (SELECT chore_id
				, DATE_ADD(last_due_date, INTERVAL frequency_days - days_in_advance DAY) AS schedule_on
				, DATE_ADD(last_due_date, INTERVAL frequency_days DAY) AS next_due_date
			FROM (SELECT chore_id, MAX(due_date) AS last_due_date
					FROM chore_schedule
					NATURAL JOIN chore_completions
					NATURAL JOIN chore_schedule_in_advance
					NATURAL JOIN schedule_from
					WHERE schedule_from = 'due date'
					GROUP BY chore_id) AS last_due_dates
				NATURAL JOIN chore_schedule_in_advance
				NATURAL JOIN chore_frequencies) AS scheduling_parameters
	WHERE schedule_on <= DATE(CURRENT_TIMESTAMP)
		AND NOT EXISTS(SELECT *
				FROM chore_schedule
                NATURAL JOIN chore_completions
                WHERE chore_completions.chore_id = scheduling_parameters.chore_id
					AND due_date = next_due_date)