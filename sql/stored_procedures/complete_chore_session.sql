USE chores;
DROP PROCEDURE IF EXISTS complete_chore_session;

DELIMITER $$
USE chores$$
CREATE PROCEDURE complete_chore_session(
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
	CALL get_chore_completion(chore_name, found_chore_completion_id);
    IF found_chore_completion_id IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Procedure complete_chore_session: Could not find chore completion record matching the specified criteria.';
    END IF;
	CALL record_chore_session(found_chore_completion_id, when_completed, minutes, seconds, new_chore_session_id);
END$$

DELIMITER ;