USE chores;

DROP VIEW IF EXISTS chore_completions_schedule_from_dates;

CREATE VIEW chore_completions_schedule_from_dates
AS
SELECT chore_completion_id
        , chore_completion_status_id
        , due_date
        , when_completed AS schedule_from_date
        , schedule_from_id
    FROM chore_completions_schedule_from
    NATURAL JOIN chore_completions_when_completed
    WHERE schedule_from_id = 1 # Completion time
UNION
SELECT chore_completion_id
        , chore_completion_status_id
        , due_date
        , due_date AS schedule_from_date
        , schedule_from_id
    FROM chore_completions_schedule_from
    NATURAL JOIN chore_schedule
    WHERE schedule_from_id = 2 # Due date
UNION
SELECT chore_completion_id
        , chore_completion_status_id
        , due_date
        , due_date AS schedule_from_date
        , 2 AS schedule_from_id # Due date
    FROM chore_completions
    NATURAL JOIN chore_schedule
    WHERE chore_completion_status_id = 1 # Scheduled
