USE chores;

DROP PROCEDURE IF EXISTS postpone_chore_by_name;

DELIMITER $$

CREATE PROCEDURE postpone_chore_by_name(chore_name NVARCHAR(256), days INT, OUT found_chore_completion_id INT, OUT due_date DATETIME)
BEGIN
    CALL get_chore_completion(chore_name, found_chore_completion_id);
    CALL postpone_chore(found_chore_completion_id, days, due_date);
END$$

DELIMITER ;
