USE chores;
DROP PROCEDURE IF EXISTS hierarchize_chore_completion;

DELIMITER $$

CREATE PROCEDURE hierarchize_chore_completion(
	chore_name NVARCHAR(256),
    the_due_date DATETIME,
    OUT found_parent_chore_completion_id INT)
this_procedure:BEGIN
	CALL get_chore_completion(chore_name, found_parent_chore_completion_id);
    INSERT INTO chore_completion_hierarchy
		(chore_completion_id, parent_chore_completion_id)
		SELECT chore_completions.chore_completion_id, found_parent_chore_completion_id
			FROM chore_completions
			NATURAL JOIN chore_hierarchy
			NATURAL JOIN chore_schedule
			INNER JOIN chores AS parent_chores
				ON parent_chore_id = parent_chores.chore_id
			LEFT OUTER JOIN chore_completion_hierarchy
				ON chore_completions.chore_completion_id = chore_completion_hierarchy.chore_completion_id
			WHERE parent_chores.chore = chore_name
				AND chore_completion_status_id = 1 # scheduled
				AND due_date <= the_due_date
				AND parent_chore_completion_id IS NULL;
END$$

DELIMITER ;