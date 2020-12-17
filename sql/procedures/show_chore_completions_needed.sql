USE chores;

DROP PROCEDURE IF EXISTS show_chore_completions_needed;

DELIMITER $$

CREATE PROCEDURE show_chore_completions_needed(chore_completion_id_to_summarize INT)
BEGIN
    WITH to_30_s_and_5_percent AS (SELECT confidence_interval_type
            , chore_completion_id
            , times_completed
            , completions_needed
        FROM chore_completions
        JOIN chore_schedule USING (chore_completion_id)
        JOIN completions_needed
            ON chore_completions.chore_id = completions_needed.chore_id
            AND (aggregate_by_id = 0 # empty
                OR aggregate_by_id = 2 # weekendity
                    AND weekendity(due_date) = aggregate_key)
        WHERE chore_completion_id = chore_completion_id_to_summarize)
    SELECT to_30_s.chore_completion_id
            , to_30_s.times_completed
            , to_30_s.completions_needed AS `to 30 s`
            , to_5_percent.completions_needed AS `to 5%`
        FROM to_30_s_and_5_percent AS to_30_s
        JOIN to_30_s_and_5_percent AS to_5_percent
            ON to_30_s.chore_completion_id = to_5_percent.chore_completion_id
            AND to_30_s.confidence_interval_type = 'absolute'
            AND to_5_percent.confidence_interval_type = 'relative';
END$$

DELIMITER ;
