USE chores;

DROP PROCEDURE IF EXISTS update_chore_completion_due_date;

DELIMITER $$

CREATE PROCEDURE update_chore_completion_due_date(chore_completion_to_update_id INT, new_due_date DATETIME)
BEGIN
    SET @`now` = NOW();
    INSERT INTO chore_schedule_history
        (chore_completion_id, `from`, `to`, due_date)
        SELECT chore_completion_id, due_date_since, @`now`, due_date
            FROM chore_schedule
            WHERE chore_completion_id = chore_completion_to_update_id;
    UPDATE chore_schedule
        SET due_date = new_due_date, due_date_since = @`now`
        WHERE chore_completion_id = chore_completion_to_update_id;
END$$

DELIMITER ;
