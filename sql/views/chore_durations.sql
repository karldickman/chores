USE chores;

#DROP VIEW chore_durations;

CREATE OR REPLACE VIEW chore_durations
AS
WITH `union` AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
    FROM chore_durations_by_empty
    JOIN aggregate_keys USING (aggregate_by_id)
UNION
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , weekendity AS aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
    FROM chore_durations_by_weekendity)
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes AS arithmetic_avg_duration_minutes
        , stdev_duration_minutes AS arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , EXP(avg_log_duration_minutes - POWER(stdev_log_duration_minutes, 2)) AS mode_duration_minutes
        , EXP(avg_log_duration_minutes) AS median_duration_minutes
        , EXP(avg_log_duration_minutes + POWER(stdev_log_duration_minutes, 2) / 2) AS avg_duration_minutes
        , SQRT((EXP(stdev_log_duration_minutes) - 1) * EXP(2 * avg_log_duration_minutes + POWER(stdev_log_duration_minutes, 2))) AS stdev_duration_minutes
    FROM `union`;
