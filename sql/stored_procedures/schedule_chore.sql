USE chores;
DROP PROCEDURE IF EXISTS schedule_chore;

DELIMITER $$
USE chores$$
CREATE PROCEDURE schedule_chore(chore_name NVARCHAR(256), due_date DATETIME, OUT new_chore_completion_id INT)
BEGIN
	SET @chore_to_schedule_id = NULL;
	SET new_chore_completion_id = NULL;
	SELECT chore_id
		INTO @chore_to_schedule_id
		FROM chores
		WHERE chore = chore_name;
	CALL schedule_chore_by_id(@chore_to_schedule_id, due_date, new_chore_completion_id);
END$$

DELIMITER ;