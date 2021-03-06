USE chores;

CREATE OR REPLACE VIEW chore_durations_by_person_per_weekday
AS
SELECT person_id
        , COUNT(DISTINCT chore_id) AS number_of_chores
        , SUM(mean_duration_per_day) AS mean_duration_per_day
    FROM chore_durations_by_person_per_day
    WHERE daily AND NOT weekendity
    GROUP BY person_id;
