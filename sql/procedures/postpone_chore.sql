USE chores;

DROP PROCEDURE IF EXISTS postpone_chore;

DELIMITER $$

CREATE PROCEDURE postpone_chore(chore_name NVARCHAR(256), days INT, OUT found_chore_completion_id INT)
BEGIN
    CALL get_chore_completion(chore_name, found_chore_completion_id);
    SELECT due_date INTO @due_date
        FROM chore_schedule
        WHERE chore_completion_id = found_chore_completion_id;
    SET @due_date = DATE_ADD(@due_date, INTERVAL days DAY);
    CALL update_chore_completion_due_date(found_chore_completion_id, @due_date);
END$$

DELIMITER ;
