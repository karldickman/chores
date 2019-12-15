USE chores;

DROP PROCEDURE IF EXISTS schedule_next_chore_by_due_date;

DELIMITER $$

CREATE PROCEDURE schedule_next_chore_by_due_date (chore_to_schedule_id INT, OUT new_chore_completion_id INT)
this_procedure:BEGIN
    SELECT MIN(due_date) INTO @next_due_date
        FROM chore_due_dates_this_year_and_next
        WHERE chore_id = chore_to_schedule_id
            AND due_date > (SELECT MAX(due_date)
                    FROM chore_completions
                    NATURAL JOIN chore_schedule
                    WHERE chore_id = chore_to_schedule_id
                        AND chore_completion_status_id != 1)
            AND due_date NOT IN (SELECT due_date
                FROM chore_schedule
                NATURAL JOIN chore_completions
                WHERE chore_id = chore_to_schedule_id);
    IF @next_due_date IS NULL
    THEN
        LEAVE this_procedure;
    END IF;
    CALL schedule_chore_by_id(chore_to_schedule_id, @next_due_date, new_chore_completion_id);
END$$

DELIMITER ;
