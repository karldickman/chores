USE chores;

CREATE OR REPLACE VIEW chore_durations_per_day
AS
WITH chore_completions_per_day AS (SELECT period_type_id
        , chore_id
        , period
        , period_unit_id
        , period_days
        , completions_per_day
        , period_since
    FROM chores.chore_completions_per_day)
SELECT period_type_id
        , chore_id
        , chore
        , period
        , period_unit_id
        , period_days
        , chore_completions_per_day.completions_per_day
        , period_since
        , aggregate_by_id
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
        , mean_duration_minutes * chore_completions_per_day.completions_per_day AS mean_duration_per_day
        , sd_duration_minutes
        , period_days < 4 AS daily
        , period_days <= 14 AS weekly
        , NOT ((chore_durations.aggregate_by_id = 0 AND period_days < 4
            OR chore_durations.aggregate_by_id = 2 AND aggregate_key = 0)) AS weekendity
    FROM chore_completions_per_day
    JOIN chore_durations USING (chore_id);
