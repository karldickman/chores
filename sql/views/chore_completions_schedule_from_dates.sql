DROP VIEW IF EXISTS chore_completions_schedule_from_dates;
CREATE VIEW chore_completions_schedule_from_dates
AS
SELECT chore_completion_id
		, when_completed AS schedule_from_date
        , schedule_from_id
	FROM chore_completions_schedule_from
    NATURAL JOIN chore_completions_when_completed
    WHERE schedule_from_id = 1 # Completion time
UNION
SELECT chore_completion_id
		, due_date
        , schedule_from_id
	FROM chore_completions_schedule_from
    NATURAL JOIN chore_schedule
    WHERE schedule_from_id = 2 # Due date