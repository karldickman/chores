USE chores;

DROP PROCEDURE IF EXISTS delete_chore_completion;

DELIMITER $$

CREATE PROCEDURE delete_chore_completion(chore_completion_to_delete_id INT)
BEGIN
    DELETE FROM chore_schedule
        WHERE chore_completion_id = chore_completion_to_delete_id;
    DELETE FROM chore_completions
        WHERE chore_completion_id = chore_completion_to_delete_id;
END$$

DELIMITER ;
