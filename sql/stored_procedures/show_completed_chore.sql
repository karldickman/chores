USE chores;
DROP PROCEDURE IF EXISTS show_completed_chore;

DELIMITER $$
USE chores$$
CREATE PROCEDURE show_completed_chore(chore_completion_id_to_show INT)
BEGIN
	SELECT chore_session_id
			, chore
			, duration_minutes
			, when_completed
			, when_recorded
		FROM chore_completions
		NATURAL JOIN chores
		NATURAL JOIN chore_sessions
		WHERE chore_completion_id = chore_completion_id_to_show
			AND chore_completion_status_id = 4
	UNION
    SELECT chore_session_id
			, chore
			, duration_minutes
			, when_completed
			, when_recorded
		FROM chore_completions
		NATURAL JOIN chores
		NATURAL JOIN chore_sessions
        NATURAL JOIN chore_completion_hierarchy
		WHERE parent_chore_completion_id = chore_completion_id_to_show
			AND chore_completion_status_id = 4;
END$$

DELIMITER ;