USE chores;

DROP FUNCTION IF EXISTS nearest_saturday;

DELIMITER $$

CREATE FUNCTION nearest_saturday (`date` DATETIME)
RETURNS DATETIME
DETERMINISTIC
BEGIN
    SET @adjustment = 5 - WEEKDAY(`date`);
    IF @adjustment > 2
    THEN
        SET @adjustment = @adjustment - 7;
    END IF;
    RETURN DATE_ADD(`date`, INTERVAL @adjustment DAY);
END$$

DELIMITER ;
