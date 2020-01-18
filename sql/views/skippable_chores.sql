DROP VIEW IF EXISTS skippable_chores;
CREATE VIEW skippable_chores
AS
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , schedule_from_date
        , schedule_from_id
        , frequency
        , frequency_unit_id
        , frequency_unit
        , next_due_date
    FROM chore_completion_next_due_dates
    WHERE chore_completion_status_id = 1 # Status = scheduled
        AND next_due_date <= NOW()
        AND schedule_from_id != 2 # Schedule from due date
        AND chore_id NOT IN (SELECT chore_id
                FROM chore_categories
                WHERE category_id = 1) # Category = meals
