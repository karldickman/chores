USE chores;

DROP PROCEDURE IF EXISTS postpone_chore;

DELIMITER $$

CREATE PROCEDURE postpone_chore(chore_completion_to_postpone_id INT, days INT, OUT new_due_date DATETIME)
BEGIN
    SELECT due_date INTO new_due_date
        FROM chore_schedule
        WHERE chore_completion_id = chore_completion_to_postpone_id;
    SET new_due_date = DATE_ADD(new_due_date, INTERVAL days DAY);
    CALL update_chore_completion_due_date(chore_completion_to_postpone_id, new_due_date);
END$$

DELIMITER ;
