USE chores;

DROP FUNCTION IF EXISTS log_normal_confidence_bound;

DELIMITER $$

CREATE FUNCTION log_normal_confidence_bound (sample_mean DOUBLE, sample_standard_deviation DOUBLE, sample_size INT, critical_value DOUBLE)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    SET @sample_variance = POWER(sample_standard_deviation, 2);
    IF sample_size < 2
    THEN
        RETURN NULL;
    END IF;
    # http://jse.amstat.org/v13n1/olsson.html 3.4 Cox method: a modified version
    RETURN sample_mean + @sample_variance / 2 + critical_value * SQRT(@sample_variance / sample_size + POWER(@sample_variance, 2) / (2 * (sample_size - 1)));
END$$

DELIMITER ;
