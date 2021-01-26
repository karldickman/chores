USE chores;

DROP PROCEDURE IF EXISTS create_chore;

DELIMITER $$

CREATE PROCEDURE create_chore(chore_name NVARCHAR(256), aggregate_by_id INT, completions_per_day INT, frequency_days FLOAT, OUT new_chore_id INT)
BEGIN
    INSERT INTO chores
        (chore, aggregate_by_id, completions_per_day)
        VALUES
        (chore_name, aggregate_by_id, completions_per_day);
    SET new_chore_id = LAST_INSERT_ID();
    IF frequency_days IS NOT NULL
    THEN
        SET @day_unit_id = 1;
        INSERT INTO chore_frequencies
            (chore_id, frequency, frequency_unit_id)
            VALUES
            (new_chore_id, frequency_days, @day_unit_id);
        SET @schedule_from_completion_time = 1;
        INSERT INTO chore_schedule_from
            (chore_id, schedule_from_id)
            VALUES
            (new_chore_id, @schedule_from_completion_time);
    END IF;
END$$

DELIMITER ;
