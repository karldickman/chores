USE chores;
DROP PROCEDURE IF EXISTS get_or_create_chore_completion;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE get_or_create_chore_completion(
	chore_name NVARCHAR(256),
    chore_due_date DATETIME,
    OUT found_chore_completion_id INT)
this_procedure:BEGIN
	SET found_chore_completion_id = NULL;
    SET @chore_id = NULL;
	CALL get_chore_completion(chore_name, found_chore_completion_id);
	IF found_chore_completion_id IS NOT NULL
    THEN
		LEAVE this_procedure;
	END IF;
	SELECT chore_id INTO @chore_id
		FROM chores
		WHERE chore = chore_name;
	IF @chore_id IS NULL
	THEN
		SET @message = 'Could not find chore record for "' + chore_name + '."';
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message;
	END IF;
	IF chore_due_date IS NULL
	THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter chore_due_date cannot be NULL.';
	END IF;
	INSERT INTO chore_completions
		(chore_id, is_completed)
		VALUES
		(@chore_id, 0);
	SET found_chore_completion_id = LAST_INSERT_ID();
	INSERT INTO chore_schedule
		(chore_completion_id, due_date)
		VALUES
		(found_chore_completion_id, chore_due_date);
END$$

DELIMITER ;