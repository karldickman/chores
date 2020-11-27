USE chores;

DROP PROCEDURE IF EXISTS chore_duration_today;

DELIMITER $$

CREATE PROCEDURE chore_duration_today()
BEGIN
    SET @`day` = NOW();
    SELECT IFNULL(SUM(duration_minutes), 0) AS duration
        FROM chore_sessions
        WHERE DATE(when_completed) BETWEEN DATE(@`day`) AND DATE(DATE_ADD(@`day`, INTERVAL 1 DAY));
END$$

DELIMITER ;
