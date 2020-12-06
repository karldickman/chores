USE chores;

CREATE OR REPLACE VIEW exclude_from_chore_durations_per_weekend
AS
# inactive chores
SELECT chore_id
    FROM chores
    WHERE NOT is_active
UNION
# hierarchical chores
SELECT chore_id
    FROM chore_hierarchy
UNION
# physical therapy
SELECT chore_id
    FROM chore_categories
    WHERE category_id = 2;
