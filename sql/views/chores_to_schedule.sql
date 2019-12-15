use chores;

DROP VIEW IF EXISTS chores_to_schedule;

CREATE VIEW chores_to_schedule
AS
SELECT chore_id, schedule_on, next_due_date
    FROM (SELECT chore_id
                , CASE
                    WHEN time_unit = 'day'
                        THEN DATE_ADD(last_due_date, INTERVAL frequency - days_in_advance DAY)
                    WHEN time_unit = 'month'
                        THEN DATE_ADD(DATE_ADD(last_due_date, INTERVAL frequency MONTH), INTERVAL -days_in_advance DAY)
                    END AS schedule_on
                , CASE
                    WHEN time_unit = 'day'
                        THEN DATE_ADD(last_due_date, INTERVAL frequency DAY)
                    WHEN time_unit = 'month'
                        THEN DATE_ADD(last_due_date, INTERVAL frequency MONTH)
                    END AS next_due_date
            FROM (SELECT chore_id, MAX(due_date) AS last_due_date
                    FROM chore_schedule
                    NATURAL JOIN chore_completions
                    NATURAL JOIN chore_schedule_in_advance
                    NATURAL JOIN schedule_from
                    WHERE schedule_from = 'due date'
                    GROUP BY chore_id) AS last_due_dates
                NATURAL JOIN chore_schedule_in_advance
                NATURAL JOIN chore_frequencies
                NATURAL JOIN time_units) AS scheduling_parameters
    WHERE schedule_on <= DATE(CURRENT_TIMESTAMP)
        AND NOT EXISTS(SELECT *
                FROM chore_schedule
                NATURAL JOIN chore_completions
                WHERE chore_completions.chore_id = scheduling_parameters.chore_id
                    AND due_date = next_due_date)
