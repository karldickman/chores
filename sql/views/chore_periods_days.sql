USE chores;

CREATE OR REPLACE VIEW chore_periods_days
AS
WITH chore_completions_per_year AS (SELECT chore_id
        , COUNT(*) AS completions_per_year
        , MIN(since) AS since
    FROM chore_due_dates
    GROUP BY chore_id)
SELECT 'chore_frequencies' AS `source`
        , chore_id
        , chore
        , aggregate_by_id
        , is_active
        , frequency AS period
        , frequency_unit_id AS period_unit_id
        , frequency * CASE
            WHEN time_unit_id = 2
                THEN 365 / 12
            ELSE 1
            END AS period_days
        , completions_per_day
        , frequency_since AS period_since
        , schedule_from_id
        , schedule_from_id_since
    FROM chore_frequencies
    JOIN chores USING (chore_id)
    JOIN time_units
        ON frequency_unit_id = time_unit_id
UNION
SELECT 'chore_due_dates' AS `source`
        , chore_id
        , chore
        , aggregate_by_id
        , is_active
        , 365 / completions_per_year AS period
        , 1 AS period_unit_id
        , 365 / completions_per_year AS period_days
        , completions_per_year / 365 AS completions_per_day
        , since AS period_since
        , 3 AS schedule_from_id
        , since AS schedule_from_id_since
    FROM chore_completions_per_year
    JOIN chores USING (chore_id)
    WHERE chore_id NOT IN (SELECT chore_id
            FROM chore_frequencies);     
