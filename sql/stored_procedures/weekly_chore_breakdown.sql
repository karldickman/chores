USE chores;
DROP PROCEDURE IF EXISTS weekly_chore_breakdown;

DELIMITER $$
USE chores$$
CREATE PROCEDURE weekly_chore_breakdown ()
BEGIN
	SELECT chore
			, CASE
				WHEN frequency_unit_id = 1
					THEN 7.0
				ELSE 12 / 52
				END / frequency * avg_duration_minutes AS `duration/weekend`
			, avg_duration_minutes AS `duration/chore`
		FROM chores
		NATURAL JOIN chore_frequencies
		NATURAL JOIN chore_durations
		WHERE chore_id NOT IN (SELECT chore_id
					FROM chore_hierarchy)
			AND chore NOT IN ('close budget period', 'haircut');
END$$

DELIMITER ;