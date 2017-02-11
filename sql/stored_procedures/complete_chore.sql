USE chores;
DROP PROCEDURE IF EXISTS complete_chore;

DELIMITER $$
USE chores$$
CREATE PROCEDURE complete_chore(
	chore_name NVARCHAR(256),
    when_completed DATETIME,
    minutes FLOAT,
    seconds FLOAT,
    OUT found_chore_completion_id INT,
    OUT next_chore_completion_id INT)
BEGIN
	SET found_chore_completion_id = NULL;
    SET @new_chore_session_id = NULL;
	IF when_completed IS NOT NULL AND minutes IS NOT NULL and seconds IS NOT NULL
    THEN
		CALL complete_chore_session(chore_name, when_completed, minutes, seconds, found_chore_completion_id, @new_chore_session_id);
	ELSE
		CALL get_chore_completion(chore_name, found_chore_completion_id);
	END IF;
    CALL record_chore_completed(found_chore_completion_id, when_completed, 4, next_chore_completion_id, TRUE);
END$$

DELIMITER ;