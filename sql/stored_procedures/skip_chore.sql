USE chores;
DROP procedure IF EXISTS skip_chore;

DELIMITER $$
USE chores$$
CREATE PROCEDURE skip_chore (chore_name NVARCHAR(256), OUT next_chore_completion_id INT)
BEGIN
	SET @found_chore_completion_id = NULL;
	CALL get_chore_completion(chore_name, @found_chore_completion_id);
    CALL record_chore_completed(@found_chore_completion_id, NULL, next_chore_completion_id);
END$$

DELIMITER ;
