USE chores;
DROP PROCEDURE IF EXISTS chore_burndown;

DELIMITER $$
CREATE PROCEDURE chore_burndown(`from` DATETIME, `until` DATETIME)
BEGIN
	SET @`from` = `from`;
	SET @`until` = DATE_ADD(DATE(`until`), INTERVAL 1 DAY);
	SET @time_format = '%H:%i:%S';
    SET @scheduled_status_id = 1;
	# Get all chore completions that are due this weekend
	WITH up_to_this_weekend AS (SELECT chore_completion_id
			, chore_id
            , chore_completion_status_id
            , chore_completion_status_since
            , due_date
		FROM chore_completions
		NATURAL JOIN hierarchical_chore_schedule
		WHERE due_date <= @`until`
			# Skipping chores should not advance the burndown
			AND chore_completion_status_id != 2 /* skipped */),
	# Get chore completions due this weekend that are still incomplete
	still_incomplete AS (SELECT chore_completion_id
			, chore_id
            , chore
            , due_date
            , chore_completion_status_id
            , chore_completion_status_since
		FROM up_to_this_weekend
        NATURAL JOIN chores # Included for debugging
		WHERE chore_completion_status_id = @scheduled_status_id),
	# Get chore completions that were overdue this weekend but are now completed
	scheduled_and_completed_this_weekend AS (SELECT up_to_this_weekend.chore_completion_id
			, chore_id
            , chore
            , due_date
            , chore_completion_status_history_id
            , `from`
            , `to`
            , chore_completion_status_history.chore_completion_status_id
		FROM up_to_this_weekend
        NATURAL JOIN chores # Included for debugging
		INNER JOIN chore_completion_status_history
			ON up_to_this_weekend.chore_completion_id = chore_completion_status_history.chore_completion_id
		WHERE `to` >= @`from`
			AND chore_completion_status_history.chore_completion_status_id = @scheduled_status_id
            AND up_to_this_weekend.chore_completion_status_id != @scheduled_status_id),
	# Combine still incomplete chores and those completed this weekend into master list of chore completions due this weekend
	due_this_weekend AS (SELECT chore_completion_id
		FROM still_incomplete
	UNION
	SELECT chore_completion_id
		FROM scheduled_and_completed_this_weekend),
	# All sessions on chores due this weekend
	relevant_chore_sessions AS (SELECT chore_session_id
			, when_completed
            , duration_minutes
            , when_recorded
            , chore_completion_id
		FROM chore_sessions
		NATURAL JOIN due_this_weekend),
	# Get list of chore sessions this weekend
    chore_sessions_this_weekend AS (SELECT chore_session_id
			, when_completed
            , duration_minutes
            , when_recorded
            , chore_completion_id
		FROM relevant_chore_sessions
        WHERE when_completed BETWEEN @`from` AND @`until`),
	# Timestamps on chores due this weekend
	timestamps AS (SELECT 'chore_sessions' AS `source`
			, chore_session_id AS timestamp_id
            , chore_completion_id
            , when_completed
            , duration_minutes
		FROM chore_sessions
		NATURAL JOIN due_this_weekend
	UNION
    SELECT 'chore_completion_times' AS `source`
			, chore_completion_id AS timestamp_id
            , chore_completion_id
            , when_completed
            , 0 AS duration_minutes
		FROM chore_completion_times
        NATURAL JOIN chore_completions
        NATURAL JOIN due_this_weekend
        WHERE chore_completion_status_id = 3 /* unknown duration */
	UNION
    SELECT 'to argument' AS `source`
		, 1 AS timestamp_id
        , NULL AS chore_completion_id
        , @`until` AS when_completed
        , 0 AS duration_minutes),
	# Get list of chore sessions after the start of the weekend
	timestamps_this_weekend AS (SELECT `source`
			, timestamp_id
            , when_completed
            , duration_minutes
		FROM timestamps
        WHERE when_completed BETWEEN @`from` AND @`until`),
	# Chores that were incomplete when each chore session occurred
	incomplete_as_of_timestamp AS (SELECT DISTINCT chore_completions.*
			, `source` AS timestamp_source
			, timestamp_id
			, duration_minutes
			, when_completed
		FROM due_this_weekend
		NATURAL JOIN chore_completions
        LEFT OUTER JOIN chore_completion_status_history
			ON chore_completions.chore_completion_id = chore_completion_status_history.chore_completion_id
		INNER JOIN timestamps_this_weekend
			# Chore is still incomplete
			ON chore_completions.chore_completion_status_id = @scheduled_status_id
            # Chore was incomplete when session occurred
			OR (chore_completion_status_history.chore_completion_status_id = @scheduled_status_id
				AND when_completed < `to`)),
	# Duration of all outstanding chores as of each chore session
	required_duration AS (SELECT timestamp_id
			, COUNT(DISTINCT chore_id) AS number_of_chores
			, SUM(avg_duration_minutes) AS avg_duration_minutes
			, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stddev_duration_minutes
		FROM incomplete_as_of_timestamp
		NATURAL JOIN chore_durations
		GROUP BY timestamp_id),
	# Running total of chore duration by session
	cumulative_duration_by_timestamp AS (SELECT `current`.timestamp_id
			, SUM(cumulative.duration_minutes) AS cumulative_duration_minutes
		FROM timestamps_this_weekend AS `current`
		INNER JOIN chore_sessions_this_weekend AS cumulative
			ON cumulative.when_completed <= `current`.when_completed
		GROUP BY `current`.timestamp_id),
	# Subtract cumulative chore sessions from chore duration
	remaining_duration AS (SELECT timestamp_id
			, number_of_chores
            , avg_duration_minutes
            , stddev_duration_minutes
			, CASE
				WHEN avg_duration_minutes > cumulative_duration_minutes
					THEN avg_duration_minutes - cumulative_duration_minutes
				ELSE 0
				END AS remaining_duration_minutes
		FROM required_duration
		NATURAL JOIN cumulative_duration_by_timestamp),
	completed_before_the_weekend AS (SELECT chore_completion_id
			, SUM(duration_minutes) AS duration_minutes
		FROM relevant_chore_sessions
		WHERE when_completed < @`from`
		GROUP BY chore_completion_id
	UNION
	SELECT chore_completion_id, 0
		FROM due_this_weekend
		WHERE chore_completion_id NOT IN (SELECT chore_completion_id
				FROM relevant_chore_sessions
				WHERE when_completed < @`from`)),
	remaining_durations_and_weekend_boundaries AS (SELECT `source` AS timestamp_source
            , timestamp_id
			, number_of_chores
			, when_completed
			, duration_minutes AS session_duration_minutes
			, chore_completion_id
			, remaining_duration_minutes
		FROM remaining_duration
        NATURAL JOIN timestamps
	# First record
	UNION
	SELECT 'from argument' AS timestamp_source
			, NULL AS timestamp_id
            , COUNT(DISTINCT chore_id) AS number_of_chores
			, @`from` AS when_completed
			, 0 AS session_duration_minutes
			, NULL AS chore_completion_id
			, SUM(CASE
				WHEN avg_duration_minutes > duration_minutes
					THEN avg_duration_minutes - duration_minutes
				ELSE 0
				END) AS remaining_duration_minutes
		FROM due_this_weekend
		NATURAL JOIN chore_completions
		NATURAL JOIN chore_durations
		NATURAL JOIN completed_before_the_weekend)
	SELECT timestamp_source
			, chore
			, when_completed
			, session_duration_minutes
            , number_of_chores
			, remaining_duration_minutes
		FROM remaining_durations_and_weekend_boundaries
        LEFT OUTER JOIN chore_completions
			ON remaining_durations_and_weekend_boundaries.chore_completion_id = chore_completions.chore_completion_id
		LEFT OUTER JOIN chores
			ON chore_completions.chore_id = chores.chore_id
		ORDER BY when_completed;
END$$

DELIMITER ;
