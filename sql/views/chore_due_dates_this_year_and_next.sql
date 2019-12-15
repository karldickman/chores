use chores;

DROP VIEW IF EXISTS chore_due_dates_this_year_and_next;

CREATE VIEW chore_due_dates_this_year_and_next
AS
SELECT chore_id, DATE_ADD(due_date, INTERVAL nearest_sunday_adjustment DAY) AS due_date
    FROM (SELECT chore_id, due_date, weekday, sunday_adjustment, sunday_adjustment - CASE WHEN weekday <= 2 THEN 7 ELSE 0 END AS nearest_sunday_adjustment
            FROM (SELECT chore_id, due_date, weekday, 6 - weekday AS sunday_adjustment
                    FROM (SELECT chore_id, due_date, WEEKDAY(due_date) AS weekday
                            FROM (SELECT chore_id, DATE_ADD(DATE_ADD(MAKEDATE(YEAR(NOW()), 1), INTERVAL `month` - 1 MONTH), INTERVAL `day` - 1 DAY) AS due_date
                                    FROM chore_due_dates
                                UNION
                                SELECT chore_id, DATE_ADD(DATE_ADD(MAKEDATE(YEAR(NOW()) + 1, 1), INTERVAL `month` - 1 MONTH), INTERVAL `day` - 1 DAY) AS due_date
                                    FROM chore_due_dates) AS due_dates) AS weekdays) AS sunday_adjustments) AS nearest_sunday_adjustments
