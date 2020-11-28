USE chores;

DROP VIEW IF EXISTS chore_durations;

CREATE VIEW chore_durations
AS
SELECT chore_id
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
    FROM chore_durations_by_weekendity
