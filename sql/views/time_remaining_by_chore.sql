USE chores;

CREATE OR REPLACE VIEW time_remaining_by_chore
AS
WITH completed_chores AS (SELECT chore_id
        , chore
        , chore_completion_id
        , due_date
        , TRUE AS is_completed
        , 0 AS remaining_minutes
        , 0 AS `95% CI UB`
        , chore_completion_status_id
    FROM chore_completions
    JOIN chores USING (chore_id)
    LEFT JOIN hierarchical_chore_schedule AS chore_schedule USING (chore_completion_id)
    WHERE chore_completion_status_id IN (3, 4)) # completed, with or without recorded duration
# Incomplete
SELECT chore_id
        , chore
        , chore_completion_id
        , due_date
        , FALSE AS is_completed
        , NULL AS when_completed
        , duration_minutes
        , completed_minutes
        , remaining_minutes
        , `95% CI UB`
    FROM incomplete_chores_progress
    # Exclude hierarchical chores with incomplete children
    WHERE chore_completion_id NOT IN (SELECT parent_chore_completion_id
            FROM chore_completion_hierarchy
            JOIN chore_completions USING (chore_completion_id)
            WHERE chore_completion_status_id = 1) # scheduled
UNION
# Known duration
SELECT chore_id
        , chore
        , chore_completion_id
        , due_date
        , is_completed
        , when_completed
        , duration_minutes
        , duration_minutes AS completed_minutes
        , remaining_minutes
        , `95% CI UB`
    FROM completed_chores
    JOIN chore_completion_durations USING (chore_completion_id)
    WHERE chore_completion_status_id = 4 # completed
UNION
# Unknown duration
SELECT chore_id
        , completed_chores.chore
        , chore_completion_id
        , due_date
        , is_completed
        , when_completed
        , COALESCE(chore_durations.mean_duration_minutes, all_chore_durations.mean_duration_minutes) AS duration_minutes
        , COALESCE(chore_durations.mean_duration_minutes, all_chore_durations.mean_duration_minutes) AS completed_minutes
        , remaining_minutes
        , completed_chores.`95% CI UB`
    FROM completed_chores
    LEFT JOIN chore_completions_when_completed USING (chore_completion_id)
    LEFT JOIN chore_durations USING (chore_id)
    CROSS JOIN all_chore_durations
    WHERE chore_completion_status_id = 3; # completed without sufficient data
