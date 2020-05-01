USE chores;

DROP VIEW IF EXISTS chore_durations;

CREATE VIEW chore_durations
AS
SELECT chore_id
        , 0 AS aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , 0 AS aggregate_by_id
    FROM chore_durations_by_empty
UNION
SELECT chore_id
        , week_day AS aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , 1 AS aggregate_by_id
    FROM chore_durations_by_weekday
UNION
SELECT chore_id
        , weekendity AS aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , 2 AS aggregate_by_id
    FROM chore_durations_by_weekendity
