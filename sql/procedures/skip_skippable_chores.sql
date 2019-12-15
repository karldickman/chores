USE chores;

DROP PROCEDURE IF EXISTS skip_skippable_chores;

DELIMITER $$

CREATE PROCEDURE skip_skippable_chores (update_history BIT)
BEGIN
    DECLARE is_finished BIT DEFAULT FALSE;
    DECLARE chore_completion_id INT;
    DECLARE skip_chores_cursor CURSOR FOR
        SELECT chore_completion_id
            FROM chores_to_skip;
    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET is_finished = TRUE;
    # Store chores to skip in temporary table
    CREATE TEMPORARY TABLE chores_to_skip
        SELECT chore_completion_id
            FROM skippable_chores
            LIMIT 0;
    OPEN skip_chores_cursor;
    SET @skipped = 2;
    skip_chores: LOOP
        FETCH skip_chores_cursor INTO chore_completion_id;
        IF is_finished THEN
            LEAVE skip_chores;
        END IF;
        CALL record_chore_completed(chore_completion_id, CURRENT_TIMESTAMP, @skipped, update_history);
    END LOOP skip_chores;
    CLOSE skip_chores_cursor;
    DROP TEMPORARY TABLE chores_to_skip;
END$$

DELIMITER ;
