library(data.table)
library(dplyr)

source("analysis.R")
source("database.R")

chore.breakdown.chart <- function (fitted.chore.durations, title) {
  durations <- fitted.chore.durations %>%
    expand.many.chore.completions.per.day %>%
    scale.less.than.one.chore.completion.per.day %>%
    arrange(-median_duration_minutes) # Sort in descending order of median duration
  # Calculate key values
  mode <- durations$mode_duration_minutes
  median <- durations$median_duration_minutes - durations$mode_duration_minutes
  mean <- durations$mean_duration_minutes - durations$median_duration_minutes
  q.95 <- qlnorm(0.95, durations$mean_log_duration_minutes, durations$sd_log_duration_minutes) -
    durations$mean_duration_minutes
  # Transpose data frame for presentation in stacked bar chart
  summary.values<- data.frame(mode, median, mean, q.95) %>% transpose
  colnames(summary.values) <- durations$chore
  rownames(summary.values) <- c("mode", "median", "mean", "95%ile")
  # Create stacked bar chart
  summary.values %>% as.matrix %>%
    barplot(main = title, ylab = "Duration (minutes)", las = 2)
}

main <- function () {
  using.database(function (fetch.query.results) {
    "SELECT chore_id
          , chore
          , completions_per_day
          , mean_log_duration_minutes
          , sd_log_duration_minutes
          , mode_duration_minutes
          , median_duration_minutes
          , mean_duration_minutes
          , daily
          , weekendity
          , category_id
          , chore_id IN (SELECT chore_id FROM chore_hierarchy) AS child_chore
        FROM chore_durations_per_day
        LEFT JOIN chore_categories USING (chore_id)
        WHERE is_active" %>%
      fetch.query.results %>%
      subset(daily == 1 & weekendity == 0 & child_chore == 0 & (is.na(category_id) | category_id != 1)) %>%
      chore.breakdown.chart("Weekday chore breakdown")
  })
}

if (interactive()) {
  main()
}
