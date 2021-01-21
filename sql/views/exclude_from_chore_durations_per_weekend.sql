USE chores;

CREATE OR REPLACE VIEW exclude_from_chore_durations_per_weekend
AS
WITH chores_on_day_of_week AS (SELECT DISTINCT chore_id
    FROM chore_day_of_week),
chore_day_of_week_booleans AS (SELECT chore_id
        , day_of_week
        , chore_day_of_week_id IS NOT NULL AS chore_on_day
    FROM chores_on_day_of_week
    CROSS JOIN days_of_week
    LEFT JOIN chore_day_of_week USING (chore_id, day_of_week))
# inactive chores
SELECT 'inactive' AS reason, chore_id
    FROM chores
    WHERE NOT is_active
UNION
# hierarchical chores
SELECT 'has parent chore' AS reason, chore_id
    FROM chore_hierarchy
UNION
# physical therapy
SELECT 'physical therapy' AS reason, chore_id
    FROM chore_categories
    WHERE category_id = 2
UNION
SELECT 'weekday' AS reason, saturday.chore_id
    FROM chore_day_of_week_booleans AS saturday
    NATURAL JOIN chores
    JOIN chore_day_of_week_booleans AS sunday
        ON saturday.chore_id = sunday.chore_id
        AND saturday.day_of_week = 5
        AND sunday.day_of_week = 6
    WHERE NOT (saturday.chore_on_day OR sunday.chore_on_day);
