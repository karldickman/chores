USE chores;

CREATE OR REPLACE VIEW hypothetical_critical_values_with_unlimited_degrees_of_freedom
AS
SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , times_completed
        , mean_number_of_sessions
        , arithmetic_mean_duration_minutes
        , arithmetic_sd_duration_minutes
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , mean_duration_minutes
        , sd_duration_minutes
        , chore_duration_confidence_intervals.degrees_of_freedom
        , chore_duration_confidence_intervals.one_tail_critical_value
        , `one tail 95% CI UB`
        , students_t_critical_values_unlimited_degrees_of_freedom.critical_value AS hypothetical_critical_value
    FROM chore_duration_confidence_intervals
    JOIN students_t_critical_values_unlimited_degrees_of_freedom
        ON one_tail_confidence = 0.05;
