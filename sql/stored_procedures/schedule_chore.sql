USE chores;
DROP procedure IF EXISTS schedule_chore;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE schedule_chore(chore_to_schedule_id INT, chore_name NVARCHAR(256), due_date DATETIME, OUT new_chore_completion_id INT)
BEGIN
	SET new_chore_completion_id = NULL;
	IF chore_to_schedule_id IS NULL
	THEN
		SELECT chore_id
			INTO chore_to_schedule_id
			FROM chores
			WHERE chore = chore_name;
	END IF;
	INSERT INTO chore_completions
		(chore_id, is_completed)
        VALUES
        (chore_to_schedule_id, 0);
	SET new_chore_completion_id = LAST_INSERT_ID();
    INSERT INTO chore_schedule
		(chore_completion_id, due_date)
        VALUES
        (new_chore_completion_id, due_date);
END$$

DELIMITER ;
