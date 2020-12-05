USE chores;
# DROP VIEW chore_durations_per_weekend;
CREATE OR REPLACE VIEW chore_durations_per_weekend
AS
WITH completions_per_weekend AS (SELECT FALSE AS daily, 7 AS days_per_weekend
UNION
SELECT TRUE AS daily, 2 AS days_per_weekend)
SELECT daily
        , weekly
        , COUNT(chore_id) AS number_of_chores
        , AVG(completions_per_day * days_per_weekend) AS completions_per_weekend
        , SUM(avg_duration_per_day * days_per_weekend) AS avg_duration_per_weekend
    FROM chore_durations_per_day
    JOIN completions_per_weekend USING (daily)
    WHERE `weekday` = 0
        AND chore_id IN (SELECT chore_id
                FROM chore_completions
                WHERE chore_completion_status_id = 1)
    GROUP BY daily, weekly;
