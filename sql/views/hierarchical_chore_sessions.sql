USE chores;

DROP VIEW IF EXISTS hierarchical_chore_sessions;

CREATE VIEW hierarchical_chore_sessions
AS
SELECT chore_completion_id
				, chore_session_id
				, when_completed
				, duration_minutes
	FROM chore_completions
	NATURAL JOIN chore_sessions
UNION
SELECT parent_chore_completion_id
		, chore_session_id
		, when_completed
		, duration_minutes
	FROM chore_completion_hierarchy
	NATURAL JOIN chore_sessions
	NATURAL JOIN chores_measured_hierarchically