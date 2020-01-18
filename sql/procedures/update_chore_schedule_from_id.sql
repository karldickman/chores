USE chores;

DROP PROCEDURE IF EXISTS update_chore_schedule_from_id;

DELIMITER $$

CREATE PROCEDURE update_chore_schedule_from_id(chore_id_to_update INT, new_schedule_from_id INT)
BEGIN
    SET @`to` = NOW();
    INSERT INTO chore_frequency_schedule_from_id_history
        (chore_id, `from`, `to`, schedule_from_id)
        SELECT chore_id, schedule_from_id_since, @`to`, schedule_from_id
            FROM chore_frequencies
            WHERE chore_id = chore_id_to_update;
    UPDATE chore_frequencies
        SET schedule_from_id = new_schedule_from_id, schedule_from_id_since = @`to`
        WHERE chore_id = chore_id_to_update;
END$$

DELIMITER ;
