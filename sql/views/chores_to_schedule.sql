USE chores;

CREATE OR REPLACE VIEW chores_to_schedule
AS
SELECT chore_id
        , DATE_ADD(next_due_date, INTERVAL -days_in_advance DAY) AS schedule_on
        , next_due_date
    FROM chore_completion_next_due_dates
    JOIN chore_schedule_in_advance USING (chore_id)
    WHERE schedule_from_id = 2 # due date
        AND DATE_ADD(next_due_date, INTERVAL -days_in_advance DAY) <= DATE(CURRENT_TIMESTAMP)
        AND NOT EXISTS(SELECT *
                FROM chore_schedule
                JOIN chore_completions USING (chore_completion_id)
                WHERE chore_completions.chore_id = chore_completion_next_due_dates.chore_id
                    AND due_date >= next_due_date);
