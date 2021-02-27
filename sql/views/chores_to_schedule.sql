USE chores;

CREATE OR REPLACE VIEW chores_to_schedule
AS
WITH last_due_dates AS (SELECT chore_id, MAX(due_date) AS last_due_date
    FROM chore_schedule
    JOIN chore_completions USING (chore_completion_id)
    JOIN chore_schedule_in_advance USING (chore_id)
    JOIN chores USING (chore_id)
    WHERE schedule_from_id = 2 # 'due date'
    GROUP BY chore_id),
scheduling_parameters AS (SELECT chore_id
        , DATE_ADD(last_due_date, INTERVAL period_days - days_in_advance DAY) AS schedule_on
        , DATE_ADD(last_due_date, INTERVAL period_days DAY) AS next_due_date
    FROM last_due_dates
    JOIN chore_schedule_in_advance USING (chore_id)
    JOIN chore_periods_days USING (chore_id)) 
SELECT chore_id, schedule_on, next_due_date
    FROM scheduling_parameters
    WHERE schedule_on <= DATE(CURRENT_TIMESTAMP)
        AND NOT EXISTS(SELECT *
                FROM chore_schedule
                JOIN chore_completions USING (chore_completion_id)
                WHERE chore_completions.chore_id = scheduling_parameters.chore_id
                    AND due_date = next_due_date);
