USE chores;

DROP PROCEDURE IF EXISTS skippable_chores_pretty;

DELIMITER $$

CREATE PROCEDURE skippable_chores_pretty(skippable_as_of DATETIME)
BEGIN
    IF skippable_as_of IS NULL
    THEN
        SET skippable_as_of = CURRENT_TIMESTAMP;
    END IF;
    SET @date_format = '%Y-%m-%d';
    SELECT chore
            , DATE_FORMAT(due_date, @date_format) AS due_date
            , DATE_FORMAT(next_due_date, @date_format) AS next_due_date
            , schedule_from
            , DATE_FORMAT(schedule_from_date, @date_format) AS schedule_from_date
            , frequency
            , frequency_unit AS unit
        FROM chore_completion_next_due_dates
        NATURAL JOIN chores
        NATURAL JOIN schedule_from
        WHERE chore_completion_status_id = 1 # Status = scheduled
            AND next_due_date <= skippable_as_of
            AND schedule_from_id != 2 # Schedule from due date
            AND chore_id NOT IN (SELECT chore_id
                    FROM chore_categories
                    WHERE category_id = 1); # Category = meals
END$$

DELIMITER ;
