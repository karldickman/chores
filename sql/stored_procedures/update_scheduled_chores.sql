USE chores;
DROP PROCEDURE IF EXISTS update_chore_schedule;

DELIMITER $$
USE chores$$
CREATE PROCEDURE update_chore_schedule()
BEGIN
	DECLARE cursor_done INT DEFAULT FALSE;
    DECLARE chore_to_schedule_id INT;
    DECLARE due_date DATETIME;
	DECLARE to_schedule_cursor CURSOR FOR
		SELECT chore_id, next_due_date
			FROM chores_to_schedule;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET cursor_done = TRUE;
	OPEN to_schedule_cursor;
    read_loop: LOOP
		FETCH to_schedule_cursor INTO chore_to_schedule_id, due_date;
        IF cursor_done THEN
			LEAVE read_loop;
		END IF;
        CALL schedule_chore_by_id(chore_to_schedule_id, due_date, @c);
        CALL show_chore_completion(@c);
    END LOOP;
    CLOSE to_schedule_cursor;
END$$

DELIMITER ;