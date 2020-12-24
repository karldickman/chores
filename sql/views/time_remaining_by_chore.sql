USE chores;

CREATE OR REPLACE VIEW time_remaining_by_chore
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
        , FALSE AS is_completed
        , NULL AS when_completed
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
        , central_tendency_duration_minutes
        , completed_minutes
        , hierarchical_completed_minutes
        , remaining_minutes
        , critical_value
        , `95% CI UB`
    FROM incomplete_chores_progress
    # Exclude hierarchical chores with incomplete children
    WHERE chore_completion_id NOT IN (SELECT parent_chore_completion_id
            FROM chore_completion_hierarchy
            JOIN chore_completions USING (chore_completion_id)
            WHERE chore_completion_status_id = 1) # scheduled
UNION
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
        , TRUE AS is_completed
        , when_completed
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
        , duration_minutes
        , duration_minutes AS completed_minutes
        , NULL AS hierarchical_completed_minutes
        , 0 AS remaining_minutes
        , NULL AS critical_value
        , 0 AS `95% CI UB`
    FROM chore_completion_durations_measured_and_unmeasured
    JOIN hierarchical_chore_schedule USING (chore_completion_id)
    JOIN chore_durations USING (chore_id)
    LEFT JOIN last_chore_completion_times USING (chore_id);