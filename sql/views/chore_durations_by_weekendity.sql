USE chores;

CREATE OR REPLACE VIEW chore_durations_by_weekendity
AS
WITH summary as (SELECT chore_id
        , weekendity(when_completed) AS weekendity
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
    JOIN chore_completions USING (chore_completion_id)
    JOIN chores USING (chore_id)
    WHERE chore_completion_status_id = 4 # Completed
        AND aggregate_by_id = 2 # Weekendity
    GROUP BY chore_id, weekendity(when_completed))
SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , is_active
        , weekendity
        , times_completed
        , mean_number_of_sessions
        , mean_duration_minutes
        , sd_duration_minutes
        , mean_log_duration_minutes
        , sd_log_duration_minutes
    FROM summary
    JOIN chores USING (chore_id);
