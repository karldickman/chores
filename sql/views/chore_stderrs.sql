DROP VIEW IF EXISTS chore_stderrs;

CREATE VIEW chore_stderrs
AS
WITH stderr AS (SELECT chore_id
        , chore
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , COALESCE(stdev_duration_minutes, 3.402823466E+38) AS stdev_duration_minutes
        , COALESCE(stdev_duration_minutes, 3.402823466E+38) / SQRT(times_completed) AS stderr_duration_minutes
    FROM chore_durations
    NATURAL JOIN chores
UNION
SELECT chore_id
        , chore
        , 0 AS times_completed
        , NULL AS avg_number_of_sessions
        , avg_duration_minutes
        , 3.402823466E+38 AS stdev_duration_minutes
        , 3.402823466E+38 AS stderr_duration_minutes
    FROM chores
    CROSS JOIN all_chore_durations
    WHERE chore_id NOT IN (SELECT chore_id
            FROM chore_durations)),
confidence_intervals AS (SELECT chore_id
        , chore
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , stderr_duration_minutes
        , 1.96 * stderr_duration_minutes AS `95% CI`
    FROM stderr)
SELECT chore_id
        , chore
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , stderr_duration_minutes
        , `95% CI`
    FROM confidence_intervals