USE chores;
DROP PROCEDURE IF EXISTS get_chore_completion;

DELIMITER $$
USE chores$$
CREATE PROCEDURE get_chore_completion (chore_name NVARCHAR(256), OUT found_chore_completion_id INT)
this_procedure:BEGIN
	SET @earliest_due_date = NULL;
	SELECT MIN(due_date) INTO @earliest_due_date
		FROM chore_completions
		NATURAL JOIN chores
		LEFT OUTER JOIN chore_schedule
			ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
		WHERE chores.chore = chore_name
			AND chore_completion_status_id = 1;
	IF @earliest_due_date IS NULL
	THEN
		SELECT MIN(chore_completion_id) INTO found_chore_completion_id
			FROM chore_completions
			NATURAL JOIN chores
			WHERE chores.chore = chore_name
				AND chore_completion_status_id = 1;
		LEAVE this_procedure;
	END IF;
	SELECT MIN(chore_completion_id) INTO found_chore_completion_id
		FROM chore_completions
		NATURAL JOIN chores
		NATURAL JOIN chore_schedule
		WHERE chores.chore = chore_name
			AND chore_completion_status_id = 1
			AND due_date = @earliest_due_date;
END$$

DELIMITER ;