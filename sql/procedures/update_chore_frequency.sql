USE chores;

DROP PROCEDURE IF EXISTS update_chore_frequency;

DELIMITER $$

CREATE PROCEDURE update_chore_frequency(chore_id_to_update INT, new_frequency FLOAT, new_frequency_unit_id INT)
BEGIN
    SET @`to` = NOW();
    INSERT INTO chore_frequency_history
        (chore_id, `from`, `to`, frequency, frequency_unit_id)
        SELECT chore_id, schedule_from_id_since, @`to`, frequency, frequency_unit_id
            FROM chore_frequencies
            WHERE chore_id = chore_id_to_update;
    UPDATE chore_frequencies
        SET frequency = new_frequency, frequency_unit_id = new_frequency_unit_id, frequency_since = @`to`
        WHERE chore_id = chore_id_to_update;
END$$

DELIMITER ;
