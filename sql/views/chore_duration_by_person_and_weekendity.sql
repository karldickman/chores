USE chores;
# DROP VIEW chore_duration_by_person_and_weekendity;
CREATE OR REPLACE VIEW chore_duration_by_person_and_weekendity
AS
SELECT person_id
        , NOT `weekday` AS weekendity
        , SUM(CASE
            WHEN `weekday` = 1
                THEN avg_duration_per_day
            END) AS avg_duration_per_day
        , SUM(CASE
            WHEN `weekday` = 1
                THEN 5
            WHEN aggregate_by_id = 2 AND aggregate_key = 1 AND period_days < 4
                THEN 2
            ELSE 7
            END * avg_duration_per_day) AS avg_duration_per_week
    FROM chore_durations_per_day_and_people
    GROUP BY person_id, NOT `weekday`;
