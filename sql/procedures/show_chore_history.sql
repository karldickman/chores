USE chores;

DROP PROCEDURE IF EXISTS show_chore_history;

DELIMITER $$

CREATE PROCEDURE show_chore_history(chore_name NVARCHAR(256))
BEGIN
    IF NOT EXISTS(SELECT * FROM chores WHERE chore = chore_name)
    THEN
        SET @error_message = CONCAT('No chore found named "', chore_name, '".');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
    END IF;
    SELECT chore_completions.chore_completion_id
            , due_date
            , chore_completions_when_completed.when_completed
            , number_of_sessions
            , TIME_FORMAT(SEC_TO_TIME(duration_minutes * 60), '%H:%i:%S') AS duration
            , chore_completion_status
        FROM chore_completions
        NATURAL JOIN chore_completion_statuses
        NATURAL JOIN chores
        LEFT OUTER JOIN hierarchical_chore_schedule AS chore_schedule
            ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
        LEFT OUTER JOIN chore_completions_when_completed
            ON chore_completions.chore_completion_id = chore_completions_when_completed.chore_completion_id
        LEFT OUTER JOIN chore_completion_durations
            ON chore_completions.chore_completion_id = chore_completion_durations.chore_completion_id
        WHERE chore = @chore_name
        ORDER BY due_date DESC, when_completed DESC;
END$$

DELIMITER ;
