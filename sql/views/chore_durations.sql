USE chores;

DROP VIEW IF EXISTS chore_durations;

CREATE VIEW chore_durations
AS
SELECT chore_id, times_completed, avg_number_of_sessions, avg_duration_minutes, stdev_duration_minutes
    FROM chore_durations_by_empty
UNION
SELECT chore_id, times_completed, avg_number_of_sessions, avg_duration_minutes, stdev_duration_minutes
    FROM chore_durations_by_weekday
UNION
SELECT chore_id, times_completed, avg_number_of_sessions, avg_duration_minutes, stdev_duration_minutes
    FROM chore_durations_by_weekendity
