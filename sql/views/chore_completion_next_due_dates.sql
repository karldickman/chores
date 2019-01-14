DROP VIEW IF EXISTS chore_completion_next_due_dates;
CREATE VIEW chore_completion_next_due_dates
AS
SELECT chore_completions.chore_completion_id
		, chore_completions.chore_id
		, chore_completions.chore_completion_status_id
        , chore_completion_status_since
		, schedule_from_date
        , chore_completions_schedule_from_dates.schedule_from_id
        , frequency
        , frequency_unit_id
        , time_unit AS frequency_unit
        , CASE
			WHEN time_unit = 'day'
				THEN DATE_ADD(schedule_from_date, INTERVAL frequency DAY)
			WHEN time_unit = 'month'
				THEN DATE_ADD(schedule_from_date, INTERVAL frequency MONTH)
			END AS next_due_date
	FROM chore_completions
    INNER JOIN chore_completions_schedule_from_dates
		ON chore_completions.chore_completion_id = chore_completions_schedule_from_dates.chore_completion_id
    INNER JOIN chore_frequencies
		ON chore_completions.chore_id = chore_frequencies.chore_id
    INNER JOIN time_units
		ON frequency_unit_id = time_units.time_unit_id
    ORDER BY chore_completions.chore_completion_id