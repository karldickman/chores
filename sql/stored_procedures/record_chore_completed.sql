USE chores;
DROP PROCEDURE IF EXISTS record_chore_completed;

DELIMITER $$
USE chores$$
CREATE PROCEDURE record_chore_completed (completed_chore_completion_id INT, when_completed DATETIME, new_chore_completion_status_id INT, OUT next_chore_completion_id INT, update_history BIT)
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
    IF update_history = TRUE
    THEN
		SET @status_since = CURRENT_TIMESTAMP;
		INSERT INTO chore_completion_status_history
			(chore_completion_id, `from`, `to`, chore_completion_status_id)
			SELECT chore_completion_id, chore_completion_status_since, @status_since, chore_completion_status_id
				FROM chore_completions
				WHERE chore_completion_id = completed_chore_completion_id;
	END IF;
	UPDATE chore_completions
		SET chore_completion_status_id = new_chore_completion_status_id, chore_completion_status_since = @status_since
		WHERE chore_completion_id = completed_chore_completion_id;
	CALL schedule_next_chore(completed_chore_completion_id, next_chore_completion_id);
END$$

DELIMITER ;