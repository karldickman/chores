USE chores;

DROP VIEW IF EXISTS incomplete_chores_progress;

CREATE VIEW incomplete_chores_progress
AS
SELECT chore_completion_id
        , chore_id
        , chore
        , chore_measured
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , last_completed
        , times_completed
        , avg_number_of_sessions
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , duration_minutes
        , completed_minutes
        , remaining_minutes
        , stdev_duration_minutes
        , critical_value
        , `95% CI UB`
    FROM incomplete_measured_chores_progress 
UNION
SELECT chore_completion_id
        , chore_id
        , chore
        , chore_measured
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , last_completed
        , 0 AS times_completed
        , NULL AS avg_number_of_sessions
        , NULL AS avg_log_duration_minutes
        , NULL AS stdev_log_duration_minutes
        , duration_minutes
        , completed_minutes
        , remaining_minutes
        , stdev_duration_minutes
        , critical_value
        , `95% CI UB`
    FROM never_measured_chores_progress
    JOIN chores USING (chore_id)
    JOIN aggregate_keys USING (aggregate_by_id);
