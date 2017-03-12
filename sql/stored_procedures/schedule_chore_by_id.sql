USE chores;
DROP PROCEDURE IF EXISTS schedule_chore_by_id;

DELIMITER $$
USE chores$$
CREATE PROCEDURE schedule_chore_by_id(chore_to_schedule_id INT, due_date DATETIME, OUT new_chore_completion_id INT)
BEGIN
	SET new_chore_completion_id = NULL;
	IF chore_to_schedule_id IS NULL
	THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter chore_to_schedule_id cannot be NULL.';
	END IF;
	INSERT INTO chore_completions
		(chore_id, chore_completion_status_id)
        VALUES
        (chore_to_schedule_id, 1);
	SET new_chore_completion_id = LAST_INSERT_ID();
    INSERT INTO chore_schedule
		(chore_completion_id, due_date)
        VALUES
        (new_chore_completion_id, due_date);
END$$

DELIMITER ;