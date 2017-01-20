USE chores;
DROP PROCEDURE IF EXISTS schedule_next_chore;

DELIMITER $$
USE chores$$
CREATE PROCEDURE schedule_next_chore (completed_chore_completion_id INT, OUT new_chore_completion_id INT)
this_procedure:BEGIN
	/* Change variables to NULL */
    SET @is_completed = NULL;
    SET @chore_id = NULL;
    SET @when_completed = NULL;
    SET @frequency = NULL;
    SET @next_due_date = NULL;
    SET @adjustment = NULL;
	/* Leave the procedure if not completed */
	SELECT is_completed INTO @is_completed
		FROM chore_completions
        WHERE chore_completions.chore_completion_id = completed_chore_completion_id;
	SELECT chore_id INTO @chore_id
		FROM chore_completions
        WHERE chore_completions.chore_completion_id = completed_chore_completion_id;
	IF @is_completed = 0
    THEN
		LEAVE this_procedure;
    END IF;
    /* Leave the procedure if there is a later completion date than this one */
    SELECT when_completed INTO @when_completed
		FROM chore_completions_when_completed
        WHERE chore_completions_when_completed.chore_completion_id = completed_chore_completion_id;
	IF @when_completed IS NULL
    THEN
		SET @when_completed = CURRENT_TIMESTAMP;
    END IF;
    IF EXISTS(SELECT *
		FROM chore_completion_durations
        NATURAL JOIN chore_completions
        WHERE chore_id = @chore_id
			AND when_completed > @when_completed)
	THEN
		LEAVE this_procedure;
    END IF;        
    /* Find the frequency between chores */
    SELECT frequency_days INTO @frequency
		FROM chore_frequencies
        WHERE chore_id = @chore_id;
	/* Get the next chore schedule date */
	SELECT next_due_date INTO @next_due_date 
		FROM chore_completion_next_due_dates
        WHERE chore_completion_next_due_dates.chore_completion_id = completed_chore_completion_id;
	IF @next_due_date IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Could not find next due date for chore.';
    END IF;
	/* If 7 or more days between chores, find the closest Sunday and use that */
    IF @frequency >= 7
    THEN
        SET @adjustment = 3 - MOD(WEEKDAY(@next_due_date) - 3, 7);
        SET @next_due_date = DATE_ADD(@next_due_date, INTERVAL @adjustment DAY);
	END IF;
	CALL schedule_chore(@chore_id, NULL, @next_due_date, new_chore_completion_id);
END$$

DELIMITER ;
