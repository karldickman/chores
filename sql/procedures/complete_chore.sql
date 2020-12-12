USE chores;

DROP PROCEDURE IF EXISTS complete_chore;

DELIMITER $$

CREATE PROCEDURE complete_chore(
    chore_name NVARCHAR(256),
    when_completed DATETIME,
    duration_minutes FLOAT,
    OUT found_chore_completion_id INT,
    OUT next_chore_completion_id INT)
BEGIN
    SET found_chore_completion_id = NULL;
    SET @new_chore_session_id = NULL;
    IF when_completed IS NOT NULL AND duration_minutes IS NOT NULL
    THEN
        CALL complete_chore_session(chore_name, when_completed, duration_minutes, found_chore_completion_id, @new_chore_session_id);
    ELSE
        CALL get_chore_completion(chore_name, found_chore_completion_id);
        IF (SELECT COUNT(chore_session_id) FROM chore_sessions WHERE chore_completion_id = found_chore_completion_id) = 0
        THEN
            SET @message = CONCAT('Procedure complete_chore: chore completion with id ', found_chore_completion_id, ' has no chore sessions.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message;
        END IF;
    END IF;
    CALL record_chore_completed(found_chore_completion_id, when_completed, 4, TRUE);
    CALL schedule_next_chore(found_chore_completion_id, next_chore_completion_id);
END$$

DELIMITER ;
