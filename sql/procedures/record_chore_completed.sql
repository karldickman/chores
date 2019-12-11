USE chores;
DROP PROCEDURE IF EXISTS record_chore_completed;

DELIMITER $$

CREATE PROCEDURE record_chore_completed (completed_chore_completion_id INT, when_completed DATETIME, new_chore_completion_status_id INT, update_history BIT)
BEGIN
	IF when_completed IS NOT NULL
		AND new_chore_completion_status_id = 3 # No data
	THEN
		IF EXISTS(SELECT * FROM chore_completion_times WHERE chore_completion_id = completed_chore_completion_id)
        THEN
			SET @error_message = CONCAT('Chore completion id ', completed_chore_completion_id, ' already has a completion time.');
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
        END IF;
		INSERT INTO chore_completion_times
			(chore_completion_id, when_completed)
			VALUES
			(completed_chore_completion_id, when_completed);
	END IF;
	CALL update_chore_completion_status(completed_chore_completion_id, new_chore_completion_status_id, update_history);
END$$

DELIMITER ;