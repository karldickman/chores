SET @weekend_start = '2018-06-02 00:00:00';
SET @weekend_end = '2018-06-04 00:00:00';
/*USE chores;
DROP PROCEDURE IF EXISTS chore_burndown;

DELIMITER $$
CREATE PROCEDURE chore_burndown(@weekend_start DATETIME, @weekend_end DATETIME)
BEGIN*/
	SET @time_format = '%H:%i:%S';
	WITH meal_chore_completion_ids AS (SELECT *
		FROM chore_completions
		NATURAL JOIN chore_categories
		NATURAL JOIN categories
		WHERE category = 'meals'),
	non_meal_chore_completions AS (SELECT *
		FROM chore_completions
		WHERE chore_completion_id NOT IN (SELECT chore_completion_id
				FROM meal_chore_completion_ids)),
	up_to_this_weekend AS (SELECT chore_completion_id
			, chore_id
            , chore_completion_status_id
            , chore_completion_status_since
            , due_date
		FROM non_meal_chore_completions
		NATURAL JOIN chore_schedule
		WHERE due_date <= @weekend_end),
	scheduled_this_weekend AS (SELECT *
		FROM up_to_this_weekend
		NATURAL JOIN chore_completion_statuses
		WHERE chore_completion_status = 'scheduled'),
	scheduled_and_completed_this_weekend AS (SELECT up_to_this_weekend.chore_completion_id
			, chore_id
            , due_date
            , chore_completion_status_history_id
            , `from`
            , `to`
            , chore_completion_status_history.chore_completion_status_id
            , chore_completion_status
		FROM up_to_this_weekend
		INNER JOIN chore_completion_status_history
			ON up_to_this_weekend.chore_completion_id = chore_completion_status_history.chore_completion_id
		INNER JOIN chore_completion_statuses
			ON chore_completion_status_history.chore_completion_status_id = chore_completion_statuses.chore_completion_status_id
		WHERE `to` >= @weekend_start
			AND chore_completion_status = 'scheduled'),
	due_this_weekend AS (SELECT chore_completion_id
		FROM scheduled_this_weekend
	UNION
	SELECT chore_completion_id
		FROM scheduled_and_completed_this_weekend),
	relevant_chore_sessions AS (SELECT chore_sessions.*
		FROM chore_sessions
		NATURAL JOIN due_this_weekend),
	chore_sessions_before_this_weekend AS (SELECT *
		FROM relevant_chore_sessions
        WHERE when_completed < @weekend_start),
	chore_sessions_this_weekend AS (SELECT *
		FROM relevant_chore_sessions
        WHERE when_completed >= @weekend_start),
	cumulative_duration_by_chore_session AS (SELECT current_.chore_session_id, SUM(cumulative.duration_minutes) AS cumulative_duration_minutes
		FROM relevant_chore_sessions AS current_
		INNER JOIN relevant_chore_sessions AS cumulative
			ON cumulative.when_completed BETWEEN @weekend_start AND current_.when_completed
		GROUP BY current_.chore_session_id),
	incomplete_as_of_session AS (SELECT chore_completions.*
			, chore_completion_status
			, chore_session_id
			, when_completed
			, when_recorded
			, duration_minutes
		FROM due_this_weekend
		NATURAL JOIN chore_completions
		NATURAL JOIN chore_completion_statuses
		INNER JOIN relevant_chore_sessions
			ON chore_completion_status = 'scheduled'
			OR (chore_completion_status = 'completed'
				AND chore_completion_status_since > when_completed)
		WHERE when_completed BETWEEN @weekend_start AND @weekend_end),
	required_duration AS (SELECT chore_session_id
			, SUM(avg_duration_minutes) AS avg_duration_minutes
			, SQRT(SUM(POWER(stdev_duration_minutes, 2))) AS stddev_duration_minutes
		FROM incomplete_as_of_session
		NATURAL JOIN chore_durations
		GROUP BY chore_session_id),
	remaining_duration AS (SELECT *
			, CASE
				WHEN avg_duration_minutes > cumulative_duration_minutes
					THEN avg_duration_minutes - cumulative_duration_minutes
				ELSE 0
				END AS remaining_duration_minutes
		FROM required_duration
		NATURAL JOIN cumulative_duration_by_chore_session),
	completed_before_the_weekend AS (SELECT chore_completion_id, SUM(duration_minutes) AS duration_minutes
		FROM relevant_chore_sessions
		WHERE when_completed < @weekend_start
		GROUP BY chore_completion_id
	UNION
	SELECT chore_completion_id, 0
		FROM due_this_weekend
		WHERE chore_completion_id NOT IN (SELECT chore_completion_id
				FROM relevant_chore_sessions
				WHERE when_completed < @weekend_start)),
	remaining_durations_and_weekend_start AS (SELECT when_completed, remaining_duration_minutes
		FROM remaining_duration
		NATURAL JOIN chore_sessions
	UNION
	SELECT @weekend_start, SUM(CASE
			WHEN avg_duration_minutes > duration_minutes
				THEN avg_duration_minutes - duration_minutes
			ELSE 0
			END)
		FROM due_this_weekend
		NATURAL JOIN chore_completions
		NATURAL JOIN chore_durations
		NATURAL JOIN completed_before_the_weekend)
	SELECT *
		FROM chore_sessions_this_weekend
	/*
	SELECT when_completed, TIME_FORMAT(SEC_TO_TIME(remaining_duration_minutes * 60), @time_format) AS remaining_duration
		FROM remaining_durations_and_weekend_start
		ORDER BY when_completed;
	*/
/*
END$$

DELIMITER ;
*/