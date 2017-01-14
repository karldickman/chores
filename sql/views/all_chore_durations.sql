ALTER VIEW all_chore_durations
AS
SELECT COUNT(DISTINCT chore_id) AS number_of_chores_with_data
		, AVG(avg_duration_minutes) AS avg_duration_minutes
		, SQRT(SUM(POW(COALESCE(stdev_duration_minutes, 480), 2))) / COUNT(DISTINCT chore_id) AS stdev_duration_minutes
	FROM chore_durations