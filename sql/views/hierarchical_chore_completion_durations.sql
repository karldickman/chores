USE chores;

DROP VIEW IF EXISTS hierarchical_chore_completion_durations;

CREATE VIEW hierarchical_chore_completion_durations
AS
SELECT chore_completion_id
        , COUNT(chore_session_id) AS number_of_sessions
        , MAX(when_completed) AS when_completed
        , SUM(duration_minutes) AS duration_minutes
        , LOG(SUM(duration_minutes)) AS log_duration_minutes
    FROM hierarchical_chore_sessions
    GROUP BY chore_completion_id
