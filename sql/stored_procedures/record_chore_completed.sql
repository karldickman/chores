USE chores;
DROP procedure IF EXISTS record_chore_completed;

DELIMITER $$
USE chores$$
CREATE PROCEDURE record_chore_completed (completed_chore_completion_id INT, when_completed DATETIME, OUT next_chore_completion_id INT)
BEGIN
	IF when_completed IS NOT NULL
		AND EXISTS(SELECT *
			FROM chore_completion_sessions
			WHERE chore_completion_sessions.chore_completion_id = completed_chore_completion_id)
	THEN
		INSERT INTO chore_completion_times
			(chore_completion_id, when_completed)
			VALUES
			(completed_chore_completion_id, when_completed);
	END IF;
	UPDATE chore_completions
		SET is_completed = 1
		WHERE chore_completion_id = completed_chore_completion_id;
	CALL schedule_next_chore(completed_chore_completion_id, next_chore_completion_id);
END$$

DELIMITER ;
