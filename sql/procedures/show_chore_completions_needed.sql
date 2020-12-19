USE chores;

DROP PROCEDURE IF EXISTS show_chore_completions_needed;

DELIMITER $$

CREATE PROCEDURE show_chore_completions_needed(chore_name VARCHAR(256))
BEGIN
    SET @weekendity = weekendity(NOW());
    WITH to_30_s_and_5_percent AS (SELECT confidence_interval_type
            , times_completed
            , completions_needed
        FROM completions_needed
        WHERE chore = chore_name
            AND (aggregate_by_id = 0 # empty
                OR aggregate_by_id = 2 # weekendity
                    AND aggregate_key = @weekendity))
    SELECT to_30_s.times_completed AS `times completed`
            , to_5_percent.completions_needed AS `to 5%`
            , to_30_s.completions_needed AS `to 30 s`
        FROM to_30_s_and_5_percent AS to_5_percent
        JOIN to_30_s_and_5_percent AS to_30_s
            ON to_5_percent.confidence_interval_type = 'relative'
            AND to_30_s.confidence_interval_type = 'absolute';
END$$

DELIMITER ;
