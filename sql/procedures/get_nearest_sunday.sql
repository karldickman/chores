USE chores;

DROP PROCEDURE IF EXISTS get_nearest_sunday;

DELIMITER $$

CREATE PROCEDURE get_nearest_sunday (`date` DATE, OUT nearest_sunday DATE)
BEGIN
    SET @adjustment = 6 - WEEKDAY(`date`);
    IF @adjustment > 3
    THEN
        SET @adjustment = @adjustment - 7;
    END IF;
    SET nearest_sunday = DATE_ADD(`date`, INTERVAL @adjustment DAY);
END$$

DELIMITER ;
