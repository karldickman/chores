USE chores;

DROP PROCEDURE IF EXISTS postpone_chore;

DELIMITER $$

CREATE PROCEDURE postpone_chore(chore_name NVARCHAR(256), days INT, OUT found_chore_completion_id INT)
BEGIN
    SET @`now` = NOW();
    CALL get_chore_completion(chore_name, found_chore_completion_id);
    INSERT INTO chore_schedule_history
        (chore_completion_id, `from`, `to`, due_date)
        SELECT chore_completion_id, due_date_since, @`now`, due_date
            FROM chore_schedule
            WHERE chore_completion_id = found_chore_completion_id;
    UPDATE chore_schedule
        SET due_date = DATE_ADD(due_date, INTERVAL days DAY), due_date_since = @`now`
        WHERE chore_completion_id = found_chore_completion_id;
END$$

DELIMITER ;
