USE chores;

DROP VIEW IF EXISTS incomplete_chores;

CREATE VIEW incomplete_chores
AS
SELECT chore_id
        , chore_measured
        , chore_completion_id
        , due_date
        , last_completed
        , duration_minutes
        , completed_minutes
        , remaining_minutes
        , stdev_duration_minutes
        , remaining_minutes + (1.645 * stdev_duration_minutes) AS `95% CI UB`
    FROM incomplete_chores_progress
