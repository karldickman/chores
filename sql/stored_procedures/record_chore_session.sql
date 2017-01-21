USE chores;
DROP procedure IF EXISTS record_chore_session;

DELIMITER $$
USE chores$$
CREATE DEFINER=root@localhost PROCEDURE record_chore_session(
	chore_name NVARCHAR(256),
    when_completed DATETIME,
    chore_due_date DATETIME,
    create_if_not_exists BOOL,
    minutes FLOAT,
    seconds FLOAT,
    OUT found_chore_completion_id INT,
    OUT new_chore_session_id INT)
BEGIN
	SET @chore_id = NULL;
    SET found_chore_completion_id = NULL;
    SET new_chore_session_id = NULL;
    IF minutes IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter minutes cannot be null.';
    END IF;
    IF seconds IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter seconds cannot be null.';
    END IF;
	SET @duration_minutes = minutes + seconds / 60.0;
	SELECT chore_id
		INTO @chore_id
		FROM chores
		WHERE chore = chore_name;
	IF @chore_id IS NULL
    THEN
		SET @message = 'Could not find ID of chore "' + chore_name + '."';
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
    END IF;
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
			AND DATE(chore_schedule.due_date) = DATE(chore_due_date);
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
    IF found_chore_completion_id IS NULL
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Procedure record_chore_session: Could not find chore completion record matching the specified criteria.';
    END IF;
	INSERT INTO chore_sessions
		(when_completed, duration_minutes)
		VALUES
		(when_completed, @duration_minutes);
	SET new_chore_session_id = LAST_INSERT_ID();
	INSERT INTO chore_completion_sessions
		(chore_completion_id, chore_session_id)
		VALUES
		(found_chore_completion_id, new_chore_session_id);
END$$

DELIMITER ;

