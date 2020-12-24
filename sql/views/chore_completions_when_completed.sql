USE chores;

CREATE OR REPLACE VIEW chore_completions_when_completed
AS
WITH when_completed AS (SELECT 'chore_completion_times' AS `source`
        , chore_completion_id
        , when_completed
    FROM hierarchical_chore_completion_times
UNION ALL
SELECT 'chore_sessions' AS `source`
        , chore_completion_id
        , MAX(when_completed) AS when_completed
    FROM hierarchical_chore_sessions
    WHERE chore_completion_id NOT IN (SELECT chore_completion_id
            FROM hierarchical_chore_completion_times)
    GROUP BY chore_completion_id
UNION ALL
SELECT 'chore_completions' AS `source`
        , chore_completion_id
        , chore_completion_status_since
    FROM chore_completions
    WHERE chore_completion_status_id = 3 # No chore sessions
        AND chore_completion_id NOT IN (SELECT chore_completion_id
                FROM hierarchical_chore_completion_times)
        AND chore_completion_id NOT IN (SELECT chore_completion_id
                FROM hierarchical_chore_sessions))
SELECT `source`
        , chore_completion_id
        , when_completed
    FROM when_completed
    JOIN chore_completions USING (chore_completion_id)
    WHERE chore_completion_status_id != 1; # scheduled
