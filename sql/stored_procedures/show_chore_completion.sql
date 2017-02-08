USE chores;
DROP PROCEDURE IF EXISTS show_chore_completion;

DELIMITER $$
USE chores$$
CREATE PROCEDURE show_chore_completion(chore_completion_id_to_show INT)
BEGIN
	SELECT chore
			, chore_session_id
			, duration_minutes
			, when_completed
			, when_recorded
		FROM chore_completions
		NATURAL JOIN chores
		LEFT OUTER JOIN chore_sessions
			ON chore_completions.chore_completion_id = chore_sessions.chore_completion_id
		WHERE chore_completions.chore_completion_id = chore_completion_id_to_show
	UNION
    SELECT chore
			, chore_session_id
			, duration_minutes
			, when_completed
			, when_recorded
		FROM chore_completions
		NATURAL JOIN chores
        INNER JOIN chore_completion_hierarchy
			ON chore_completions.chore_completion_id = chore_completion_hierarchy.parent_chore_completion_id
		LEFT OUTER JOIN chore_sessions
			ON chore_completion_hierarchy.chore_completion_id = chore_sessions.chore_completion_id
		WHERE chore_completions.chore_completion_id = chore_completion_id_to_show;
END$$

DELIMITER ;