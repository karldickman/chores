USE chores;
DROP PROCEDURE IF EXISTS put_away_dishes;

DELIMITER $$
USE chores$$
CREATE PROCEDURE put_away_dishes (when_completed DATETIME, drainer_minutes FLOAT, drainer_seconds FLOAT, dishwasher_minutes FLOAT, dishwasher_seconds FLOAT, OUT found_chore_completion_id INT, OUT next_chore_completion_id INT)
BEGIN
	SET found_chore_completion_id = NULL;
    SET next_chore_completion_id = NULL;
    SET @drainer_id = NULL;
    SET @dishwasher_id = NULL;
	CALL get_chore_completion('put away dishes', found_chore_completion_id);
	IF drainer_minutes IS NOT NULL AND drainer_seconds IS NOT NULL
    THEN
		CALL complete_unscheduled_chore('empty drainer', when_completed, drainer_minutes, drainer_seconds, @drainer_id, @next_chore_completion_id);
		INSERT INTO chore_completion_hierarchy
			(chore_completion_id, parent_chore_completion_id)
			VALUES
			(@drainer_id, found_chore_completion_id);
	END IF;
    IF dishwasher_minutes IS NOT NULL AND dishwasher_seconds IS NOT NULL
    THEN
		CALL complete_unscheduled_chore('empty dishwasher', when_completed, dishwasher_minutes, dishwasher_seconds, @dishwasher_id, @next_chore_completion_id);
		INSERT INTO chore_completion_hierarchy
			(chore_completion_id, parent_chore_completion_id)
			VALUES
			(@dishwasher_id, found_chore_completion_id);
	END IF;
	CALL record_chore_completed(found_chore_completion_id, NULL, 4, next_chore_completion_id, TRUE);
END$$

DELIMITER ;