USE chores;

DROP VIEW IF EXISTS chore_stderrs;

CREATE VIEW chore_stderrs
AS
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , COALESCE(stdev_duration_minutes, 3.402823466E+38) AS stdev_duration_minutes
        , COALESCE(stdev_duration_minutes, 3.402823466E+38) / SQRT(times_completed) AS stderr_duration_minutes
        , avg_log_duration_minutes
        , COALESCE(stdev_log_duration_minutes, 3.402823466E+38) AS stdev_log_duration_minutes
        , COALESCE(stdev_log_duration_minutes, 3.402823466E+38) / SQRT(times_completed) AS stderr_log_duration_minutes
    FROM chore_durations
UNION
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , 0 AS times_completed
        , NULL AS avg_number_of_sessions
        , avg_duration_minutes
        , 3.402823466E+38 AS stdev_duration_minutes
        , 3.402823466E+38 AS stderr_duration_minutes
        , avg_log_duration_minutes
        , 3.402823466E+38 AS stdev_log_duration_minutes
        , 3.402823466E+38 AS stderr_log_duration_minutes
    FROM chores
    JOIN aggregate_keys USING (aggregate_by_id)
    CROSS JOIN all_chore_durations
    WHERE chore_id NOT IN (SELECT chore_id
            FROM chore_durations)