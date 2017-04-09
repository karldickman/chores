USE chores;
DROP PROCEDURE IF EXISTS show_chore_history;

DELIMITER $$
USE chores$$
CREATE PROCEDURE show_chore_history(chore_name NVARCHAR(256))
BEGIN
	SELECT chore_completions.chore_completion_id, due_date, when_completed, chore_completion_status
		FROM chore_completions
		NATURAL JOIN chore_completion_statuses
        NATURAL JOIN chores
        LEFT OUTER JOIN chore_schedule
			ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
		LEFT OUTER JOIN chore_completions_when_completed
			ON chore_completions.chore_completion_id = chore_completions_when_completed.chore_completion_id
		WHERE chore = chore_name
        ORDER BY due_date DESC, when_completed DESC;
END$$

DELIMITER ;