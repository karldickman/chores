USE chores;

CREATE OR REPLACE VIEW chore_duration_confidence_intervals
AS
SELECT chore_id
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
        , times_completed - 1 AS degrees_of_freedom
        , COALESCE(one_tail_critical_values.critical_value, one_tail_critical_values_unlimited_df.critical_value) AS one_tail_critical_value
        , EXP(log_normal_confidence_bound(mean_log_duration_minutes, sd_log_duration_minutes, times_completed, COALESCE(one_tail_critical_values.critical_value, one_tail_critical_values_unlimited_df.critical_value))) AS `one tail 95% CI UB`
        , COALESCE(two_tail_critical_values.critical_value, two_tail_critical_values_unlimited_df.critical_value) AS two_tail_critical_value
        , EXP(log_normal_confidence_bound(mean_log_duration_minutes, sd_log_duration_minutes, times_completed, -COALESCE(two_tail_critical_values.critical_value, two_tail_critical_values_unlimited_df.critical_value))) AS `two tail 95% CI LB`
        , EXP(log_normal_confidence_bound(mean_log_duration_minutes, sd_log_duration_minutes, times_completed, COALESCE(two_tail_critical_values.critical_value, two_tail_critical_values_unlimited_df.critical_value))) AS `two tail 95% CI UB`
    FROM chore_durations
    LEFT JOIN students_t_critical_values AS one_tail_critical_values
        ON one_tail_confidence = 0.05
        AND times_completed - 1 = degrees_of_freedom
    LEFT JOIN students_t_critical_values_unlimited_degrees_of_freedom AS one_tail_critical_values_unlimited_df
        ON one_tail_critical_values_unlimited_df.one_tail_confidence = 0.05
        AND times_completed - 1 > (SELECT MAX(degrees_of_freedom)
                FROM students_t_critical_values
                WHERE one_tail_confidence = 0.05)
    LEFT JOIN students_t_critical_values AS two_tail_critical_values
        ON two_tail_critical_values.one_tail_confidence = 0.025
        AND times_completed - 1 = two_tail_critical_values.degrees_of_freedom
    LEFT JOIN students_t_critical_values_unlimited_degrees_of_freedom AS two_tail_critical_values_unlimited_df
        ON two_tail_critical_values_unlimited_df.one_tail_confidence = 0.025
        AND times_completed - 1 > (SELECT MAX(degrees_of_freedom)
                FROM students_t_critical_values
                WHERE one_tail_confidence = 0.025);
