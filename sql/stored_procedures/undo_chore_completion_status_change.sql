USE chores;
DROP PROCEDURE IF EXISTS undo_chore_completion;

DELIMITER $$
USE chores$$
CREATE PROCEDURE undo_chore_completion(chore_name NVARCHAR(256))
BEGIN
	CALL get_chore_completion(chore_name, @found_chore_completion_id);
	CALL delete_chore_completion(@found_chore_completion_id);
	CALL get_chore_completion(chore_name, @found_chore_completion_id);
    CALL undo_chore_completion_status_change(@found_chore_completion_id);
END$$

DELIMITER ;