/*USE chores;

CREATE OR REPLACE VIEW chore_completion_next_due_dates
AS*/
WITH due_dates_from_chore_due_dates AS (SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , STR_TO_DATE(CONCAT(
            YEAR(schedule_from_date)
                + (`month` < MONTH(schedule_from_date)
                    OR (`month` = MONTH(schedule_from_date)
                        AND `day` <= DAY(schedule_from_date))),
            '-', `month`, '-', `day`), '%Y-%m-%d') AS next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN chore_due_dates USING (chore_id)),
nearest_due_dates_from_chore_due_dates AS (SELECT chore_completion_id
        , MIN(next_due_date) AS next_due_date
    FROM due_dates_from_chore_due_dates
    GROUP BY chore_completion_id),
due_dates_from_chore_day_of_week AS (SELECT chore_completion_id
        , DATE_ADD(DATE(schedule_from_date), INTERVAL CASE
            WHEN WEEKDAY(schedule_from_date) = day_of_week
                THEN 7
            ELSE MOD((day_of_week - WEEKDAY(schedule_from_date)) + 7, 7)
            END DAY) AS next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN chore_day_of_week USING (chore_id)),
nearest_due_dates_from_chore_day_of_week AS (SELECT chore_completion_id, MIN(next_due_date) AS next_due_date
    FROM due_dates_from_chore_day_of_week
    GROUP BY chore_completion_id)
SELECT 1 AS period_type_id
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , time_unit AS frequency_unit
        , frequency_since
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , CASE
            WHEN time_unit = 'day'
                THEN DATE_ADD(schedule_from_date, INTERVAL frequency DAY)
            WHEN time_unit = 'month'
                THEN DATE_ADD(schedule_from_date, INTERVAL frequency MONTH)
            END AS next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN chore_frequencies USING (chore_id)
    JOIN time_units
        ON frequency_unit_id = time_units.time_unit_id
UNION
SELECT 2 AS period_type_id
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , NULL AS frequency
        , NULL AS frequency_unit_id
        , NULL AS frequency_unit
        , NULL AS frequency_since
        , NULL AS chore_schedule_from_id
        , NULL AS chore_schedule_from_since
        , NULL AS chore_completion_status_schedule_from_id
        , NULL AS schedule_from_id
        , NULL AS schedule_from_date
        , next_due_date
    FROM nearest_due_dates_from_chore_due_dates
    JOIN chore_completions USING (chore_completion_id)
    LEFT JOIN chore_schedule USING (chore_completion_id)
UNION
SELECT 3 AS period_type_id
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , NULL AS frequency
        , NULL AS frequency_unit_id
        , NULL AS frequency_unit
        , NULL AS frequency_since
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN nearest_due_dates_from_chore_day_of_week USING (chore_completion_id);
