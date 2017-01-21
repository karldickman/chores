DELIMITER $$
CREATE DEFINER=root@localhost PROCEDURE show_chore_session(the_chore_completion_id INT, the_chore_session_id INT)
BEGIN
	SELECT chore
			, due_date
            , when_completed AS session_ended
            , duration_minutes
            , when_recorded
		FROM chore_sessions
        NATURAL JOIN chore_completion_sessions
        INNER JOIN chore_completions
			ON chore_completion_sessions.chore_completion_id = chore_completions.chore_completion_id
        NATURAL JOIN chores
        LEFT OUTER JOIN chore_schedule
			ON chore_completion_sessions.chore_completion_id = chore_schedule.chore_completion_id
        WHERE chore_session_id = the_chore_session_id
			AND chore_completion_sessions.chore_completion_id = the_chore_completion_id;
END$$
DELIMITER ;
