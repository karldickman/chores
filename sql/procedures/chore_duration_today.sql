USE chores;

DROP PROCEDURE IF EXISTS chore_duration_today;

DELIMITER $$

CREATE PROCEDURE chore_duration_today()
BEGIN
    SET @`day` = DATE(NOW());
    SELECT IFNULL(SUM(duration_minutes), 0) AS duration
        FROM chore_sessions
        WHERE when_completed BETWEEN @`day` AND DATE_ADD(@`day`, INTERVAL 1 DAY);
END$$

DELIMITER ;
