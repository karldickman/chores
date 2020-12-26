USE chores;

CREATE OR REPLACE VIEW incomplete_measured_chores_progress
AS
WITH incomplete_chore_completions AS (SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
    FROM chore_completions
    INNER JOIN chore_schedule USING (chore_completion_id)
    WHERE chore_completion_status_id = 1 /* Incomplete */),
expected_duration_and_completed AS (SELECT chore_completion_id
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
        , COALESCE(chore_completion_durations.duration_minutes, 0) AS completed_minutes
        , COALESCE(hierarchical_chore_completion_durations.duration_minutes, 0) AS hierarchical_completed_minutes
    FROM incomplete_chore_completions
    JOIN chore_durations USING (chore_id)
    LEFT JOIN last_chore_completion_times USING (chore_id)
    LEFT JOIN chore_completion_durations USING (chore_completion_id)
    LEFT JOIN hierarchical_chore_completion_durations USING (chore_completion_id)
    WHERE aggregate_by_id = 0
        OR aggregate_by_id = 2 AND weekendity(due_date) = aggregate_key)
SELECT TRUE AS chore_measured
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
        , completed_minutes
        , hierarchical_completed_minutes
        , median_duration_minutes - hierarchical_completed_minutes AS remaining_minutes
        , `value` * EXP(mean_log_duration_minutes) AS `95%ile`
    FROM expected_duration_and_completed
    LEFT JOIN log_normal_quantiles
        ON ABS(sd_log_duration_minutes - log_normal_standard_deviation) < 0.0005
        AND quantile = 0.95;
