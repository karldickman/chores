USE chores;

DROP PROCEDURE IF EXISTS update_chore_completion_status;

DELIMITER $$

CREATE PROCEDURE update_chore_completion_status(chore_completion_to_update_id INT, new_chore_completion_status_id INT, update_history BIT)
BEGIN
    SET @status_since = CURRENT_TIMESTAMP;
    IF update_history = TRUE
    THEN
        INSERT INTO chore_completion_status_history
            (chore_completion_id, `from`, `to`, chore_completion_status_id)
            SELECT chore_completion_id, chore_completion_status_since, @status_since, chore_completion_status_id
                FROM chore_completions
                WHERE chore_completion_id = chore_completion_to_update_id;
    END IF;
    UPDATE chore_completions
        SET chore_completion_status_id = new_chore_completion_status_id, chore_completion_status_since = @status_since
        WHERE chore_completion_id = chore_completion_to_update_id;
END$$

DELIMITER ;
