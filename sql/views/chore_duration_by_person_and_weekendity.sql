USE chores;
# DROP VIEW chore_duration_by_person_and_weekendity;
CREATE VIEW chore_duration_by_person_and_weekendity
AS
WITH duration_by_person AS (SELECT person_id
        , aggregate_by_id
        , aggregate_key
        , SUM(avg_duration_per_day) AS sum_avg_duration
    FROM chore_durations_per_day
    JOIN chore_people USING (chore_id)
    GROUP BY person_id, aggregate_by_id, aggregate_key),
expand_aggregate_by_none AS (SELECT person_id, aggregate_keys.aggregate_key AS weekendity, sum_avg_duration
    FROM duration_by_person
    JOIN aggregate_keys
        ON aggregate_keys.aggregate_by_id = 2
    WHERE duration_by_person.aggregate_by_id = 0
UNION
SELECT person_id, aggregate_key AS weekendity, sum_avg_duration
    FROM duration_by_person
    WHERE aggregate_by_id = 2)
SELECT person_id, weekendity, SUM(sum_avg_duration) AS sum_avg_duration
    FROM expand_aggregate_by_none
    GROUP BY person_id, weekendity;
