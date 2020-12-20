USE chores;

CREATE OR REPLACE VIEW chore_durations_by_person_per_week
AS
WITH durations_per_week AS (SELECT person_id
        , number_of_chores
        , mean_duration_per_day * 5 AS mean_duration_per_week
    FROM chore_durations_by_person_per_weekday
UNION
SELECT person_id
        , SUM(number_of_chores)
        , SUM(mean_duration_per_weekend)
    FROM chore_durations_by_person_per_weekend
    GROUP BY person_id)
SELECT person_id, SUM(mean_duration_per_week) AS mean_duration_per_week
    FROM durations_per_week
    GROUP BY person_id;
