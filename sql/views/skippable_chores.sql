CREATE VIEW skippable_chores
AS
SELECT chore, due_date, next_due_date
	FROM chore_completion_next_due_dates
    NATURAL JOIN chores
    WHERE chore_completion_status_id = 1 # Status = scheduled
		AND next_due_date <= NOW()
        AND chore_id NOT IN (SELECT chore_id
				FROM chore_categories
                WHERE category_id = 1) # Category = meals