USE chores;

DROP VIEW IF EXISTS chore_durations_by_empty;

CREATE VIEW chore_durations_by_empty
AS
SELECT chore_id
        , COUNT(chore_completion_id) AS times_completed
        , AVG(1.0 * number_of_sessions) AS avg_number_of_sessions
        , AVG(duration_minutes) AS avg_duration_minutes
        , CASE
            WHEN COUNT(chore_completion_id) > 1
                THEN STD(duration_minutes)
            END AS stdev_duration_minutes
    FROM hierarchical_chore_completion_durations
    NATURAL JOIN chore_completions
    NATURAL JOIN chores
    WHERE chore_completion_status_id = 4 # Completed
        AND aggregate_by_id = 0 # Empty
    GROUP BY chore_id