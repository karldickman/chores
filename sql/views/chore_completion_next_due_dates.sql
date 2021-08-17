USE chores;

CREATE OR REPLACE VIEW chore_completion_next_due_dates
AS
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
                        AND `day` <= DAYOFMONTH(schedule_from_date))),
            '-', `month`, '-', `day`), '%Y-%m-%d') AS next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN chore_due_dates USING (chore_id)),
nearest_due_dates_from_chore_due_dates AS (SELECT chore_completion_id
        , MIN(next_due_date) AS next_due_date
    FROM due_dates_from_chore_due_dates
    GROUP BY chore_completion_id),
due_dates_from_chore_day_of_week AS (SELECT chore_completion_id
        , (DATE(schedule_from_date) + INTERVAL (CASE
            WHEN WEEKDAY(schedule_from_date) = day_of_week
                THEN 7
            ELSE (day_of_week - WEEKDAY(schedule_from_date) + 7) % 7
            END) DAY) AS next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN chore_day_of_week USING (chore_id)),
nearest_due_dates_from_chore_day_of_week AS (SELECT chore_completion_id, MIN(next_due_date) AS next_due_date
    FROM due_dates_from_chore_day_of_week
    GROUP BY chore_completion_id),
`union` AS (SELECT 1 AS period_type_id
        , chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , time_unit AS frequency_unit
        , frequency_since
        , COALESCE(day_of_week, CASE
            WHEN frequency >= 7 AND frequency_unit_id = 1 OR frequency > 0.25 AND frequency_unit_id = 2
                THEN 5
            END) AS day_of_week
        , COALESCE(chore_day_of_week.since, CASE
            WHEN frequency >= 7 AND frequency_unit_id = 1 OR frequency > 0.25 AND frequency_unit_id = 2
                THEN frequency_since
            END) AS day_of_week_since
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , CASE
            WHEN time_unit = 'day'
                THEN schedule_from_date + INTERVAL frequency DAY
            WHEN time_unit = 'month'
                THEN schedule_from_date + INTERVAL frequency MONTH
            END AS next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN chore_frequencies USING (chore_id)
    LEFT JOIN chore_day_of_week USING (chore_id)
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
        , NULL AS day_of_week
        , NULL AS day_of_week_since
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
        , chore_completions_schedule_from_dates.chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , NULL AS frequency
        , NULL AS frequency_unit_id
        , NULL AS frequency_unit
        , NULL AS frequency_since
        , day_of_week
        , since AS day_of_week_since
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , next_due_date
    FROM chore_completions_schedule_from_dates
    JOIN nearest_due_dates_from_chore_day_of_week USING (chore_completion_id)
    JOIN chore_day_of_week
        ON chore_completions_schedule_from_dates.chore_id = chore_day_of_week.chore_id
        AND WEEKDAY(next_due_date) = day_of_week
    WHERE chore_completions_schedule_from_dates.chore_id NOT IN (SELECT chore_id
            FROM chore_frequencies)),
repetitions as (SELECT period_type_id
        , chore_completion_id
        , chore_id
        , ROW_NUMBER() OVER (PARTITION BY chore_id, DATE(due_date) ORDER BY due_date) AS repetition
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , frequency_unit
        , frequency_since
        , day_of_week
        , day_of_week_since
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , next_due_date AS next_due_date_raw
        , DATE(CASE
            WHEN period_type_id = 1 AND day_of_week IS NOT NULL
                THEN nearest_day_of_week(next_due_date, day_of_week)
            ELSE next_due_date
            END) AS next_due_date
    FROM `union`)
SELECT period_type_id
        , chore_completion_id
        , chore_id
        , repetition
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , frequency_unit
        , frequency_since
        , day_of_week
        , day_of_week_since
        , chore_schedule_from_id
        , chore_schedule_from_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , next_due_date_raw
        , chore_time_of_day_id
        , `time`
        , CAST(ADDTIME(next_due_date, COALESCE(chore_time_of_day.`time`, 0)) AS DATETIME) AS next_due_date
    FROM repetitions
    LEFT JOIN chore_time_of_day USING (chore_id, repetition);
