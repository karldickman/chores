USE chores;

CREATE OR REPLACE VIEW chore_completion_aggregate_keys
AS
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
        , due_date
        , due_date_since
        , `source` AS when_completed_source
        , when_completed
        , CASE
            WHEN aggregate_by_id = 0 # empty
                THEN 0
            WHEN aggregate_by_id = 2 # weekendity
                THEN weekendity(COALESCE(due_date, when_completed))
            END AS aggregate_key
    FROM chore_completions
    JOIN chores USING (chore_id)
    LEFT JOIN chore_schedule USING (chore_completion_id)
    LEFT JOIN chore_completions_when_completed USING (chore_completion_id);