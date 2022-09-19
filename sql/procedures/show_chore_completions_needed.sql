USE chores;

DROP PROCEDURE IF EXISTS show_chore_completions_needed;

DELIMITER $$

CREATE PROCEDURE show_chore_completions_needed(chore_name VARCHAR(256))
BEGIN
    IF NOT EXISTS(SELECT * FROM chores WHERE chore = chore_name)
    THEN
        SET @message = CONCAT('Procedure show_chore_completions_needed: no chore with name "', chore_name, '" exists.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message;
    END IF;
    WITH confidence_interval_types AS (SELECT 'relative' AS confidence_interval_type
        UNION
        SELECT 'absolute'),
    to_30_s_and_5_percent AS (SELECT confidence_interval_type
			, aggregate_by_id
            , aggregate_key
            , COALESCE(times_completed, 0) AS times_completed
            , completions_needed
        FROM chores
        CROSS JOIN confidence_interval_types
        LEFT JOIN completions_needed USING (chore_id, aggregate_by_id, confidence_interval_type)
        WHERE chore = chore_name)
    SELECT to_5_percent.aggregate_key
			, to_30_s.times_completed AS `times completed`
            , to_5_percent.completions_needed AS `to 5%`
            , to_30_s.completions_needed AS `to 30 s`
        FROM to_30_s_and_5_percent AS to_5_percent
        JOIN to_30_s_and_5_percent AS to_30_s
            ON to_5_percent.confidence_interval_type = 'relative'
            AND to_30_s.confidence_interval_type = 'absolute'
            AND to_5_percent.aggregate_by_id = to_30_s.aggregate_by_id
            AND to_5_percent.aggregate_key = to_30_s.aggregate_key
		ORDER BY aggregate_key;
END$$

DELIMITER ;
