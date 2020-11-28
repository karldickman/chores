USE chores;

DROP VIEW IF EXISTS interpolated_critical_values;

CREATE VIEW interpolated_critical_values
AS
WITH explicit_critical_values AS (SELECT critical_value_id
        , one_tail_confidence
        , degrees_of_freedom
        , critical_value
    FROM degrees_of_freedom
    JOIN students_t_critical_values USING (degrees_of_freedom)),
one_tail_confidences AS (SELECT DISTINCT one_tail_confidence
    FROM students_t_critical_values),
interpolated_degrees_of_freedom AS (SELECT one_tail_confidence, degrees_of_freedom
    FROM one_tail_confidences
    CROSS JOIN degrees_of_freedom
    WHERE NOT EXISTS(SELECT *
            FROM explicit_critical_values
            WHERE explicit_critical_values.one_tail_confidence = one_tail_confidences.one_tail_confidence
                AND explicit_critical_values.degrees_of_freedom = degrees_of_freedom.degrees_of_freedom)),
degrees_of_freedom_bounds AS (SELECT interpolated_degrees_of_freedom.one_tail_confidence
        , interpolated_degrees_of_freedom.degrees_of_freedom
        , MAX(lower_bounds.degrees_of_freedom) AS df_lower_bound
        , MIN(upper_bounds.degrees_of_freedom) AS df_upper_bound
    FROM interpolated_degrees_of_freedom
    JOIN students_t_critical_values AS lower_bounds
        ON interpolated_degrees_of_freedom.one_tail_confidence = lower_bounds.one_tail_confidence
        AND interpolated_degrees_of_freedom.degrees_of_freedom > lower_bounds.degrees_of_freedom
    JOIN students_t_critical_values AS upper_bounds
        ON interpolated_degrees_of_freedom.one_tail_confidence = upper_bounds.one_tail_confidence
        AND interpolated_degrees_of_freedom.degrees_of_freedom < upper_bounds.degrees_of_freedom
    GROUP BY interpolated_degrees_of_freedom.one_tail_confidence, interpolated_degrees_of_freedom.degrees_of_freedom),
interpolated_critical_values AS (SELECT degrees_of_freedom_bounds.one_tail_confidence
        , degrees_of_freedom_bounds.degrees_of_freedom
        , df_lower_bound
        , df_upper_bound
        , lower_bound_critical_values.critical_value AS critical_value_lower_bound
        , upper_bound_critical_values.critical_value AS critical_value_upper_bound
        , (upper_bound_critical_values.critical_value - lower_bound_critical_values.critical_value) # Rise
            / (upper_bound_critical_values.degrees_of_freedom - lower_bound_critical_values.degrees_of_freedom) # Run
            * (degrees_of_freedom_bounds.degrees_of_freedom - lower_bound_critical_values.degrees_of_freedom) # x translation
            + lower_bound_critical_values.critical_value # y translation
            AS critical_value
    FROM degrees_of_freedom_bounds
    INNER JOIN students_t_critical_values AS lower_bound_critical_values
        ON degrees_of_freedom_bounds.one_tail_confidence = lower_bound_critical_values.one_tail_confidence
        AND df_lower_bound = lower_bound_critical_values.degrees_of_freedom
    INNER JOIN students_t_critical_values AS upper_bound_critical_values
        ON degrees_of_freedom_bounds.one_tail_confidence = upper_bound_critical_values.one_tail_confidence
        AND df_upper_bound = upper_bound_critical_values.degrees_of_freedom)
SELECT critical_value_id
        , one_tail_confidence
        , degrees_of_freedom
        , NULL AS df_lower_bound
        , NULL AS df_upper_bound
        , NULL AS critical_value_lower_bound
        , NULL AS critical_value_upper_bound
        , critical_value
    FROM explicit_critical_values
UNION ALL
SELECT NULL AS critical_value_id
        , one_tail_confidence
        , degrees_of_freedom
        , df_lower_bound
        , df_upper_bound
        , critical_value_lower_bound
        , critical_value_upper_bound
        , critical_value
    FROM interpolated_critical_values;
