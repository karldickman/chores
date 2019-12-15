USE chores;

DROP PROCEDURE IF EXISTS record_chore_session;

DELIMITER $$

CREATE PROCEDURE record_chore_session(
    chore_completion_id INT,
    when_completed DATETIME,
    duration_minutes FLOAT,
    OUT new_chore_session_id INT)
BEGIN
    SET new_chore_session_id = NULL;
    IF chore_completion_id IS NULL
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter chored_completion_id cannot be NULL.';
    END IF;
    IF duration_minutes IS NULL
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parameter duration_minutes cannot be NULL.';
    END IF;
    INSERT INTO chore_sessions
        (when_completed, duration_minutes, chore_completion_id)
        VALUES
        (when_completed, duration_minutes, chore_completion_id);
    SET new_chore_session_id = LAST_INSERT_ID();
END$$

DELIMITER ;
