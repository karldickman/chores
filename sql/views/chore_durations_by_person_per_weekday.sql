USE chores;

CREATE OR REPLACE VIEW chore_durations_by_person_per_weekday
AS
SELECT person_id
        , COUNT(DISTINCT chore_id) AS number_of_chores
        , SUM(avg_duration_per_day) AS avg_duration_per_day
    FROM chore_durations_per_day_and_people
    WHERE daily AND NOT weekendity
    GROUP BY person_id;
