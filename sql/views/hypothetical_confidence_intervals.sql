USE chores;

CREATE OR REPLACE VIEW hypothetical_confidence_intervals
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
        , students_t_critical_values.degrees_of_freedom AS hypothetical_degrees_of_freedom
        , students_t_critical_values.critical_value AS hypothetical_critical_value
        , EXP(log_normal_confidence_bound(mean_log_duration_minutes, sd_log_duration_minutes, students_t_critical_values.degrees_of_freedom + 1, students_t_critical_values.critical_value)) AS `hypothetical 95% CI UB`
    FROM chore_duration_confidence_intervals
    LEFT JOIN students_t_critical_values
        ON one_tail_confidence = 0.05
        AND chore_duration_confidence_intervals.degrees_of_freedom <= students_t_critical_values.degrees_of_freedom;
