USE chores;
DROP PROCEDURE IF EXISTS complete_chore_without_data;

DELIMITER $$
USE chores$$
CREATE PROCEDURE complete_chore_without_data (chore_name NVARCHAR(256), when_completed DATETIME, OUT found_chore_completion_id INT, OUT next_chore_completion_id INT)
BEGIN
	SET found_chore_completion_id = NULL;
	CALL get_chore_completion(chore_name, found_chore_completion_id);
    CALL record_chore_completed(found_chore_completion_id, when_completed, 3, next_chore_completion_id, TRUE);
END$$

DELIMITER ;