USE chores;

#DROP VIEW never_measured_chores_progress;

CREATE OR REPLACE VIEW never_measured_chores_progress
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
        , critical_value
        , `95% CI UB`
    FROM chore_completions
    JOIN chore_schedule USING (chore_completion_id)
    CROSS JOIN all_chore_durations
    LEFT JOIN chore_completion_durations USING (chore_completion_id)
    LEFT JOIN hierarchical_chore_completion_durations USING (chore_completion_id)
    LEFT JOIN last_chore_completion_times USING (chore_id)
    WHERE chore_completion_status_id = 1
        AND chore_completion_id NOT IN (SELECT chore_completion_id
                FROM incomplete_measured_chores_progress)
