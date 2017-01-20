USE chores;
DROP procedure IF EXISTS complete_chore;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE complete_chore(
	chore_name NVARCHAR(256),
    when_completed DATETIME,
    chore_due_date DATETIME,
    create_if_not_exists BOOL,
    minutes FLOAT,
    seconds FLOAT,
    is_complete BOOL,
    OUT found_chore_completion_id INT,
    OUT new_chore_session_id INT)
BEGIN
	SET @chore_id = NULL;
    SET found_chore_completion_id = NULL;
    SET new_chore_session_id = NULL;
	SET @duration_minutes = minutes + seconds / 60.0;
	SELECT chore_id
		INTO @chore_id
		FROM chores
		WHERE chore = chore_name;
	IF chore_due_date IS NULL
    THEN
		SET chore_due_date = when_completed;
    END IF;
	SELECT MIN(chore_completion_id)
		INTO found_chore_completion_id
		FROM chore_completions
        NATURAL JOIN chore_schedule
		WHERE chore_id = @chore_id
			AND is_completed = 0
			AND YEAR(chore_schedule.due_date) = YEAR(chore_due_date)
			AND MONTH(chore_schedule.due_date) = MONTH(chore_due_date)
			AND DAY(chore_schedule.due_date) = DAY(chore_due_date);
	IF create_if_not_exists = 1 AND found_chore_completion_id IS NULL
    THEN
		INSERT INTO chore_completions
			(chore_id, is_completed)
            VALUES
            (@chore_id, is_complete);
		SET found_chore_completion_id = LAST_INSERT_ID();
		INSERT INTO chore_schedule
			(chore_completion_id, due_date)
            VALUES
            (found_chore_completion_id, chore_due_date);
    END IF;
    IF @duration_minutes IS NOT NULL
    THEN
		INSERT INTO chore_sessions
			(when_completed, duration_minutes)
			VALUES
			(when_completed, @duration_minutes);
		SET new_chore_session_id = LAST_INSERT_ID();
		INSERT INTO chore_completion_sessions
			(chore_completion_id, chore_session_id)
			VALUES
			(found_chore_completion_id, new_chore_session_id);
	END IF;
    IF is_complete = 1
    THEN
		IF @duration_minutes IS NULL AND when_completed IS NOT NULL
		THEN
			INSERT INTO chore_completion_times
				(chore_completion_id, when_completed)
				VALUES
				(found_chore_completion_id, when_completed);
		END IF;
		UPDATE chore_completions
			SET is_completed = 1
			WHERE chore_completion_id = found_chore_completion_id;
		CALL schedule_next_chore(found_chore_completion_id, @next_chore_completion_id);
    END IF;
END$$

DELIMITER ;

