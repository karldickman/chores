USE chores;

#DROP VIEW chore_duration_confidence_intervals;

CREATE OR REPLACE VIEW chore_duration_confidence_intervals
AS
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , stdev_duration_minutes
        , times_completed - 1 AS degrees_of_freedom
        , COALESCE(students_t_critical_values.critical_value, students_t_critical_values_unlimited_degrees_of_freedom.critical_value) AS critical_value
        , EXP(log_normal_confidence_bound(avg_log_duration_minutes, stdev_log_duration_minutes, times_completed, COALESCE(students_t_critical_values.critical_value, students_t_critical_values_unlimited_degrees_of_freedom.critical_value))) AS `95% CI UB`
    FROM chore_durations
    LEFT JOIN students_t_critical_values
        ON one_tail_confidence = 0.05
        AND times_completed - 1 = degrees_of_freedom
    LEFT JOIN students_t_critical_values_unlimited_degrees_of_freedom
        ON students_t_critical_values_unlimited_degrees_of_freedom.one_tail_confidence = 0.05
        AND times_completed - 1 > (SELECT MAX(degrees_of_freedom) FROM students_t_critical_values WHERE one_tail_confidence = 0.05);
