USE chores;

DROP VIEW IF EXISTS never_measured_chores_progress;

CREATE VIEW never_measured_chores_progress
AS
SELECT chore_completions.chore_completion_id
        , chore_completions.chore_id
        , FALSE AS chore_measured
        , due_date
        , last_completed
        , avg_duration_minutes AS duration_minutes
        , COALESCE(chore_completion_durations.duration_minutes, 0) AS completed_minutes
        , avg_duration_minutes - COALESCE(hierarchical_chore_completion_durations.duration_minutes, 0) AS remaining_minutes
        , stdev_duration_minutes
    FROM chore_completions
    NATURAL JOIN chore_schedule
    NATURAL JOIN all_chore_durations
    LEFT OUTER JOIN chore_completion_durations
        ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
    LEFT OUTER JOIN hierarchical_chore_completion_durations
        ON chore_completions.chore_completion_id = hierarchical_chore_completion_durations.chore_completion_id
    LEFT OUTER JOIN last_chore_completion_times
        ON chore_completions.chore_id = last_chore_completion_times.chore_id
    WHERE chore_completion_status_id = 1
        AND chore_completions.chore_completion_id NOT IN (SELECT chore_completion_id
                FROM incomplete_measured_chores_progress)
