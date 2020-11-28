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
        , chore
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , aggregate_by_id
        , completions_per_day
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
    FROM incomplete_chore_completions
    JOIN chore_durations_by_empty USING (chore_id)),
chore_completion_durations_by_weekendity AS (SELECT chore_completion_id
        , incomplete_chore_completions.chore_id
        , chore
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , aggregate_by_id
        , completions_per_day
        , chore_durations_by_weekendity.weekendity
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
    FROM incomplete_chore_completions
    JOIN chore_durations_by_weekendity
        ON incomplete_chore_completions.chore_id = chore_durations_by_weekendity.chore_id
        AND weekendity(due_date) = chore_durations_by_weekendity.weekendity),
chore_completion_durations AS (SELECT chore_completion_id
        , chore_id
        , chore
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
    FROM chore_completion_durations_by_empty
    JOIN aggregate_keys USING (aggregate_by_id)
UNION
SELECT chore_completion_id
        , chore_id
        , chore
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , aggregate_by_id
        , completions_per_day
        , weekendity
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
    FROM chore_completion_durations_by_weekendity),
durations_and_critical_values AS (SELECT chore_completion_id
        , chore_id
        , chore
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , last_completed
        , times_completed
        , avg_number_of_sessions
        , chore_completions.avg_log_duration_minutes AS avg_log_duration_minutes
        , chore_completions.stdev_log_duration_minutes
        , EXP(chore_completions.avg_log_duration_minutes) AS duration_minutes
        , COALESCE(chore_completion_durations.duration_minutes, 0) AS completed_minutes
        , COALESCE(hierarchical_chore_completion_durations.duration_minutes, 0) AS hierarchical_duration_minutes
        , COALESCE(chore_completions.stdev_duration_minutes, all_chore_durations.stdev_duration_minutes) AS stdev_duration_minutes
        , COALESCE(interpolated_critical_values.critical_value, students_t_critical_values_unlimited_degrees_of_freedom.critical_value) AS critical_value
    FROM chore_completion_durations AS chore_completions
    LEFT JOIN last_chore_completion_times USING (chore_id)
    LEFT JOIN chores.chore_completion_durations USING (chore_completion_id)
    LEFT JOIN hierarchical_chore_completion_durations USING (chore_completion_id)
    CROSS JOIN all_chore_durations
    JOIN students_t_critical_values_unlimited_degrees_of_freedom
        ON students_t_critical_values_unlimited_degrees_of_freedom.one_tail_confidence = 0.025
    LEFT JOIN interpolated_critical_values
        ON students_t_critical_values_unlimited_degrees_of_freedom.one_tail_confidence = interpolated_critical_values.one_tail_confidence
        AND times_completed - 1 = degrees_of_freedom)
SELECT chore_completion_id
        , chore_id
        , chore
        , TRUE AS chore_measured
        , due_date
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , last_completed
        , times_completed
        , avg_number_of_sessions
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , duration_minutes
        , completed_minutes
        , duration_minutes - hierarchical_duration_minutes AS remaining_minutes
        , stdev_duration_minutes
        , critical_value
        , EXP(avg_log_duration_minutes + critical_value * stdev_log_duration_minutes) - completed_minutes AS `95% CI UB`
    FROM durations_and_critical_values;
