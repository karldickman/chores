DROP VIEW IF EXISTS chore_duration_confidence_intervals;

CREATE VIEW chore_duration_confidence_intervals
AS
WITH critical_values AS (SELECT critical_value_id
        , one_tail_confidence
        , degrees_of_freedom
        , critical_value
    FROM students_t_critical_values
    WHERE one_tail_confidence = 0.025),
degrees_of_freedom AS (SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , MAX(df_lower_bound.degrees_of_freedom) AS df_lower_bound
        , MIN(df_upper_bound.degrees_of_freedom) AS df_upper_bound
    FROM chore_stderrs
    INNER JOIN critical_values AS df_lower_bound
        ON df_lower_bound.degrees_of_freedom + 1 <= times_completed
    INNER JOIN critical_values AS df_upper_bound
        ON df_upper_bound.degrees_of_freedom + 1 >= times_completed
    GROUP BY chore_id, aggregate_by_id, aggregate_key),
interpolated_critical_values AS (SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , times_completed - 1 AS degrees_of_freedom
        , df_lower_bound
        , df_upper_bound
        , lower_bound_critical_values.critical_value AS critical_value_lower_bound
        , upper_bound_critical_values.critical_value AS critical_value_upper_bound
        , CASE
            WHEN df_lower_bound = df_upper_bound
                THEN lower_bound_critical_values.critical_value
            ELSE (upper_bound_critical_values.critical_value - lower_bound_critical_values.critical_value) # Rise
                / (df_upper_bound - df_lower_bound) # Run
                * ((times_completed - 1) - df_lower_bound) # x translation
                + lower_bound_critical_values.critical_value # y translation
            END AS critical_value
    FROM chore_stderrs
    NATURAL JOIN degrees_of_freedom
    INNER JOIN critical_values AS lower_bound_critical_values
        ON df_lower_bound = lower_bound_critical_values.degrees_of_freedom
    INNER JOIN critical_values AS upper_bound_critical_values
        ON df_upper_bound = upper_bound_critical_values.degrees_of_freedom),
unlimited_degrees_of_freedom_critical_values AS (SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , times_completed - 1 AS degrees_of_freedom
        , critical_value
    FROM chore_stderrs
    INNER JOIN students_t_critical_values_unlimited_degrees_of_freedom
        ON one_tail_confidence = 0.025
    WHERE times_completed - 1 > (SELECT MAX(degrees_of_freedom)
            FROM critical_values)),
chore_critical_values AS (SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , degrees_of_freedom
        , critical_value
    FROM interpolated_critical_values
UNION
SELECT chore_id
        , aggregate_by_id
        , aggregate_key
        , degrees_of_freedom
        , critical_value
    FROM unlimited_degrees_of_freedom_critical_values)        
SELECT chore_stderrs.chore_id
        , chore_stderrs.aggregate_by_id
        , chore_stderrs.aggregate_key
        , chore
        , times_completed
        , avg_number_of_sessions
        , avg_duration_minutes
        , stdev_duration_minutes
        , stderr_duration_minutes
        , critical_value
        , stderr_duration_minutes * CASE
            WHEN times_completed >= 2
                THEN critical_value
            ELSE 1
            END AS `95% CI`
    FROM chore_stderrs
    LEFT OUTER JOIN chore_critical_values
        ON chore_stderrs.chore_id = chore_critical_values.chore_id
        AND chore_stderrs.aggregate_by_id = chore_critical_values.aggregate_by_id
        AND chore_stderrs.aggregate_key = chore_critical_values.aggregate_key
