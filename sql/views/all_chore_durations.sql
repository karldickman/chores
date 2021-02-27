USE chores;

CREATE OR REPLACE VIEW all_chore_durations
AS
WITH chore_statistics AS (SELECT COUNT(DISTINCT chore_id) AS number_of_chores_with_data
        , AVG(mean_duration_minutes) AS mean_duration_minutes
        , SQRT(SUM(POW(COALESCE(sd_duration_minutes, 480), 2))) / COUNT(DISTINCT chore_id) AS sd_duration_minutes
    FROM chore_durations)
SELECT number_of_chores_with_data
        , mean_duration_minutes
        , sd_duration_minutes
        , critical_value
        , mean_duration_minutes + critical_value * sd_duration_minutes AS `95%ile`
    FROM chore_statistics
    JOIN students_t_critical_values_unlimited_degrees_of_freedom
        WHERE one_tail_confidence = 0.05;
