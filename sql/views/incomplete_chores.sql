USE chores;

DROP VIEW IF EXISTS incomplete_chores;

CREATE VIEW incomplete_chores
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
        , avg_log_duration_minutes + critical_value * stdev_log_duration_minutes AS `log 95% CI UB`
        , duration_minutes
        , completed_minutes
        , remaining_minutes
        , stdev_duration_minutes
        , critical_value
        , `95% CI UB`
    FROM incomplete_chores_progress;
