USE chores;
DROP PROCEDURE IF EXISTS skip_chore;

DELIMITER $$
USE chores$$
CREATE PROCEDURE skip_chore (chore_name NVARCHAR(256), OUT found_chore_completion_id INT, OUT next_chore_completion_id INT)
BEGIN
	SET found_chore_completion_id = NULL;
	CALL get_chore_completion(chore_name, found_chore_completion_id);
    CALL record_chore_completed(found_chore_completion_id, NULL, 2, TRUE);
    CALL schedule_next_chore(found_chore_completion_id, next_chore_completion_id);
END$$

DELIMITER ;