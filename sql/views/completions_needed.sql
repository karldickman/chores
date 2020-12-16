USE chores;

CREATE OR REPLACE VIEW completions_needed
AS
WITH hypothetical_confidence_intervals AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , stdev_duration_minutes
        , chore_duration_confidence_intervals.degrees_of_freedom
        , chore_duration_confidence_intervals.one_tail_critical_value
        , `one tail 95% CI UB`
        , students_t_critical_values.degrees_of_freedom AS hypothetical_degrees_of_freedom
        , students_t_critical_values.critical_value AS hypothetical_critical_value
        , EXP(log_normal_confidence_bound(avg_log_duration_minutes, stdev_log_duration_minutes, students_t_critical_values.degrees_of_freedom, students_t_critical_values.critical_value)) AS `hypothetical 95% CI UB`
    FROM chore_duration_confidence_intervals
    LEFT JOIN students_t_critical_values
        ON one_tail_confidence = 0.05
        AND chore_duration_confidence_intervals.degrees_of_freedom <= students_t_critical_values.degrees_of_freedom),
unlimited_degrees_of_freedom AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , stdev_duration_minutes
        , chore_duration_confidence_intervals.degrees_of_freedom
        , chore_duration_confidence_intervals.one_tail_critical_value
        , `one tail 95% CI UB`
        , students_t_critical_values_unlimited_degrees_of_freedom.critical_value AS hypothetical_critical_value
    FROM chore_duration_confidence_intervals
    JOIN students_t_critical_values_unlimited_degrees_of_freedom
        ON one_tail_confidence = 0.05),
inequality_coefficients AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , stdev_duration_minutes
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , avg_duration_minutes + 0.5 AS `+ 30 s CI UB`
        , LOG(avg_duration_minutes + 0.5) AS `log(+ 30 s CI UB)`
        , POWER(LOG(1 + 0.5 / avg_duration_minutes)
            / (one_tail_critical_value * stdev_log_duration_minutes), 2) AS absolute_ci_inequality_coefficient
        , avg_duration_minutes * 1.05 AS `+ 5% CI UB`
        , LOG(avg_duration_minutes * 1.05) AS `log(+ 5% CI UB)`
        , POWER(LOG(1.05)
            / (one_tail_critical_value * stdev_log_duration_minutes), 2) AS relative_ci_inequality_coefficient
    FROM unlimited_degrees_of_freedom),
quadratic_coefficients AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , stdev_duration_minutes
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , `+ 30 s CI UB`
        , `log(+ 30 s CI UB)`
        , absolute_ci_inequality_coefficient
        , -2 * absolute_ci_inequality_coefficient AS A_absolute
        , (POWER(stdev_log_duration_minutes, 2) + 2 * absolute_ci_inequality_coefficient + 2) AS B_absolute
        , -2 AS C
        , `+ 5% CI UB`
        , `log(+ 5% CI UB)`
        , relative_ci_inequality_coefficient
        , -2 * relative_ci_inequality_coefficient AS A_relative
        , (POWER(stdev_log_duration_minutes, 2) + 2 * relative_ci_inequality_coefficient + 2) AS B_relative
    FROM inequality_coefficients),
unlimited_df_times_needed AS (SELECT chore_id
        , chore
        , aggregate_by_id
        , completions_per_day
        , aggregate_key
        , times_completed
        , avg_number_of_sessions
        , arithmetic_avg_duration_minutes
        , arithmetic_stdev_duration_minutes
        , avg_log_duration_minutes
        , stdev_log_duration_minutes
        , mode_duration_minutes
        , median_duration_minutes
        , avg_duration_minutes
        , stdev_duration_minutes
        , degrees_of_freedom
        , one_tail_critical_value
        , `one tail 95% CI UB`
        , hypothetical_critical_value
        , `+ 30 s CI UB`
        , `log(+ 30 s CI UB)`
        , absolute_ci_inequality_coefficient
        , A_absolute
        , B_absolute
        , C
        , relative_ci_inequality_coefficient
        , CEIL((-B_absolute - SQRT(POWER(B_absolute, 2) - 4 * A_absolute * C)) / (2 * A_absolute) - times_completed) AS `to 30 s`
        , A_relative
        , B_relative
        , CEIL((-B_relative - SQRT(POWER(B_relative, 2) - 4 * A_relative * C)) / (2 * A_relative) - times_completed) AS `to 5%`
    FROM quadratic_coefficients),
df_to_30_s AS (SELECT chore_id
        , MIN(hypothetical_degrees_of_freedom) AS hypothetical_degrees_of_freedom
        , MIN(hypothetical_degrees_of_freedom - degrees_of_freedom) AS completions_needed
    FROM hypothetical_confidence_intervals
    WHERE `hypothetical 95% CI UB` - avg_duration_minutes < 0.5
    GROUP BY chore_id),
`df_to_5%` AS (SELECT chore_id
        , MIN(hypothetical_degrees_of_freedom) AS hypothetical_degrees_of_freedom
        , MIN(hypothetical_degrees_of_freedom - degrees_of_freedom) AS completions_needed
    FROM hypothetical_confidence_intervals
    WHERE `hypothetical 95% CI UB` / avg_duration_minutes - 1 < 0.05
    GROUP BY chore_id)
SELECT chore_duration_confidence_intervals.chore_id
        , chore_duration_confidence_intervals.chore
        , chore_duration_confidence_intervals.aggregate_by_id
        , chore_duration_confidence_intervals.completions_per_day
        , chore_duration_confidence_intervals.aggregate_key
        , chore_duration_confidence_intervals.times_completed
        , chore_duration_confidence_intervals.avg_number_of_sessions
        , chore_duration_confidence_intervals.arithmetic_avg_duration_minutes
        , chore_duration_confidence_intervals.arithmetic_stdev_duration_minutes
        , chore_duration_confidence_intervals.avg_log_duration_minutes
        , chore_duration_confidence_intervals.stdev_log_duration_minutes
        , chore_duration_confidence_intervals.mode_duration_minutes
        , chore_duration_confidence_intervals.median_duration_minutes
        , chore_duration_confidence_intervals.avg_duration_minutes
        , chore_duration_confidence_intervals.stdev_duration_minutes
        , chore_duration_confidence_intervals.degrees_of_freedom
        , chore_duration_confidence_intervals.one_tail_critical_value
        , chore_duration_confidence_intervals.`one tail 95% CI UB`
        , chore_duration_confidence_intervals.`one tail 95% CI UB` - chore_duration_confidence_intervals.avg_duration_minutes AS `one tail 95% CI absolute`
        , chore_duration_confidence_intervals.`one tail 95% CI UB` / chore_duration_confidence_intervals.avg_duration_minutes - 1 AS `one tail 95% CI relative`
        , df_to_30_s.hypothetical_degrees_of_freedom AS `hypothetical degrees of freedom at 30 s`
        , `df_to_5%`.hypothetical_degrees_of_freedom AS `hypothetical degrees of freedom at 5%`
        , COALESCE(`hypothetical confidence intervals at 30 s`.hypothetical_critical_value, unlimited_df_times_needed.hypothetical_critical_value) AS `hypothetical critical value at 30 s`
        , COALESCE(`hypothetical confidence intervals at 5%`.hypothetical_critical_value, unlimited_df_times_needed.hypothetical_critical_value) AS `hypothetical critical value at 5%`
        , `+ 30 s CI UB`
        , `log(+ 30 s CI UB)`
        , CASE
            WHEN `hypothetical confidence intervals at 30 s`.`hypothetical 95% CI UB` IS NULL
                THEN absolute_ci_inequality_coefficient
            END AS absolute_ci_inequality_coefficient
        , CASE
            WHEN `hypothetical confidence intervals at 30 s`.`hypothetical 95% CI UB` IS NULL
                THEN A_absolute
            END AS A_absolute
        , CASE
            WHEN `hypothetical confidence intervals at 30 s`.`hypothetical 95% CI UB` IS NULL
                THEN B_absolute
            END AS B_absolute
        , CASE
            WHEN `hypothetical confidence intervals at 30 s`.`hypothetical 95% CI UB` IS NULL
                THEN C
            END AS C
        , CASE
            WHEN `hypothetical confidence intervals at 5%`.`hypothetical 95% CI UB` IS NULL
                THEN relative_ci_inequality_coefficient
            END AS relative_ci_inequality_coefficient
        , CASE
            WHEN `hypothetical confidence intervals at 5%`.`hypothetical 95% CI UB` IS NULL
                THEN A_relative
            END AS A_relative
        , CASE
            WHEN `hypothetical confidence intervals at 5%`.`hypothetical 95% CI UB` IS NULL
                THEN B_relative
            END AS B_relative
        , COALESCE(df_to_30_s.completions_needed, CASE
            WHEN chore_duration_confidence_intervals.`one tail 95% CI UB` - chore_duration_confidence_intervals.avg_duration_minutes < 0.5
                THEN 0
            WHEN COALESCE(df_to_30_s.completions_needed, `to 30 s`) < 0
                THEN 1
            ELSE COALESCE(df_to_30_s.completions_needed, `to 30 s`)
            END) AS `to 30 s`
        , COALESCE(`df_to_5%`.completions_needed, CASE
            WHEN chore_duration_confidence_intervals.`one tail 95% CI UB` / chore_duration_confidence_intervals.avg_duration_minutes - 1 < 0.05
                THEN 0
            WHEN COALESCE(`df_to_5%`.completions_needed, `to 5%`) < 0
                THEN 1
            ELSE COALESCE(`df_to_5%`.completions_needed, `to 5%`)
            END) AS `to 5%`
    FROM chore_duration_confidence_intervals
    LEFT JOIN df_to_30_s USING (chore_id)
    LEFT JOIN hypothetical_confidence_intervals AS `hypothetical confidence intervals at 30 s` USING (chore_id, hypothetical_degrees_of_freedom)
    LEFT JOIN `df_to_5%` USING (chore_id)
    LEFT JOIN hypothetical_confidence_intervals AS `hypothetical confidence intervals at 5%`
        ON chore_duration_confidence_intervals.chore_id = `hypothetical confidence intervals at 5%`.chore_id
        AND `df_to_5%`.hypothetical_degrees_of_freedom = `hypothetical confidence intervals at 5%`.hypothetical_degrees_of_freedom
    LEFT JOIN unlimited_df_times_needed
        ON chore_duration_confidence_intervals.chore_id = unlimited_df_times_needed.chore_id;
