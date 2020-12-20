USE chores;

CREATE OR REPLACE VIEW completions_needed
AS
WITH confidence_interval_types AS (SELECT 'absolute' AS confidence_interval_type
UNION
SELECT 'relative' AS confidence_interval_type),
hypothetical_confidence_intervals_below_absolute_target AS (SELECT chore_id
        , MIN(hypothetical_degrees_of_freedom) AS hypothetical_degrees_of_freedom
        , MIN(hypothetical_degrees_of_freedom - degrees_of_freedom) AS completions_needed
    FROM hypothetical_confidence_intervals
    WHERE `hypothetical 95% CI UB` - mean_duration_minutes < 0.5
    GROUP BY chore_id),
hypothetical_confidence_intervals_below_relative_target AS (SELECT chore_id
        , MIN(hypothetical_degrees_of_freedom) AS hypothetical_degrees_of_freedom
        , MIN(hypothetical_degrees_of_freedom - degrees_of_freedom) AS completions_needed
    FROM hypothetical_confidence_intervals
    WHERE `hypothetical 95% CI UB` / mean_duration_minutes < 1.05
    GROUP BY chore_id),
hypothetical_confidence_intervals_below_target AS (SELECT 'absolute' AS confidence_interval_type
        , chore_id
        , hypothetical_degrees_of_freedom
        , completions_needed
    FROM hypothetical_confidence_intervals_below_absolute_target
UNION
SELECT 'relative' AS confidence_interval_type
        , chore_id
        , hypothetical_degrees_of_freedom
        , completions_needed
    FROM hypothetical_confidence_intervals_below_relative_target),
completions_needed_finite_df AS (SELECT chore_id
        , hypothetical_degrees_of_freedom
        , hypothetical_critical_value
    FROM hypothetical_confidence_intervals),
completions_needed_unlimited_df AS (SELECT confidence_interval_type
        , chore_id
        , aggregate_by_id
        , aggregate_key
        , hypothetical_critical_value
        , target_confidence_bound
        , log_target_confidence_bound
        , log_target_over_critical_value
        , A, B, C
        , completions_needed
    FROM target_chore_duration_confidence_bounds)
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
        , CASE
            WHEN confidence_interval_type = 'absolute'
                THEN `one tail 95% CI UB` - mean_duration_minutes
            WHEN confidence_interval_type = 'relative'
                THEN `one tail 95% CI UB` / mean_duration_minutes - 1
            END AS `one tail 95% CI`
        , hypothetical_degrees_of_freedom
        , COALESCE(completions_needed_finite_df.hypothetical_critical_value, completions_needed_unlimited_df.hypothetical_critical_value) AS hypothetical_critical_value
        , target_confidence_bound
        , log_target_confidence_bound
        , log_target_over_critical_value
        , A, B, C
        , CASE
            WHEN `one tail 95% CI UB` < target_confidence_bound
                THEN 0
            ELSE COALESCE(hypothetical_confidence_intervals_below_target.completions_needed, completions_needed_unlimited_df.completions_needed)
            END AS completions_needed
    FROM chore_duration_confidence_intervals
    JOIN confidence_interval_types
    LEFT JOIN hypothetical_confidence_intervals_below_target USING (chore_id, confidence_interval_type)
    LEFT JOIN completions_needed_finite_df USING (chore_id, hypothetical_degrees_of_freedom)
    LEFT JOIN completions_needed_unlimited_df USING (chore_id, confidence_interval_type, aggregate_by_id, aggregate_key);
