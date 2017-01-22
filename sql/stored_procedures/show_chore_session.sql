DROP PROCEDURE IF EXISTS show_chore_session;
DELIMITER $$
CREATE DEFINER=root@localhost PROCEDURE show_chore_session(the_chore_session_id INT)
BEGIN
	SELECT chore
			, due_date
            , session_ended
            , duration_minutes
            , when_recorded
		FROM (SELECT chore_session_id
					, chore_id
					, due_date
					, when_completed AS session_ended
					, duration_minutes
					, when_recorded
				FROM chore_sessions
				NATURAL JOIN chore_completions
				NATURAL JOIN chore_schedule
			UNION
			SELECT chore_session_id
					, chore_id
					, NULL AS due_date
					, when_completed AS session_ended
					, duration_minutes
					, when_recorded
				FROM chore_sessions
				NATURAL JOIN chore_completions
				WHERE NOT EXISTS(SELECT *
						FROM chore_schedule
						WHERE chore_schedule.chore_completion_id = chore_completions.chore_completion_id)) AS info
		NATURAL JOIN chores
        WHERE chore_session_id = the_chore_session_id;
END$$
DELIMITER ;