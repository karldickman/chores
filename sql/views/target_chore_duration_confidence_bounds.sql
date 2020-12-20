USE chores;

CREATE OR REPLACE VIEW target_chore_duration_confidence_bounds
AS
WITH inequality_coefficients AS (SELECT 'absolute' AS confidence_interval_type
        , chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
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
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , mean_duration_minutes + 0.5 AS target_confidence_bound
        , LOG(mean_duration_minutes + 0.5) AS log_target_confidence_bound
        , POWER(LOG(1 + 0.5 / mean_duration_minutes)
            / (one_tail_critical_value * sd_log_duration_minutes), 2) AS log_target_over_critical_value
    FROM hypothetical_critical_values_with_unlimited_degrees_of_freedom
UNION
SELECT 'relative' AS confidence_interval_type
        , chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
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
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , mean_duration_minutes * 1.05 AS target_confidence_bound
        , LOG(mean_duration_minutes * 1.05) AS log_target_confidence_bound
        , POWER(LOG(1.05)
            / (one_tail_critical_value * sd_log_duration_minutes), 2) AS log_target_over_critical_value
    FROM hypothetical_critical_values_with_unlimited_degrees_of_freedom),
quadratic_coefficients AS (SELECT confidence_interval_type
        , chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
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
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , target_confidence_bound
        , log_target_confidence_bound
        , log_target_over_critical_value
        , -2 * log_target_over_critical_value AS A
        , (POWER(sd_log_duration_minutes, 2) + 2 * log_target_over_critical_value + 2) AS B
        , -2 AS C
    FROM inequality_coefficients)
SELECT confidence_interval_type
        , chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
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
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , target_confidence_bound
        , log_target_confidence_bound
        , log_target_over_critical_value
        , A
        , B
        , C
        , CEIL((-B - SQRT(POWER(B, 2) - 4 * A * C)) / (2 * A) - times_completed) AS completions_needed
    FROM quadratic_coefficients;
