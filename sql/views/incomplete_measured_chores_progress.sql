USE chores;

DROP VIEW IF EXISTS incomplete_measured_chores_progress;

CREATE VIEW incomplete_measured_chores_progress
AS
WITH incomplete_chore_completions AS (SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
    FROM chore_completions
    INNER JOIN chore_schedule USING (chore_completion_id)
    WHERE chore_completion_status_id = 1 /* Incomplete */),
chore_completion_durations_by_empty AS (SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
    FROM incomplete_chore_completions
    INNER JOIN chore_durations_by_empty USING (chore_id)),
chore_completion_durations_by_weekday AS (SELECT chore_completion_id
        , incomplete_chore_completions.chore_id
        , chore_durations_by_weekday.week_day
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
    FROM incomplete_chore_completions
    INNER JOIN chore_durations_by_weekday
        ON incomplete_chore_completions.chore_id = chore_durations_by_weekday.chore_id
        AND WEEKDAY(due_date) = chore_durations_by_weekday.week_day),
chore_completion_durations_by_weekendity AS (SELECT chore_completion_id
        , incomplete_chore_completions.chore_id
        , chore_durations_by_weekendity.weekendity
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
    FROM incomplete_chore_completions
    INNER JOIN chore_durations_by_weekendity
        ON incomplete_chore_completions.chore_id = chore_durations_by_weekendity.chore_id
        AND weekendity(due_date) = chore_durations_by_weekendity.weekendity),
chore_completion_durations AS (SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
    FROM chore_completion_durations_by_empty
UNION
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
    FROM chore_completion_durations_by_weekday
UNION
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
    FROM chore_completion_durations_by_weekendity)
SELECT chore_completions.chore_completion_id
        , chore_completions.chore_id
        , TRUE AS chore_measured
        , due_date
        , last_completed
        , times_completed
        , chore_completions.avg_duration_minutes AS duration_minutes
        , COALESCE(chore_completion_durations.duration_minutes, 0) AS completed_minutes
        , chore_completions.avg_duration_minutes - COALESCE(hierarchical_chore_completion_durations.duration_minutes, 0) AS remaining_minutes
        , COALESCE(chore_completions.stdev_duration_minutes, all_chore_durations.stdev_duration_minutes) AS stdev_duration_minutes
    FROM chore_completion_durations AS chore_completions
    LEFT OUTER JOIN last_chore_completion_times
        ON chore_completions.chore_id = last_chore_completion_times.chore_id
    LEFT OUTER JOIN chores.chore_completion_durations
        ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
    LEFT OUTER JOIN hierarchical_chore_completion_durations
        ON chore_completions.chore_completion_id = hierarchical_chore_completion_durations.chore_completion_id
    CROSS JOIN all_chore_durations