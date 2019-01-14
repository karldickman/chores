DROP VIEW IF EXISTS incomplete_chores_next_due_dates;
CREATE VIEW incomplete_chores_next_due_dates
AS
SELECT chore_completion_id
		, chore_id
        , chore_completion_status_id
        , chore_completion_status_since
		, schedule_from_date
        , frequency
        , frequency_unit_id
        , frequency_unit
        , DATE_ADD(next_due_date, INTERVAL CASE
			WHEN WEEKDAY(next_due_date) < 3
				THEN -1 - WEEKDAY(next_due_date)
			WHEN WEEKDAY(next_due_date) >= 3
				THEN 6 - WEEKDAY(next_due_date)
			END DAY) AS next_due_date
	FROM chore_completion_next_due_dates
    WHERE chore_completion_status_id = 1
        AND chore_completion_id NOT IN (SELECT chore_completion_id
				FROM chore_completions
                NATURAL JOIN chore_categories
                WHERE category_id = 1 /* Meal */)