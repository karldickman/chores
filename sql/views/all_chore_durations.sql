USE chores;

DROP VIEW IF EXISTS all_chore_durations;

CREATE VIEW all_chore_durations
AS
WITH chore_statistics AS (SELECT COUNT(DISTINCT chore_id) AS number_of_chores_with_data
        , AVG(avg_duration_minutes) AS avg_duration_minutes
        , SQRT(SUM(POW(COALESCE(stdev_duration_minutes, 480), 2))) / COUNT(DISTINCT chore_id) AS stdev_duration_minutes
    FROM chore_durations),
critical_value AS (SELECT number_of_chores_with_data
        , avg_duration_minutes
        , stdev_duration_minutes
        , COALESCE(interpolated_critical_values.critical_value, students_t_critical_values_unlimited_degrees_of_freedom.critical_value) AS critical_value
    FROM chore_statistics
    JOIN students_t_critical_values_unlimited_degrees_of_freedom
        ON students_t_critical_values_unlimited_degrees_of_freedom.one_tail_confidence = 0.025
    LEFT JOIN interpolated_critical_values
        ON students_t_critical_values_unlimited_degrees_of_freedom.one_tail_confidence = interpolated_critical_values.one_tail_confidence
        AND number_of_chores_with_data - 1 = degrees_of_freedom)
SELECT number_of_chores_with_data
        , avg_duration_minutes
        , stdev_duration_minutes
        , critical_value
        , avg_duration_minutes + critical_value * stdev_duration_minutes AS `95% CI UB`
    FROM critical_value;
