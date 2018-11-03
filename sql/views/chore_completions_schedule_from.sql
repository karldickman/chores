DROP VIEW IF EXISTS chore_completions_schedule_from;
CREATE VIEW chore_completions_schedule_from
AS
SELECT chore_completions.*
		, chore_frequencies.schedule_from_id AS chore_schedule_from_id
		, chore_completion_status_schedule_from.schedule_from_id AS chore_completion_status_schedule_from_id
        , schedule_from_rules.schedule_from_id
	FROM chore_completions
	INNER JOIN chore_frequencies
		ON chore_completions.chore_id = chore_frequencies.chore_id
    INNER JOIN chore_completion_status_schedule_from
		ON chore_completions.chore_completion_status_id = chore_completion_status_schedule_from.chore_completion_status_id
	INNER JOIN schedule_from_rules
		ON chore_frequencies.schedule_from_id = schedule_from_rules.chore_schedule_from_id
        AND chore_completion_status_schedule_from.schedule_from_id = schedule_from_rules.chore_completion_status_schedule_from_id