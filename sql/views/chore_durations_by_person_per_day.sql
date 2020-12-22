USE chores;

CREATE OR REPLACE VIEW chore_durations_by_person_per_day
AS
SELECT period_type_id
        , chore_id
        , chore
        , period
        , period_unit_id
        , period_days
        , completions_per_day
        , period_since
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
        , mean_duration_per_day
        , sd_duration_minutes
        , daily
        , weekly
        , weekendity
        , person_id
    FROM chore_durations_per_day
    JOIN chore_people USING (chore_id);
