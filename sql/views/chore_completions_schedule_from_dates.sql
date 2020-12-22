USE chores;

CREATE OR REPLACE VIEW chore_completions_schedule_from_dates
AS
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , CASE
            WHEN schedule_from_id = 1 # Completion time
                THEN when_completed
            WHEN schedule_from_id = 2 # Due date
                THEN due_date
            END AS schedule_from_date
    FROM chore_completions_schedule_from
    LEFT JOIN chore_completions_when_completed USING (chore_completion_id);
