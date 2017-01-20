DROP VIEW IF EXISTS chore_completion_next_due_dates;
CREATE VIEW chore_completion_next_due_dates
AS
SELECT chore_completion_id
		, schedule_from_date
        , schedule_from_id
        , frequency_days
        , DATE_ADD(schedule_from_date, INTERVAL frequency_days * 24 HOUR) AS next_due_date
	FROM chore_completions_schedule_from_dates
    NATURAL JOIN chore_completions
    NATURAL JOIN chore_frequencies
    ORDER BY chore_completion_id