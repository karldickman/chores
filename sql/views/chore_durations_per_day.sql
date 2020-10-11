USE chores;
# DROP VIEW chore_durations_per_day;
CREATE OR REPLACE VIEW chore_durations_per_day
AS
SELECT chore_id
        , chore
        , period
        , period_unit_id
        , period_days
        , completions_per_day
        , period_since
        , schedule_from_id
        , schedule_from_id_since
        , chore_durations.aggregate_by_id
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , avg_duration_minutes * completions_per_day AS avg_duration_per_day
        , (chore_durations.aggregate_by_id = 0 AND period_days < 4
            OR chore_durations.aggregate_by_id = 2 AND aggregate_key = 0) AS `weekday`
    FROM chore_completions_per_day
    JOIN chore_durations USING (chore_id);
