USE chores;

#DROP VIEW all_chore_durations;

CREATE OR REPLACE VIEW all_chore_durations
AS
WITH chore_statistics AS (SELECT COUNT(DISTINCT chore_id) AS number_of_chores_with_data
        , AVG(avg_duration_minutes) AS avg_duration_minutes
        , SQRT(SUM(POW(COALESCE(stdev_duration_minutes, 480), 2))) / COUNT(DISTINCT chore_id) AS stdev_duration_minutes
    FROM chore_durations)
SELECT number_of_chores_with_data
        , avg_duration_minutes
        , stdev_duration_minutes
        , critical_value
        , avg_duration_minutes + critical_value * stdev_duration_minutes AS `95% CI UB`
    FROM chore_statistics
    JOIN students_t_critical_values_unlimited_degrees_of_freedom
        WHERE one_tail_confidence = 0.05;
