USE chores;

CREATE OR REPLACE VIEW incomplete_chores_progress
AS
SELECT chore_measured
        , chore_completion_id
        , chore_id
        , chore
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , last_completed
        , mean_number_of_sessions
        , arithmetic_mean_duration_minutes
        , arithmetic_sd_duration_minutes
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , mean_duration_minutes
        , sd_duration_minutes
        , median_duration_minutes AS central_tendency_duration_minutes
        , completed_minutes
        , hierarchical_completed_minutes
        , remaining_minutes
        , NULL AS critical_value
        , `95% CI UB`
    FROM incomplete_measured_chores_progress 
UNION
SELECT chore_measured
        , chore_completion_id
        , chore_id
        , chore
        , NULL AS chore_completion_status_id
        , NULL AS chore_completion_status_since
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , 0 AS times_completed
        , last_completed
        , NULL AS mean_number_of_sessions
        , mean_duration_minutes AS arithmetic_mean_duration_minutes
        , sd_duration_minutes AS arithmetic_sd_duration_minutes
        , NULL AS mean_log_duration_minutes
        , NULL AS sd_log_duration_minutes
        , NULL AS mode_duration_minutes
        , NULL AS median_duration_minutes
        , NULL AS mean_duration_minutes
        , NULL AS sd_duration_minutes
        , mean_duration_minutes AS central_tendency_duration_minutes
        , completed_minutes
        , NULL AS hierarchical_completed_minutes
        , remaining_minutes
        , critical_value
        , `95% CI UB`
    FROM never_measured_chores_progress
    JOIN chores USING (chore_id)
    JOIN aggregate_keys USING (aggregate_by_id);
