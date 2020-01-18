USE chores;

DROP VIEW IF EXISTS completion_time_for_unknown_duration_history_otherwise;

CREATE VIEW completion_time_for_unknown_duration_history_otherwise
AS
WITH history_from_completion_times AS (SELECT chore_completion_times.chore_completion_id
        , `from`
        , when_completed AS `to`
        , chore_completion_status_history.chore_completion_status_id
    FROM chore_completion_times
    NATURAL JOIN chore_completions
    INNER JOIN chore_completion_status_history
        ON chore_completions.chore_completion_id = chore_completion_status_history.chore_completion_id
        AND chore_completion_status_since = `to`
    WHERE chore_completions.chore_completion_status_id = 3 /* unknown duration */)
SELECT chore_completion_id, `from`, `to`, chore_completion_status_id
    FROM history_from_completion_times
UNION
SELECT chore_completion_id, `from`, `to`, chore_completion_status_id
    FROM chore_completion_status_history
    WHERE chore_completion_id NOT IN (SELECT chore_completion_id
            FROM history_from_completion_times);
