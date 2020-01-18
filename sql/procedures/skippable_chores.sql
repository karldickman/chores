USE chores;

DROP PROCEDURE IF EXISTS skippable_chores;

DELIMITER $$

CREATE PROCEDURE skippable_chores(skippable_as_of DATETIME)
BEGIN
    IF skippable_as_of IS NULL
    THEN
        SET skippable_as_of = CURRENT_TIMESTAMP;
    END IF;
    SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , schedule_from_date
        , schedule_from_id
        , frequency
        , frequency_unit_id
        , frequency_unit
        , next_due_date
        FROM chore_completion_next_due_dates
        WHERE chore_completion_status_id = 1 # Status = scheduled
            AND next_due_date <= skippable_as_of
            AND schedule_from_id != 2 # Schedule from due date
            AND chore_id NOT IN (SELECT chore_id
                    FROM chore_categories
                    WHERE category_id = 1); # Category = meals
END$$

DELIMITER ;
