USE chores;
# DROP VIEW chore_completions_per_day;
CREATE VIEW chore_completions_per_day
AS
WITH chore_completions_per_year AS (SELECT chore_id
        , COUNT(*) AS completions_per_year
        , MIN(since) AS since
    FROM chore_due_dates
    GROUP BY chore_id)
SELECT chore_id
        , chore
        , aggregate_by_id
        , period
        , period_unit_id
        , period_days
        , completions_per_day
        , period_since
        , schedule_from_id
        , schedule_from_id_since
    FROM chore_completions_per_day_from_period
UNION
SELECT chore_id
        , chore
        , aggregate_by_id
        , 365 / completions_per_year AS period
        , 1 AS period_unit_id
        , 365 / completions_per_year AS period_days
        , completions_per_year / 365 AS completions_per_day
        , since AS period_since
        , 3 AS schedule_from_id
        , since AS schedule_from_id_since
    FROM chore_completions_per_year
    JOIN chores USING (chore_id)