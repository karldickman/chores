USE chores;

DROP PROCEDURE IF EXISTS update_chore_schedule_from;

DELIMITER $$

CREATE PROCEDURE update_chore_schedule_from(chore_id_to_update INT, new_schedule_from_id INT)
BEGIN
    SET @`to` = NOW();
    INSERT INTO chore_schedule_from_history
        (chore_id, `from`, `to`, schedule_from_id)
        SELECT chore_id, schedule_from_since, @`to`, schedule_from_id
            FROM chore_schedule_from
            WHERE chore_id = chore_id_to_update;
    UPDATE chore_schedule_from
        SET schedule_from_id = new_schedule_from_id, schedule_from_since = @`to`
        WHERE chore_id = chore_id_to_update;
END$$

DELIMITER ;
