USE chores;

DROP PROCEDURE IF EXISTS chore_burndown;

DELIMITER $$
CREATE PROCEDURE chore_burndown(`from` DATETIME, `until` DATETIME)
BEGIN
    SET @`from` = `from`;
    SET @`until` = DATE_ADD(DATE(`until`), INTERVAL 1 DAY);
    SET @time_format = '%H:%i:%S';
    SET @scheduled_status_id = 1;
    SET @skipped_status_id = 2;
    SET @insufficient_data_status_id = 3;
    SET @completed_status_id = 4;
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
            AND chore_completion_status_id != @skipped_status_id
            # Exclude all hierarchical chore completions with no sessions
            AND chore_completions.chore_completion_id NOT IN (SELECT parent_chore_completion_id
                    FROM chore_completion_hierarchy
                    WHERE parent_chore_completion_id NOT IN (SELECT chore_completion_id
                            FROM chore_sessions))),
    # Get chore completions due this weekend that are still incomplete
    still_incomplete AS (SELECT chore_completion_id
            , chore_id
            , chore # Included for debugging
            , due_date
            , chore_completion_status_id
            , chore_completion_status_since
        FROM up_to_this_weekend
        NATURAL JOIN chores # Included for debugging
        WHERE chore_completion_status_id = @scheduled_status_id),
    # Get chore completions that were overdue this weekend but are now completed
    scheduled_and_completed_this_weekend AS (SELECT up_to_this_weekend.chore_completion_id
            , chore_id
            , chore # Included for debugging
            , due_date
            , chore_completion_status_id
            , chore_completion_status_since
        FROM up_to_this_weekend
        NATURAL JOIN chores # Included for debugging
        WHERE chore_completion_status_since >= @`from`
            AND chore_completion_status_id IN (@insufficient_data_status_id, @completed_status_id)),
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
    # Final chore sessions
    final_chore_sessions AS (SELECT DISTINCT chore_session_id
        FROM chore_completions_when_completed
        NATURAL JOIN relevant_chore_sessions
        NATURAL JOIN chore_completions
        WHERE chore_completion_status_id = @completed_status_id),
    # Timestamps on chores due this weekend
    timestamps AS (SELECT 'chore_sessions' AS `source`
            , chore_sessions.chore_session_id AS timestamp_id
            , chore_completion_id
            , when_completed AS `timestamp`
            , final_chore_sessions.chore_session_id IS NOT NULL AS is_chore_complete
            , duration_minutes
        FROM chore_sessions
        NATURAL JOIN due_this_weekend
        LEFT OUTER JOIN final_chore_sessions
            ON chore_sessions.chore_session_id = final_chore_sessions.chore_session_id
    UNION
    SELECT 'chore_completion_times' AS `source`
            , chore_completion_id AS timestamp_id
            , chore_completion_id
            , when_completed AS `timestamp`
            , TRUE AS is_chore_complete
            , 0 AS duration_minutes
        FROM chore_completion_times
        NATURAL JOIN chore_completions
        NATURAL JOIN due_this_weekend
        WHERE chore_completion_status_id = @insufficient_data_status_id),
    # Get list of chore sessions after the start of the weekend
    timestamps_this_weekend AS (SELECT `source`
            , timestamp_id
            , `timestamp`
            , duration_minutes
        FROM timestamps
        WHERE `timestamp` BETWEEN @`from` AND @`until`),
    # Chores that were incomplete when each chore session occurred
    incomplete_as_of_timestamp AS (SELECT DISTINCT chore_completions.chore_completion_id
            , chore_id
            , chore_completions.chore_completion_status_id
            , chore_completion_status_since
            , when_completed
            , timestamps.`source`
            , timestamp_id
            , `timestamp`
        FROM due_this_weekend
        NATURAL JOIN chore_completions
        LEFT OUTER JOIN chore_completions_when_completed
            ON chore_completions.chore_completion_id = chore_completions_when_completed.chore_completion_id
        LEFT OUTER JOIN timestamps_this_weekend AS timestamps
            ON chore_completion_status_id = @scheduled_status_id
            OR (chore_completion_status_id IN (@insufficient_data_status_id, @completed_status_id)
                AND `timestamp` < when_completed)),
    # Duration of all outstanding chores as of each chore session
    required_duration_by_timestamp AS (SELECT chore_completion_id
            , chore_id
            , chore_completion_status_id
            , chore_completion_status_since
            , `source`
            , timestamp_id
            , `timestamp`
            , avg_duration_minutes AS avg_chore_duration_minutes
            , stdev_duration_minutes AS stdev_chore_duration_minutes
        FROM incomplete_as_of_timestamp
        NATURAL JOIN chore_durations),
    # Running total of chore duration by session
    chore_sessions_by_timestamp AS (SELECT `source`
            , timestamp_id
            , `timestamp`
            , chore_session_id
            , when_completed
            , chore_sessions.duration_minutes AS chore_session_duration_minutes
            , when_recorded
            , chore_completion_id
        FROM timestamps_this_weekend AS timestamps
        INNER JOIN relevant_chore_sessions AS chore_sessions
            ON chore_sessions.when_completed <= `timestamp`),
    cumulative_duration_by_timestamp_and_chore_completion AS (SELECT timestamp_id
            , chore_completion_id
            , SUM(chore_session_duration_minutes) AS cumulative_duration_minutes
        FROM chore_sessions_by_timestamp
        GROUP BY timestamp_id, chore_completion_id),
    # Subtract cumulative chore sessions from chore duration
    remaining_duration_by_timestamp_and_chore_completion AS (SELECT required_duration.chore_completion_id
            , chore_id
            , chore_completion_status_id
            , chore_completion_status_since
            , `source`
            , required_duration.timestamp_id
            , `timestamp`
            , avg_chore_duration_minutes
            , stdev_chore_duration_minutes
            , cumulative_duration_minutes
            , CASE
                WHEN chore_completion_status_id IN (@insufficient_data_status_id, @completed_status_id)
                    THEN 0
                WHEN cumulative_duration_minutes IS NULL
                    THEN avg_chore_duration_minutes
                WHEN avg_chore_duration_minutes > cumulative_duration_minutes
                    THEN avg_chore_duration_minutes - cumulative_duration_minutes
                ELSE 0
                END AS remaining_duration_minutes
        FROM required_duration_by_timestamp AS required_duration
        LEFT OUTER JOIN cumulative_duration_by_timestamp_and_chore_completion AS completed_duration
            ON required_duration.timestamp_id = completed_duration.timestamp_id
            AND required_duration.chore_completion_id = completed_duration.chore_completion_id),
    remaining_duration_by_timestamp AS (SELECT timestamp_id
            , COUNT(DISTINCT chore_id) AS number_of_chores
            , SUM(avg_chore_duration_minutes) AS avg_chore_duration_minutes
            , SQRT(SUM(POWER(stdev_chore_duration_minutes, 2))) AS stdev_chore_duration_minutes
            , SUM(remaining_duration_minutes) AS remaining_duration_minutes
        FROM remaining_duration_by_timestamp_and_chore_completion
        GROUP BY timestamp_id),
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
    from_argument_chore_completions AS (SELECT chore_id
            , chore_completion_id
            , chore_completion_status_id
            , chore_completion_status_since
            , duration_minutes
            , avg_duration_minutes
            , CASE
                WHEN avg_duration_minutes > duration_minutes
                    THEN avg_duration_minutes - duration_minutes
                ELSE 0
                END AS remaining_duration_minutes
        FROM due_this_weekend
        NATURAL JOIN chore_completions
        NATURAL JOIN chore_durations
        NATURAL JOIN completed_before_the_weekend),
    remaining_durations_and_weekend_boundaries AS (SELECT `source` AS timestamp_source
            , timestamp_id
            , `timestamp`
            , number_of_chores
            , duration_minutes AS session_duration_minutes
            , chore_completion_id
            , is_chore_complete
            , remaining_duration_minutes
        FROM remaining_duration_by_timestamp
        NATURAL JOIN timestamps
    # First record
    UNION
    SELECT 'from argument' AS timestamp_source
            , NULL AS timestamp_id
            , @`from` AS `timestamp`
            , COUNT(DISTINCT chore_id) AS number_of_chores
            , 0 AS session_duration_minutes
            , NULL AS chore_completion_id
            , NULL AS is_chore_complete
            , SUM(remaining_duration_minutes) AS remaining_duration_minutes
        FROM from_argument_chore_completions
    # Last record
    UNION
    SELECT 'to parameter' AS timestamp_source
            , NULL AS timestamp_id
            , @`until` AS `timestamp`
            , COUNT(DISTINCT chore_id) AS number_of_chores
            , 0 AS session_duration_minutes
            , NULL AS chore_completion_id
            , NULL AS is_chore_complete
            , NULL AS remaining_duration_minutes
        FROM still_incomplete)
    SELECT timestamp_source
            , `timestamp`
            , chore
            , is_chore_complete
            , session_duration_minutes
            , number_of_chores
            , remaining_duration_minutes
        FROM remaining_durations_and_weekend_boundaries
        LEFT OUTER JOIN chore_completions
            ON remaining_durations_and_weekend_boundaries.chore_completion_id = chore_completions.chore_completion_id
        LEFT OUTER JOIN chores
            ON chore_completions.chore_id = chores.chore_id
        ORDER BY `timestamp`;
END$$

DELIMITER ;
