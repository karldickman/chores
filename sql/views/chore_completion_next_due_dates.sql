USE chores;

DROP VIEW IF EXISTS chore_completion_next_due_dates;

CREATE VIEW chore_completion_next_due_dates
AS
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , time_unit AS frequency_unit
        , frequency_since
        , chore_schedule_from_id
        , chore_schedule_from_id_since
        , chore_completion_status_schedule_from_id
        , schedule_from_id
        , schedule_from_date
        , CASE
            WHEN time_unit = 'day'
                THEN DATE_ADD(schedule_from_date, INTERVAL frequency DAY)
            WHEN time_unit = 'month'
                THEN DATE_ADD(schedule_from_date, INTERVAL frequency MONTH)
            END AS next_due_date
    FROM chore_completions_schedule_from_dates
    INNER JOIN time_units
        ON frequency_unit_id = time_units.time_unit_id