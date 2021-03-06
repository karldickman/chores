USE chores;

CREATE OR REPLACE VIEW never_measured_chores_progress
AS
SELECT chore_completions.chore_completion_id
        , chore_completions.chore_id
        , FALSE AS chore_measured
        , due_date
        , last_completed
        , mean_duration_minutes
        , COALESCE(chore_completion_durations.duration_minutes, 0) AS completed_minutes
        , mean_duration_minutes - COALESCE(hierarchical_chore_completion_durations.duration_minutes, 0) AS remaining_minutes
        , sd_duration_minutes
        , critical_value
        , `95%ile`
    FROM chore_completions
    JOIN chore_schedule USING (chore_completion_id)
    CROSS JOIN all_chore_durations
    LEFT JOIN chore_completion_durations USING (chore_completion_id)
    LEFT JOIN hierarchical_chore_completion_durations USING (chore_completion_id)
    LEFT JOIN last_chore_completion_times USING (chore_id)
    WHERE chore_completion_status_id = 1 # scheduled
        AND chore_id NOT IN (SELECT chore_id
                FROM chore_durations
                WHERE times_completed > 0);
