USE chores;

DROP VIEW IF EXISTS chore_completions_schedule_from_dates;

CREATE VIEW chore_completions_schedule_from_dates
AS
SELECT chore_completions_schedule_from.chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , frequency_since
        , chore_schedule_from_id
        , chore_schedule_from_id_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , CASE
            WHEN schedule_from_id = 1 # Completion time
                THEN when_completed
            WHEN schedule_from_id = 2 # Due date
                THEN due_date
            END AS schedule_from_date
    FROM chore_completions_schedule_from
    LEFT OUTER JOIN chore_completions_when_completed
        ON chore_completions_schedule_from.chore_completion_id = chore_completions_when_completed.chore_completion_id
