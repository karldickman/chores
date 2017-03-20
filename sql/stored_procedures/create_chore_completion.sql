USE chores;
DROP PROCEDURE IF EXISTS create_chore_completion;

DELIMITER $$
USE chores$$
CREATE PROCEDURE create_chore_completion(
	chore_name NVARCHAR(256),
    OUT new_chore_completion_id INT)
this_procedure:BEGIN
    SET @chore_id = NULL;
	SELECT chore_id INTO @chore_id
		FROM chores
		WHERE chore = chore_name;
	IF @chore_id IS NULL
	THEN
		SET @message = 'Could not find chore record for "' + chore_name + '."';
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message;
	END IF;
	INSERT INTO chore_completions
		(chore_id, chore_completion_status_id)
		VALUES
		(@chore_id, 1);
	SET new_chore_completion_id = LAST_INSERT_ID();
END$$

DELIMITER ;