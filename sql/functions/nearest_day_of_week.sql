USE chores;

DROP FUNCTION IF EXISTS nearest_day_of_week;

DELIMITER $$

CREATE FUNCTION nearest_day_of_week (`date` DATETIME, day_of_week INT)
RETURNS DATETIME
DETERMINISTIC
BEGIN
    SET @adjustment = day_of_week - WEEKDAY(`date`);
    IF @adjustment > 2
    THEN
        SET @adjustment = @adjustment - 7;
    END IF;
    RETURN DATE_ADD(`date`, INTERVAL @adjustment DAY);
END$$

DELIMITER ;
