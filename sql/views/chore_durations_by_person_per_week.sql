USE chores;

CREATE OR REPLACE VIEW chore_durations_by_person_per_week
AS
WITH durations_per_week AS (SELECT person_id, number_of_chores, avg_duration_per_day * 5 AS avg_duration_per_week
    FROM chore_durations_by_person_per_weekday
UNION
SELECT person_id
        , SUM(number_of_chores)
        , SUM(avg_duration_per_weekend)
    FROM chore_durations_by_person_per_weekend
    GROUP BY person_id)
SELECT person_id, SUM(avg_duration_per_week) AS avg_duration_per_week
    FROM durations_per_week
    GROUP BY person_id;