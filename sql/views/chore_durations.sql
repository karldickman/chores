USE chores;

CREATE OR REPLACE VIEW chore_durations
AS
WITH summary AS (SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , COUNT(chore_completion_id) AS times_completed
        , AVG(1.0 * number_of_sessions) AS mean_number_of_sessions
        , AVG(duration_minutes) AS mean_duration_minutes
        , CASE
            WHEN COUNT(chore_completion_id) > 1
                THEN STD(duration_minutes)
            END AS sd_duration_minutes
        , AVG(log_duration_minutes) AS mean_log_duration_minutes
        , CASE
            WHEN COUNT(chore_completion_id) > 1
                THEN STD(log_duration_minutes)
            END AS sd_log_duration_minutes
    FROM hierarchical_chore_completion_durations
    JOIN chore_completion_aggregate_keys USING (chore_completion_id)
    WHERE chore_completion_status_id = 4 # Completed
    GROUP BY chore_id, aggregate_by_id, aggregate_key)
SELECT chore_id
        , aggregate_by_id
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
    FROM summary;
