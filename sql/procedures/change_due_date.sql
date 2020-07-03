USE chores;

DROP PROCEDURE IF EXISTS change_due_date;

DELIMITER $$

CREATE PROCEDURE change_due_date(chore_name NVARCHAR(256), new_due_date DATETIME, OUT found_chore_completion_id INT)
BEGIN
    CALL get_chore_completion(chore_name, found_chore_completion_id);
    CALL update_chore_completion_due_date(found_chore_completion_id, new_due_date);
END$$

DELIMITER ;
