USE chores;
DROP procedure IF EXISTS show_completed_chore;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE show_completed_chore(chore_completion_id_to_show INT)
BEGIN
	SELECT chore
			, duration_minutes
			, when_completed
			, when_recorded
		FROM chores
		NATURAL JOIN chore_completions
		NATURAL JOIN chore_sessions
		WHERE chore_completion_id = chore_completion_id_to_show
			AND is_completed = 1;
END$$

DELIMITER ;
