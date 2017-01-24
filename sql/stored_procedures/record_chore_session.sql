USE chores;
DROP PROCEDURE IF EXISTS record_chore_session;

DELIMITER $$
USE chores$$
CREATE PROCEDURE record_chore_session(
	chore_completion_id INT,
    when_completed DATETIME,
    minutes FLOAT,
    seconds FLOAT,
    OUT new_chore_session_id INT)
BEGIN
    SET new_chore_session_id = NULL;
    IF chore_completion_id IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter chored_completion_id cannot be NULL.';
    END IF;
    IF minutes IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter minutes cannot be NULL.';
    END IF;
    IF seconds IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter seconds cannot be NULL.';
    END IF;
	SET @duration_minutes = minutes + seconds / 60.0;
	INSERT INTO chore_sessions
		(when_completed, duration_minutes, chore_completion_id)
		VALUES
		(when_completed, @duration_minutes, chore_completion_id);
	SET new_chore_session_id = LAST_INSERT_ID();
END$$

DELIMITER ;