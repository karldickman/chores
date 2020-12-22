USE chores;

CREATE OR REPLACE VIEW chore_periods_days
AS
WITH chore_completions_per_year AS (SELECT chore_id
        , COUNT(*) AS completions_per_year
        , MIN(since) AS since
    FROM chore_due_dates
    GROUP BY chore_id),
chore_completions_per_week AS (SELECT chore_id
        , COUNT(*) AS completions_per_week
        , MIN(since) AS since
    FROM chore_day_of_week
    WHERE chore_id NOT IN (SELECT chore_id
            FROM chore_frequencies)
    GROUP BY chore_id),
`union` AS (SELECT 1 AS period_type_id
        , chore_id
        , frequency AS period
        , frequency_unit_id AS period_unit_id
        , frequency * days AS period_days
        , completions_per_day
        , frequency_since AS period_since
    FROM chore_frequencies
    JOIN chores USING (chore_id)
    JOIN time_units
        ON frequency_unit_id = time_unit_id
UNION
SELECT 2 AS period_type_id
        , chore_id
        , 365 / completions_per_year AS period
        , 1 AS period_unit_id
        , 365 / completions_per_year AS period_days
        , completions_per_year / 365 AS completions_per_day
        , since AS period_since
    FROM chore_completions_per_year
    WHERE chore_id NOT IN (SELECT chore_id
            FROM chore_frequencies)
UNION
SELECT 3 AS period_type_id
        , chore_id
        , 7 / completions_per_week AS period
        , 1 AS period_unit_id
        , 7 / completions_per_week AS period_days
        , completions_per_week / 7 AS completions_per_day
        , since AS period_since
    FROM chore_completions_per_week)
SELECT period_type_id
        , chore_id
        , chore
        , aggregate_by_id
        , is_active
        , period
        , period_unit_id
        , period_days
        , `union`.completions_per_day
        , period_since
    FROM chores
    JOIN `union` USING (chore_id);
