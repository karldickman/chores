USE chores;

DROP PROCEDURE IF EXISTS show_weekly_chores;

DELIMITER $$

CREATE PROCEDURE show_weekly_chores(until_inclusive DATETIME)
BEGIN
    SET until_inclusive = COALESCE(until_inclusive, '2161-10-11');
    SELECT chore_completion_id
            , chore
            , due_date
            , last_completed
            , completed
            , remaining
            , std_dev
            , `90% CI UB`
        FROM report_incomplete_chores
        WHERE due_date <= until_inclusive
            AND chore_completion_id NOT IN (SELECT chore_completion_id
                    FROM do_not_show_in_overdue_chores)
            AND chore_completion_id IN (SELECT chore_completion_id
                    FROM chore_frequencies
                    NATURAL JOIN chore_completions
                    WHERE frequency_unit_id = 1
                        AND frequency <= 7
                UNION
                SELECT chore_completions.chore_completion_id
                    FROM chore_completions
                    NATURAL JOIN chore_completion_hierarchy
                    INNER JOIN chore_completions AS parent_chore_completions
                        ON parent_chore_completion_id = parent_chore_completions.chore_completion_id
                    INNER JOIN chore_frequencies
                        ON parent_chore_completions.chore_id = chore_frequencies.chore_id
                    WHERE frequency_unit_id = 1
                        AND frequency <= 7)
        ORDER BY remaining, std_dev;
    SET @date_format = '%Y-%m-%d %H:%i';
    SET @time_format = '%H:%i:%S';
    SELECT SUM(number_of_chores) AS number_of_chores
            , TIME_FORMAT(SEC_TO_TIME(SUM(backlog_minutes) * 60), @time_format) AS backlog
            , TIME_FORMAT(SEC_TO_TIME(SUM(stdev_backlog_minutes) * 60), @time_format) AS std_dev
            , TIME_FORMAT(SEC_TO_TIME((SUM(non_truncated_backlog_minutes) + 1.282 * SUM(stdev_backlog_minutes)) * 60), @time_format) AS `90% CI UB`
        FROM (SELECT COUNT(chore_id) AS number_of_chores
                , SUM(backlog_minutes) AS backlog_minutes
                , SUM(non_truncated_backlog_minutes) AS non_truncated_backlog_minutes
                , SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stdev_backlog_minutes
            FROM backlog_by_chore
            WHERE due_date <= until_inclusive
                AND chore_id IN (SELECT chore_id
                    FROM chore_frequencies
                    WHERE frequency_unit_id = 1
                        AND frequency <= 7
                UNION
                SELECT chore_hierarchy.chore_id
                    FROM chore_frequencies
                    INNER JOIN chore_hierarchy
                        ON chore_frequencies.chore_id = chore_hierarchy.parent_chore_id
                    WHERE frequency_unit_id = 1
                        AND frequency <= 7)
        UNION
        SELECT COUNT(chore_id) AS number_of_chores
                , SUM(backlog_minutes) AS backlog_minutes
                , SUM(non_truncated_backlog_minutes) AS non_truncated_backlog_minutes
                , SUM(stdev_duration_minutes) AS stdev_backlog_minutes
            FROM never_measured_chores_backlog
            WHERE due_date <= until_inclusive
                AND chore_id IN (SELECT chore_id
                    FROM chore_frequencies
                    WHERE frequency_unit_id = 1
                        AND frequency <= 7
                UNION
                SELECT chore_hierarchy.chore_id
                    FROM chore_frequencies
                    INNER JOIN chore_hierarchy
                        ON chore_frequencies.chore_id = chore_hierarchy.parent_chore_id
                    WHERE frequency_unit_id = 1
                        AND frequency <= 7))
        AS backlog_calculations;
END$$

DELIMITER ;
