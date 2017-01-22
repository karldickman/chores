USE chores;
DROP procedure IF EXISTS get_chore_completion;

DELIMITER $$
USE chores$$
CREATE PROCEDURE get_chore_completion (chore_name NVARCHAR(256), OUT found_chore_completion_id INT)
BEGIN
	SET @earliest_due_date = NULL;
	SELECT MIN(due_date) INTO @earliest_due_date
		FROM chore_completions
		NATURAL JOIN chores
		NATURAL JOIN chore_schedule
		WHERE chores.chore = chore_name
			AND is_completed = 0;
	IF @earliest_due_date IS NULL
	THEN
		SET @message = 'Could not find chore completion for chore "' + chore_name + '."';
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message;
	END IF;
	SELECT MIN(chore_completion_id) INTO found_chore_completion_id
		FROM chore_completions
		NATURAL JOIN chores
		NATURAL JOIN chore_schedule
		WHERE chores.chore = chore_name
			AND is_completed = 0
			AND due_date = @earliest_due_date;
END$$

DELIMITER ;
