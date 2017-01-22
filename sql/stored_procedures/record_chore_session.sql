USE chores;
DROP PROCEDURE IF EXISTS record_chore_session;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE record_chore_session(
	chore_name NVARCHAR(256),
    when_completed DATETIME,
    minutes FLOAT,
    seconds FLOAT,
    OUT found_chore_completion_id INT,
    OUT new_chore_session_id INT)
BEGIN
	SET @chore_id = NULL;
    SET found_chore_completion_id = NULL;
    SET new_chore_session_id = NULL;
    IF minutes IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter minutes cannot be null.';
    END IF;
    IF seconds IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter seconds cannot be null.';
    END IF;
	SET @duration_minutes = minutes + seconds / 60.0;
	CALL get_chore_completion(chore_name, found_chore_completion_id);
    IF found_chore_completion_id IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Procedure record_chore_session: Could not find chore completion record matching the specified criteria.';
    END IF;
	INSERT INTO chore_sessions
		(when_completed, duration_minutes, chore_completion_id)
		VALUES
		(when_completed, @duration_minutes, found_chore_completion_id);
	SET new_chore_session_id = LAST_INSERT_ID();
END$$

DELIMITER ;