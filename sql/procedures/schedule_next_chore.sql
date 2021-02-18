USE chores;

DROP PROCEDURE IF EXISTS schedule_next_chore;

DELIMITER $$

CREATE PROCEDURE schedule_next_chore (completed_chore_completion_id INT, OUT new_chore_completion_id INT)
this_procedure:BEGIN
    # Change variables to NULL
    SET @chore_completion_status_id = NULL;
    SET @chore_id = NULL;
    SET @when_completed = NULL;
    SET @next_due_date = NULL;
    # Parameter checking
    IF completed_chore_completion_id IS NULL
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter completed_chore_completion_id cannot be NULL.';
    END IF;
    # Leave the procedure if not completed
    SELECT chore_id, chore_completion_status_id, due_date
        INTO @chore_id, @chore_completion_status_id, @due_date
        FROM chore_completions
        LEFT JOIN chore_schedule USING (chore_completion_id)
        WHERE chore_completion_id = completed_chore_completion_id;
    IF @chore_completion_status_id = 1 # Scheduled
    THEN
        LEAVE this_procedure;
    END IF;
    # Schedule the remaining chores
    CALL update_chore_schedule();
    # If the chore is scheduled in advance, leave the procedure
    IF EXISTS(SELECT * FROM chore_schedule_in_advance WHERE chore_id = @chore_id)
    THEN
        LEAVE this_procedure;
    END IF;
    # Get the next chore schedule date
    SELECT next_due_date INTO @next_due_date 
        FROM chore_completion_next_due_dates
        WHERE chore_completion_id = completed_chore_completion_id;
    IF @next_due_date IS NULL
    THEN
        SET @message = CONCAT('Could not find next due date for chore id ', @chore_id, '.');
        SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = @message;
        LEAVE this_procedure;
    END IF;
    # Leave the procedure if there is a later due date than this one
    IF EXISTS(SELECT *
        FROM chore_completions
        JOIN chore_schedule USING (chore_completion_id)
        WHERE chore_id = @chore_id
            AND due_date > @due_date
            AND due_date <= @next_due_date
            AND chore_id NOT IN (SELECT chore_id
                    FROM chores
                    WHERE completions_per_day > 1))
    THEN
        LEAVE this_procedure;
    END IF;
    CALL schedule_chore_by_id(@chore_id, @next_due_date, new_chore_completion_id);
END$$

DELIMITER ;
