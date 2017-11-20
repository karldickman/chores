USE chores;
DROP PROCEDURE IF EXISTS postpone_yard_work;

DELIMITER $$
USE chores$$
CREATE PROCEDURE postpone_yard_work(OUT new_parent_chore_completion_id INT)
BEGIN
	DECLARE done BOOL DEFAULT FALSE;
    DECLARE to_postpone_id INT;
	DECLARE to_postpone CURSOR FOR  
		SELECT chore_completions.chore_completion_id
			FROM chore_completions
			NATURAL JOIN chore_schedule
			NATURAL JOIN chore_completion_hierarchy
			INNER JOIN chore_completions AS parent_chore_completions
				ON parent_chore_completion_id = parent_chore_completions.chore_completion_id
			INNER JOIN chores
				ON parent_chore_completions.chore_id = chores.chore_id
			WHERE chore = 'yard work'
				AND chore_completions.chore_completion_status_id = 1
				AND due_date <= NOW();
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	CALL get_chore_completion('yard work', new_parent_chore_completion_id);
    SELECT due_date INTO @new_due_date
		FROM chore_schedule
        WHERE chore_completion_id = new_parent_chore_completion_id;
    OPEN to_postpone;
    read_loop: LOOP
		FETCH to_postpone INTO to_postpone_id;
        IF done THEN
			LEAVE read_loop;
		END IF;
        UPDATE chore_completion_hierarchy
			SET parent_chore_completion_id = new_parent_chore_completion_id
			WHERE chore_completion_id = to_postpone_id;
        UPDATE chore_schedule
			SET due_date = @new_due_date
			WHERE chore_completion_id = to_postpone_id;
    END LOOP;
    CLOSE to_postpone;
END$$

DELIMITER ;