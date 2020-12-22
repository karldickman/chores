USE chores;

CREATE OR REPLACE VIEW chore_completions_schedule_from
AS
SELECT chore_completion_id
        , chore_id
        , chore_completion_status_id
        , chore_completion_status_since
        , due_date
        , frequency
        , frequency_unit_id
        , frequency_since
        , chore_frequencies.schedule_from_id AS chore_schedule_from_id
        , schedule_from_id_since AS chore_schedule_from_id_since
        , chore_completion_status_schedule_from.schedule_from_id AS chore_completion_status_schedule_from_id
        , schedule_from_rules.schedule_from_id
    FROM chore_completions
    LEFT JOIN chore_schedule USING (chore_completion_id)
    JOIN chore_frequencies USING (chore_id)
    JOIN chore_completion_status_schedule_from USING (chore_completion_status_id)
    JOIN schedule_from_rules
        ON chore_frequencies.schedule_from_id = schedule_from_rules.chore_schedule_from_id
        AND chore_completion_status_schedule_from.schedule_from_id = schedule_from_rules.chore_completion_status_schedule_from_id;
