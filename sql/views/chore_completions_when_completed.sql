DROP VIEW IF EXISTS chore_completions_when_completed;
CREATE VIEW chore_completions_when_completed
AS
SELECT chore_completion_id, when_completed
	FROM chore_completion_durations
UNION
SELECT chore_completion_id, when_completed
	FROM chore_completion_times
    WHERE chore_completion_id NOT IN (SELECT chore_completion_id
		FROM chore_sessions)