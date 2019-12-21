USE chores;

DROP PROCEDURE IF EXISTS schedule_next_chore;

DELIMITER $$

CREATE PROCEDURE schedule_next_chore (completed_chore_completion_id INT, OUT new_chore_completion_id INT)
this_procedure:BEGIN
    # Change variables to NULL
    SET @chore_completion_status_id = NULL;
    SET @chore_id = NULL;
    SET @when_completed = NULL;
    SET @frequency = NULL;
    SET @next_due_date = NULL;
    SET @adjustment = NULL;
    # Parameter checking
    IF completed_chore_completion_id IS NULL
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter completed_chore_completion_id cannot be NULL.';
    END IF;
    # Leave the procedure if not completed
    SELECT chore_id, chore_completion_status_id
        INTO @chore_id, @chore_completion_status_id
        FROM chore_completions
        WHERE chore_completions.chore_completion_id = completed_chore_completion_id;
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
    # If the chore is scheduled by due date, use that to schedule the next chore
    IF EXISTS(SELECT * FROM chore_due_dates WHERE chore_id = @chore_id)
    THEN
        CALL schedule_next_chore_by_due_date(@chore_id, new_chore_completion_id);
        LEAVE this_procedure;
    END IF;
    # Find the frequency between chores
    SELECT frequency, frequency_unit_id INTO @frequency,  @frequency_unit_id
        FROM chore_frequencies
        WHERE chore_id = @chore_id;
    IF @frequency IS NULL OR @frequency_unit_id IS NULL
    THEN
        LEAVE this_procedure;
    END IF;
    # Get the next chore schedule date
    SELECT next_due_date INTO @next_due_date 
        FROM chore_completion_next_due_dates
        WHERE chore_completion_next_due_dates.chore_completion_id = completed_chore_completion_id;
    IF @next_due_date IS NULL
    THEN
        SELECT when_completed INTO @when_completed
            FROM chore_completions_when_completed
            WHERE chore_completions_when_completed.chore_completion_id = completed_chore_completion_id;
        SET @when_completed = COALESCE(@when_completed, CURRENT_TIMESTAMP);
        IF @frequency_unit_id = 1 THEN
            SET @next_due_date = DATE_ADD(@when_completed, INTERVAL @frequency DAY);
        ELSEIF @frequency_unit_id = 2 THEN
            SET @next_due_date = DATE_ADD(@when_completed, INTERVAL @frequency MONTH);
        END IF;
    END IF;
    SET @next_due_date = DATE(@next_due_date);
    # If 7 or more days between chores, find the closest Sunday and use that
    IF @frequency >= 7 AND @frequency_unit_id = 1 OR @frequency > 0.25 AND @frequency_unit_id = 2
    THEN    
        # Leave the procedure if there is a later due date than this one
        SELECT due_date INTO @due_date
            FROM chore_completions
            NATURAL JOIN chore_schedule
            WHERE chore_completion_id = completed_chore_completion_id;
        IF EXISTS(SELECT *
            FROM chore_completions
            NATURAL JOIN chore_schedule
            WHERE chore_id = @chore_id
                AND due_date > @due_date)
        THEN
            LEAVE this_procedure;
        END IF;
        CALL get_nearest_sunday(@next_due_date, @next_due_date);
    END IF;
    CALL schedule_chore_by_id(@chore_id, @next_due_date, new_chore_completion_id);
END$$

DELIMITER ;
