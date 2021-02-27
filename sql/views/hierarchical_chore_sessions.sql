USE chores;

#DROP VIEW hierarchical_chore_sessions;

CREATE OR REPLACE VIEW hierarchical_chore_sessions
AS
SELECT FALSE AS hierarchical
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , chore_session_id
        , when_completed
        , duration_minutes
        , when_recorded
    FROM chore_completions
    JOIN chore_sessions USING (chore_completion_id)
UNION
SELECT TRUE AS hierarchical
        , parent_chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , chore_session_id
        , when_completed
        , duration_minutes
        , when_recorded
    FROM chore_completion_hierarchy
    JOIN chore_sessions USING (chore_completion_id)
    JOIN chore_completions
        ON parent_chore_completion_id = chore_completions.chore_completion_id
    JOIN chores_measured_hierarchically USING (chore_id);
