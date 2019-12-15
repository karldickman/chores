USE chores;

DROP FUNCTION IF EXISTS format_duration;

DELIMITER $$

CREATE FUNCTION format_duration (duration_minutes DOUBLE) RETURNS VARCHAR(256) DETERMINISTIC
BEGIN
    IF duration_minutes = 0
    THEN
        RETURN '';
    END IF;
    SET @duration = SEC_TO_TIME(duration_minutes * 60);
    IF duration_minutes < 60
    THEN
        RETURN CONCAT('   ', TIME_FORMAT(@duration, '%i:%S'));
    END IF;
    RETURN TIME_FORMAT(@duration, '%H:%i:%S');
END$$

DELIMITER ;
