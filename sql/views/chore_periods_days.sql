USE chores;
CREATE VIEW chore_periods_days
AS
SELECT chore_id
        , frequency AS period
        , frequency_unit_id AS period_unit_id
        , frequency * CASE
            WHEN time_unit_id = 2
                THEN 365 / 12
            ELSE 1
            END AS period_days
        , frequency_since AS period_since
        , schedule_from_id
        , schedule_from_id_since
    FROM chore_frequencies
    JOIN time_units
        ON frequency_unit_id = time_unit_id;
