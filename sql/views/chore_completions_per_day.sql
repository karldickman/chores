USE chores;
# DROP VIEW chore_completions_per_day;
CREATE OR REPLACE VIEW chore_completions_per_day
AS
SELECT `source`
        , chore_id
        , chore
        , aggregate_by_id
        , period
        , period_unit_id
        , period_days
        , completions_per_day / period_days AS completions_per_day
        , period_since
        , schedule_from_id
        , schedule_from_id_since
    FROM chore_periods_days;
