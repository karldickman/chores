USE chores;

DROP PROCEDURE IF EXISTS skippable_chores_pretty;

DELIMITER $$

CREATE PROCEDURE skippable_chores_pretty(skippable_as_of DATETIME)
BEGIN
    IF skippable_as_of IS NULL
    THEN
        SET skippable_as_of = NOW();
    END IF;
    SET @date_format = '%Y-%m-%d';
    SELECT chore
            , DATE_FORMAT(due_date, @date_format) AS due_date
            , DATE_FORMAT(next_due_date, @date_format) AS next_due_date
            , schedule_from
            , DATE_FORMAT(schedule_from_date, @date_format) AS schedule_from_date
            , frequency
            , frequency_unit AS unit
            , COALESCE(duration_minutes, 0) AS duration_minutes
        FROM chore_completion_next_due_dates
        JOIN chores USING (chore_id)
        JOIN schedule_from
            ON chore_completion_next_due_dates.schedule_from_id = schedule_from.schedule_from_id
        LEFT JOIN chore_completion_durations
            USING (chore_completion_id)
        WHERE chore_completion_status_id = 1 # Status = scheduled
            AND next_due_date <= skippable_as_of
            AND chore_schedule_from_id != 2; # Schedule from due date;
END$$

DELIMITER ;
