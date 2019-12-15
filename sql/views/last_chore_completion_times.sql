USE chores;

DROP VIEW IF EXISTS last_chore_completion_times;

CREATE VIEW last_chore_completion_times
AS
SELECT chore_id AS chore_id, MAX(when_completed) AS last_completed
    FROM all_chore_completion_times
    NATURAL JOIN chore_completions
    GROUP BY chore_id
