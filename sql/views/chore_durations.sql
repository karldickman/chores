USE chores;

CREATE OR REPLACE VIEW chore_durations
AS
WITH `union` AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
        , aggregate_key
        , times_completed
        , mean_number_of_sessions
        , mean_duration_minutes
        , sd_duration_minutes
        , mean_log_duration_minutes
        , sd_log_duration_minutes
    FROM chore_durations_by_empty
    JOIN aggregate_keys USING (aggregate_by_id)
UNION
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
        , weekendity AS aggregate_key
        , times_completed
        , mean_number_of_sessions
        , mean_duration_minutes
        , sd_duration_minutes
        , mean_log_duration_minutes
        , sd_log_duration_minutes
    FROM chore_durations_by_weekendity)
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
        , aggregate_key
        , times_completed
        , mean_number_of_sessions
        , mean_duration_minutes AS arithmetic_mean_duration_minutes
        , sd_duration_minutes AS arithmetic_sd_duration_minutes
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , EXP(mean_log_duration_minutes - POWER(sd_log_duration_minutes, 2)) AS mode_duration_minutes
        , EXP(mean_log_duration_minutes) AS median_duration_minutes
        , EXP(mean_log_duration_minutes + POWER(sd_log_duration_minutes, 2) / 2) AS mean_duration_minutes
        , SQRT((EXP(sd_log_duration_minutes) - 1) * EXP(2 * mean_log_duration_minutes + POWER(sd_log_duration_minutes, 2))) AS sd_duration_minutes
    FROM `union`;
