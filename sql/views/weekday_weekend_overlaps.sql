CREATE OR REPLACE VIEW weekday_weekend_overlaps
AS
WITH confidence_intervals AS (SELECT chore_id
        , aggregate_key
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , degrees_of_freedom
        , two_tail_critical_value AS critical_value
        , `two tail 95% CI LB` AS `95% CI LB`
        , `two tail 95% CI UB` AS `95% CI UB`
        , `two tail 95% CI UB` - `two tail 95% CI LB` AS `95% CI absolute`
        , (`two tail 95% CI UB` - `two tail 95% CI LB`) / mean_duration_minutes AS `95% CI relative`
    FROM chore_duration_confidence_intervals
    WHERE aggregate_by_id = 2),
`weekday` AS (SELECT chore_id
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , degrees_of_freedom
        , critical_value
        , `95% CI LB`
        , `95% CI UB`
        , `95% CI absolute`
        , `95% CI relative`
    FROM confidence_intervals
    WHERE aggregate_key = 0),
weekend AS (SELECT  chore_id
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , degrees_of_freedom
        , critical_value
        , `95% CI LB`
        , `95% CI UB`
        , `95% CI absolute`
        , `95% CI relative`
    FROM confidence_intervals
    WHERE aggregate_key = 1)
SELECT `weekday`.chore_id
        , chore
        , `weekday`.mean_log_duration_minutes AS weekday_mean_log_duration_minutes
        , `weekday`.sd_log_duration_minutes AS weekday_sd_log_duration_minutes
        , weekend.mean_log_duration_minutes AS weekend_mean_log_duration_minutes
        , weekend.sd_log_duration_minutes AS weekend_sd_log_duration_minutes
        , `weekday`.degrees_of_freedom AS weekday_degrees_of_freedom
        , `weekday`.critical_value AS weekday_critical_value
        , weekend.degrees_of_freedom AS weekend_degrees_of_freedom
        , weekend.critical_value AS weekend_critical_value
        , `weekday`.`95% CI LB` AS `weekday 95% CI LB`
        , `weekday`.`95% CI UB` AS `weekday 95% CI UB`
        , `weekday`.`95% CI absolute` AS `weekday 95% CI absolute`
        , `weekday`.`95% CI relative` AS `weekday 95% CI relative`
        , weekend.`95% CI LB` AS `weekend 95% CI LB`
        , weekend.`95% CI UB` AS `weekend 95% CI UB`
        , weekend.`95% CI absolute` AS `weekend 95% CI absolute`
        , weekend.`95% CI relative` AS `weekend 95% CI relative`
        , `weekday`.`95% CI UB` >= weekend.`95% CI LB` OR `weekday`.`95% CI LB` >= weekend.`95% CI UB` AS `overlaps`
    FROM `weekday`
    JOIN chores USING (chore_id)
    JOIN weekend USING (chore_id);
