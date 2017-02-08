USE chores;
DROP PROCEDURE IF EXISTS show_chore_completion;

DELIMITER $$
USE chores$$
CREATE PROCEDURE show_chore_completion(chore_completion_id_to_show INT)
BEGIN
	SELECT chore_completions.chore_completion_id
			, chore
			, chore_session_id
			, duration_minutes
			, when_completed
			, when_recorded
		FROM chore_completions
        NATURAL JOIN chores
        LEFT OUTER JOIN (SELECT chore_completion_id
					, chore_session_id
					, duration_minutes
					, when_completed
					, when_recorded
				FROM chore_completions
				NATURAL JOIN chore_sessions
			UNION
			SELECT parent_chore_completion_id
					, chore_session_id
					, duration_minutes
					, when_completed
					, when_recorded
				FROM chore_completions
				NATURAL JOIN chore_sessions
				NATURAL JOIN chore_completion_hierarchy) AS chore_sessions_and_child_sessions
			ON chore_completions.chore_completion_id = chore_sessions_and_child_sessions.chore_completion_id
		WHERE chore_completions.chore_completion_id = chore_completion_id_to_show;
END$$

DELIMITER ;