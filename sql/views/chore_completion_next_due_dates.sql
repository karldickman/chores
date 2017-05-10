DROP VIEW IF EXISTS chore_completion_next_due_dates;
CREATE VIEW chore_completion_next_due_dates
AS
SELECT chore_completion_id
		, schedule_from_date
        , schedule_from_id
        , frequency
        , frequency_unit_id
        , time_unit AS frequency_unit
        , CASE
			WHEN time_unit = 'day'
				THEN DATE_ADD(schedule_from_date, INTERVAL frequency DAY)
			WHEN time_unit = 'month'
				THEN DATE_ADD(schedule_from_date, INTERVAL frequency MONTH)
			END AS next_due_date
	FROM chore_completions_schedule_from_dates
    NATURAL JOIN chore_completions
    NATURAL JOIN chore_frequencies
    INNER JOIN time_units
		ON frequency_unit_id = time_units.time_unit_id
    ORDER BY chore_completion_id