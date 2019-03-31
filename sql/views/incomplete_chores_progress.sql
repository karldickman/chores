USE chores;

DROP VIEW IF EXISTS incomplete_chores_progress;

CREATE VIEW incomplete_chores_progress
AS
SELECT chore_completion_id
    , chore_id
    , due_date
    , last_completed
    , times_completed
    , completed_minutes
    , remaining_minutes
    , stdev_duration_minutes
	FROM incomplete_measured_chores_progress 
UNION
SELECT chore_completion_id
    , chore_id
    , due_date
    , last_completed
    , 0 AS times_completed
    , completed_minutes
    , remaining_minutes
    , stdev_duration_minutes
	FROM never_measured_chores_progress