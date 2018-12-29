USE chores;
DROP PROCEDURE IF EXISTS record_chore_completed;

DELIMITER $$
USE chores$$
CREATE PROCEDURE record_chore_completed (completed_chore_completion_id INT, when_completed DATETIME, new_chore_completion_status_id INT, update_history BIT)
BEGIN
	IF when_completed IS NOT NULL
		AND NOT EXISTS(SELECT *
			FROM chore_sessions
			WHERE chore_sessions.chore_completion_id = completed_chore_completion_id)
	THEN
		INSERT INTO chore_completion_times
			(chore_completion_id, when_completed)
			VALUES
			(completed_chore_completion_id, when_completed);
	END IF;
	CALL update_chore_completion_status(completed_chore_completion_id, new_chore_completion_status_id, update_history);
END$$

DELIMITER ;