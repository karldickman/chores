USE chores;
DROP PROCEDURE IF EXISTS undo_chore_completion_status_change;

DELIMITER $$

CREATE PROCEDURE undo_chore_completion_status_change(chore_completion_to_undo_id INT)
BEGIN
	SET @last_status_change_date = NULL;
    SELECT MAX(`to`) INTO @last_status_change_date
		FROM chore_completion_status_history
        WHERE chore_completion_id = chore_completion_to_undo_id;
	SET @previous_chore_completion_status_id = NULL, @previous_status_since = NULL;
    SELECT chore_completion_status_id INTO @previous_chore_completion_status_id
		FROM chore_completion_status_history
        WHERE chore_completion_id = chore_completion_to_undo_id
			AND `to` = @last_status_change_date;
    SELECT `from` INTO @previous_status_since
		FROM chore_completion_status_history
        WHERE chore_completion_id = chore_completion_to_undo_id
			AND `to` = @last_status_change_date;
	UPDATE chore_completions
		SET chore_completion_status_id = @previous_chore_completion_status_id
			, chore_completion_status_since = @previous_status_since
		WHERE chore_completion_id = chore_completion_to_undo_id;
	DELETE FROM chore_completion_status_history
		WHERE chore_completion_id = chore_completion_to_undo_id
			AND chore_completion_status_id = @previous_chore_completion_status_id
            AND `from` = @previous_status_since
            AND `to` = @last_status_change_date;
END$$

DELIMITER ;
