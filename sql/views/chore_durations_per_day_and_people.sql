USE chores;
# DROP VIEW chore_durations_per_day_and_people;
CREATE OR REPLACE VIEW chore_durations_per_day_and_people
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
        , aggregate_by_id
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , avg_duration_per_day
        , stdev_duration_minutes
        , daily
        , weekly
        , weekendity
        , person_id
    FROM chore_durations_per_day
    JOIN chore_people USING (chore_id);
