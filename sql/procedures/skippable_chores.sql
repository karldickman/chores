USE chores;
DROP PROCEDURE IF EXISTS skippable_chores;

DELIMITER $$

CREATE PROCEDURE skippable_chores(skippable_as_of DATETIME)
BEGIN
	IF skippable_as_of IS NULL
    THEN
		SET skippable_as_of = CURRENT_TIMESTAMP;
    END IF;
	SELECT *
		FROM chore_completion_next_due_dates
		WHERE chore_completion_status_id = 1 # Status = scheduled
			AND next_due_date <= skippable_as_of
			AND chore_id NOT IN (SELECT chore_id
					FROM chore_categories
					WHERE category_id = 1); # Category = meals
END$$

DELIMITER ;
