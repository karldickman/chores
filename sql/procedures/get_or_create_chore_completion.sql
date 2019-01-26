USE chores;
DROP PROCEDURE IF EXISTS get_or_create_chore_completion;

DELIMITER $$

CREATE DEFINER=root@localhost PROCEDURE get_or_create_chore_completion(
	chore_name NVARCHAR(256),
    chore_due_date DATETIME,
    OUT found_chore_completion_id INT)
this_procedure:BEGIN
	SET found_chore_completion_id = NULL;
    SET @chore_id = NULL;
	CALL get_chore_completion(chore_name, found_chore_completion_id);
	IF found_chore_completion_id IS NOT NULL
    THEN
		LEAVE this_procedure;
	END IF;
	CALL create_chore_completion(chore_name, chore_due_date, found_chore_completion_id);
END$$

DELIMITER ;
