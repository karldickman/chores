CREATE OR REPLACE VIEW chore_completion_overdue_statuses
AS
SELECT chore_completion_id
        , chore_id
        , chore
        , due_date
        , next_due_date
        , frequency
        , overdue_chore_completion_status_id
        , chore_completion_status AS overdue_chore_completion_status
    FROM chore_completion_next_due_dates
    JOIN chores USING (chore_id)
    LEFT JOIN chore_overdue_statuses USING (chore_id)
    LEFT JOIN chore_completion_statuses
    ON overdue_chore_completion_status_id = chore_completion_statuses.chore_completion_status_id
    WHERE chore_completion_next_due_dates.chore_completion_status_id = 1 -- active
    ORDER BY overdue_chore_completion_status DESC, next_due_date, due_date;
