DROP VIEW IF EXISTS chore_stderrs;

CREATE VIEW chore_stderrs
AS
SELECT chore_id
        , aggregate_key
        , chore
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , COALESCE(stdev_duration_minutes, 3.402823466E+38) AS stdev_duration_minutes
        , COALESCE(stdev_duration_minutes, 3.402823466E+38) / SQRT(times_completed) AS stderr_duration_minutes
        , aggregate_by_id
    FROM chore_durations
    NATURAL JOIN chores
UNION
SELECT chores.chore_id
        , aggregate_key
        , chore
        , 0 AS times_completed
        , NULL AS avg_number_of_sessions
        , avg_duration_minutes
        , 3.402823466E+38 AS stdev_duration_minutes
        , 3.402823466E+38 AS stderr_duration_minutes
        , aggregate_by_id
    FROM chores
    NATURAL JOIN aggregate_keys
    CROSS JOIN all_chore_durations
    WHERE chores.chore_id NOT IN (SELECT chore_id
            FROM chore_durations)