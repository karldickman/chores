USE chores;

DROP VIEW IF EXISTS chore_completions_schedule_from;

CREATE VIEW chore_completions_schedule_from
AS
SELECT chore_completions.chore_completion_id
        , chore_completions.chore_id
        , chore_completions.chore_completion_status_id
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
    LEFT OUTER JOIN chore_schedule
        ON chore_completions.chore_completion_id = chore_schedule.chore_completion_id
    INNER JOIN chore_frequencies
        ON chore_completions.chore_id = chore_frequencies.chore_id
    INNER JOIN chore_completion_status_schedule_from
        ON chore_completions.chore_completion_status_id = chore_completion_status_schedule_from.chore_completion_status_id
    INNER JOIN schedule_from_rules
        ON chore_frequencies.schedule_from_id = schedule_from_rules.chore_schedule_from_id
        AND chore_completion_status_schedule_from.schedule_from_id = schedule_from_rules.chore_completion_status_schedule_from_id
