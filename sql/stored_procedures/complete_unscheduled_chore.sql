USE chores;
DROP PROCEDURE IF EXISTS complete_unscheduled_chore;

DELIMITER $$

CREATE PROCEDURE complete_unscheduled_chore(
	chore_name NVARCHAR(256),
    when_completed DATETIME,
    duration_minutes FLOAT,
    OUT new_chore_completion_id INT,
    OUT next_chore_completion_id INT)
BEGIN
	CALL create_chore_completion(chore_name, new_chore_completion_id);
    CALL record_chore_session(new_chore_completion_id, when_completed, duration_minutes, @new_chore_session_id);
    CALL record_chore_completed(new_chore_completion_id, NULL, 4, FALSE);
    IF next_chore_completion_id = TRUE
    THEN
		CALL schedule_next_chore(new_chore_completion_id, next_chore_completion_id);
    END IF;
END$$

DELIMITER ;