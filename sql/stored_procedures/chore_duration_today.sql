USE chores;
DROP PROCEDURE IF EXISTS chore_duration_today;

DELIMITER $$

CREATE PROCEDURE chore_duration_today()
BEGIN
	SET @day = DATE(NOW());
    WITH irrelevant_chores AS (SELECT chore_id
		FROM chore_categories
		NATURAL JOIN categories
		WHERE category = 'meals'
	UNION
	SELECT chore_id
		FROM chores
		WHERE chore IN ('close budget period'))
	SELECT IFNULL(SUM(duration_minutes), 0) AS duration
		FROM chore_sessions
		NATURAL JOIN chore_completions
		NATURAL JOIN chores
		WHERE when_completed BETWEEN @day AND DATE_ADD(@day, INTERVAL 1 DAY)
			AND chore_id NOT IN (SELECT chore_id
					FROM irrelevant_chores);
END$$

DELIMITER ;