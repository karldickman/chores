USE chores;

CREATE OR REPLACE VIEW chore_completion_durations_measured_and_unmeasured
AS
# Known duration
SELECT TRUE AS chore_measured
        , 'chore_completion_durations' AS `source`
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , when_completed
        , duration_minutes
    FROM chore_completions
    JOIN chore_completion_durations USING (chore_completion_id)
    WHERE chore_completion_status_id = 4 # completed with known duration
UNION
# Unknown duration
SELECT TRUE AS chore_measured
        , 'chore_durations' AS `source`
        , chore_completion_id
        , chore_completions.chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , when_completed
        , mean_duration_minutes AS duration_minutes
    FROM chore_completions
    LEFT JOIN chore_completions_when_completed USING (chore_completion_id)
    LEFT JOIN hierarchical_chore_schedule USING (chore_completion_id)
    LEFT JOIN chore_durations
        ON chore_completions.chore_id = chore_durations.chore_id
        AND (aggregate_by_id = 0
            OR aggregate_by_id = 2 AND weekendity(due_date) = aggregate_key)
    WHERE chore_completion_status_id = 3
UNION
# Unknown duration, never measured chore
SELECT FALSE AS chore_measured
        , 'all_chore_durations' AS `source`
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , when_completed
        , mean_duration_minutes AS duration_minutes
    FROM chore_completions
    LEFT JOIN chore_completions_when_completed USING (chore_completion_id)
    CROSS JOIN all_chore_durations
    WHERE chore_completion_status_id = 3 # completed without sufficient data
        AND chore_id NOT IN (SELECT chore_id
                FROM chore_durations);
