SET @weekend_start = '2019-12-14 00:00:00';
SET @weekend_end = '2019-12-16 00:00:00';
/*USE chores;
DROP PROCEDURE IF EXISTS chore_burndown;

DELIMITER $$
CREATE PROCEDURE chore_burndown(@weekend_start DATETIME, @weekend_end DATETIME)
BEGIN*/
	SET @time_format = '%H:%i:%S';
    SET @scheduled_status_id = 1;
	# Get all (non-meal) chore completions that are due this weekend
	WITH up_to_this_weekend AS (SELECT chore_completion_id
			, chore_id
            , chore_completion_status_id
            , chore_completion_status_since
            , due_date
		FROM chore_completions
		NATURAL JOIN chore_schedule
		WHERE due_date <= @weekend_end
			AND chore_completion_id NOT IN (SELECT chore_completion_id
					FROM chore_completions
					NATURAL JOIN chore_categories
					WHERE category_id = 1 /* meals */)),
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
		WHERE `to` >= @weekend_start
			AND chore_completion_status_history.chore_completion_status_id = @scheduled_status_id
            AND up_to_this_weekend.chore_completion_status_id != @scheduled_status_id),
	# Combine still incomplete chores and those completed this weekend into master list of chore completions due this weekend
	due_this_weekend AS (SELECT chore_completion_id
		FROM still_incomplete
	UNION
	SELECT chore_completion_id
		FROM scheduled_and_completed_this_weekend),
	# All sessions on chores due this weekend
	relevant_chore_sessions AS (SELECT chore_sessions.*
		FROM chore_sessions
		NATURAL JOIN due_this_weekend),
	# Get list of chore sessions after the start of the weekend
	chore_sessions_this_weekend AS (SELECT *
		FROM relevant_chore_sessions
        WHERE when_completed BETWEEN @weekend_start AND @weekend_end),
	# Running total of chore duration by session
	cumulative_duration_by_chore_session AS (SELECT `current`.chore_session_id
			, SUM(cumulative.duration_minutes) AS cumulative_duration_minutes
		FROM chore_sessions_this_weekend AS `current`
		INNER JOIN chore_sessions_this_weekend AS cumulative
			ON cumulative.when_completed <= `current`.when_completed
		GROUP BY `current`.chore_session_id),
	# Chores that were incomplete when each chore session occurred
	incomplete_as_of_session AS (SELECT DISTINCT chore_completions.*
			, chore_session_id
			, duration_minutes
			, when_completed
		FROM due_this_weekend
		NATURAL JOIN chore_completions
        LEFT OUTER JOIN chore_completion_status_history
			ON chore_completions.chore_completion_id = chore_completion_status_history.chore_completion_id
		INNER JOIN chore_sessions_this_weekend
			# Chore is still incomplete
			ON chore_completions.chore_completion_status_id = @scheduled_status_id
            # Chore was incomplete when session occurred
			OR (chore_completion_status_history.chore_completion_status_id = @scheduled_status_id
				AND when_completed < `to`)),
	# Duration of all outstanding chores as of each chore session
	required_duration AS (SELECT chore_session_id
			, SUM(avg_duration_minutes) AS avg_duration_minutes
			, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stddev_duration_minutes
		FROM incomplete_as_of_session
		NATURAL JOIN chore_durations
		GROUP BY chore_session_id),
	# Subtract cumulative chore sessions from chore duration
	remaining_duration AS (SELECT chore_session_id
            , avg_duration_minutes
            , stddev_duration_minutes
			, CASE
				WHEN avg_duration_minutes > cumulative_duration_minutes
					THEN avg_duration_minutes - cumulative_duration_minutes
				ELSE 0
				END AS remaining_duration_minutes
		FROM required_duration
		NATURAL JOIN cumulative_duration_by_chore_session),
	completed_before_the_weekend AS (SELECT chore_completion_id
			, SUM(duration_minutes) AS duration_minutes
		FROM relevant_chore_sessions
		WHERE when_completed < @weekend_start
		GROUP BY chore_completion_id
	UNION
	SELECT chore_completion_id, 0
		FROM due_this_weekend
		WHERE chore_completion_id NOT IN (SELECT chore_completion_id
				FROM relevant_chore_sessions
				WHERE when_completed < @weekend_start)),
	remaining_durations_and_weekend_boundaries AS (SELECT chore_session_id
			, when_completed
			, duration_minutes AS session_duration_minutes
			, chore_completion_id
			, remaining_duration_minutes
		FROM remaining_duration
		NATURAL JOIN chore_sessions
	UNION
	SELECT NULL
			, @weekend_start
			, NULL
			, NULL
			, SUM(CASE
				WHEN avg_duration_minutes > duration_minutes
					THEN avg_duration_minutes - duration_minutes
				ELSE 0
				END)
		FROM due_this_weekend
		NATURAL JOIN chore_completions
		NATURAL JOIN chore_durations
		NATURAL JOIN completed_before_the_weekend
	UNION
    SELECT NULL, @weekend_end, NULL, NULL, NULL)
	SELECT chore
			, when_completed
			, session_duration_minutes / 60 / 24 AS session_duration_days
			, remaining_duration_minutes / 60 / 24 AS remaining_duration_days
			#, TIME_FORMAT(SEC_TO_TIME(remaining_duration_minutes * 60), @time_format) AS remaining_duration
		FROM remaining_durations_and_weekend_boundaries
        LEFT OUTER JOIN chore_completions
			ON remaining_durations_and_weekend_boundaries.chore_completion_id = chore_completions.chore_completion_id
		LEFT OUTER JOIN chores
			ON chore_completions.chore_id = chores.chore_id
		ORDER BY when_completed;
/*
END$$

DELIMITER ;
*/