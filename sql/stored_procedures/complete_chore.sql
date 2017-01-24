USE chores;
DROP procedure IF EXISTS complete_chore;

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
	CALL complete_chore_session(chore_name, when_completed, minutes, seconds, found_chore_completion_id, @new_chore_session_id);
    CALL record_chore_completed(found_chore_completion_id, when_completed, 4, next_chore_completion_id, TRUE);
END$$

DELIMITER ;