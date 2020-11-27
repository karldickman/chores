USE chores;

DROP VIEW IF EXISTS chore_durations_by_empty;

CREATE VIEW chore_durations_by_empty
AS
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , COUNT(chore_completion_id) AS times_completed
        , AVG(1.0 * number_of_sessions) AS avg_number_of_sessions
        , AVG(duration_minutes) AS avg_duration_minutes
        , CASE
            WHEN COUNT(chore_completion_id) > 1
                THEN STD(duration_minutes)
            END AS stdev_duration_minutes
        , AVG(log_duration_minutes) AS avg_log_duration_minutes
        , CASE
            WHEN COUNT(chore_completion_id) > 1
                THEN STD(log_duration_minutes)
            END AS stdev_log_duration_minutes
    FROM hierarchical_chore_completion_durations
    JOIN chore_completions USING (chore_completion_id)
    JOIN chores USING (chore_id)
    WHERE chore_completion_status_id = 4 # Completed
        AND aggregate_by_id = 0 # Empty
    GROUP BY chore_id, chore, aggregate_by_id, completions_per_day
