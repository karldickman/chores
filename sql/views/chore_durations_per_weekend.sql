USE chores;
# DROP VIEW chore_durations_per_weekend;
CREATE OR REPLACE VIEW chore_durations_per_weekend
AS
SELECT daily
        , weekly
        , COUNT(chore_id) AS number_of_chores
        , AVG(completions_per_day * days_per_weekend) AS completions_per_weekend
        , SUM(avg_duration_per_day * days_per_weekend) AS avg_duration_per_weekend
    FROM chore_durations_per_day
    JOIN days_per_weekend USING (daily)
    WHERE weekendity = 1
        AND chore_id NOT IN (SELECT chore_id
            FROM exclude_from_chore_durations_per_weekend)
    GROUP BY daily, weekly;
