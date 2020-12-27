library(data.table)
library(dplyr)

source("database.R")

arrange.by.remaining.then.completed <- function (completed.and.remaining) {
  # Sort in descending order of remaining duration, then by completed
  arrange(completed.and.remaining, completed_minutes - median_duration_minutes * (!is_completed))
}

chores.completed.and.remaining.chart <- function (completed.and.remaining, title) {
  completed.and.remaining <- completed.and.remaining %>%
    subset(is_completed | !is.na(sd_log_duration_minutes)) %>%
    arrange.by.remaining.then.completed()
  # Calculate key values
  diff <- function (completed, minuend, subtrahend) {
    ifelse(
      completed == 0,
      ifelse(
        minuend > subtrahend,
        minuend - subtrahend,
        0),
      NA)
  }
  completed <- completed.and.remaining$completed_minutes
  mode.diff <- diff(completed.and.remaining$is_completed, completed.and.remaining$mode_duration_minutes, completed)
  median.diff <- diff(completed.and.remaining$is_completed, completed.and.remaining$median_duration_minutes, completed + mode.diff)
  mean.diff <- diff(completed.and.remaining$is_completed, completed.and.remaining$mean_duration_minutes, completed + mode.diff + median.diff)
  q.95 <- qlnorm(0.95, completed.and.remaining$mean_log_duration_minutes, completed.and.remaining$sd_log_duration_minutes)
  q.95.diff <- diff(completed.and.remaining$is_completed, q.95, completed + mode.diff + median.diff + mean.diff)
  # Transpose data frame for presentation in stacked bar chart
  summary.values <- data.frame(completed, mode.diff, median.diff, mean.diff, q.95.diff) %>% transpose
  colnames(summary.values) <- completed.and.remaining$chore
  rownames(summary.values) <- c("completed", "mode", "median", "mean", "95%ile")
  # Create stacked bar chart
  summary.values %>% as.matrix %>%
    barplot(main = title, ylab = "Duration (minutes)", las = 2)
}

main <- function () {
  using.database(function (fetch.query.results) {
    "SELECT time_remaining_by_chore.*, period_days, category_id
        FROM time_remaining_by_chore
        LEFT JOIN chore_categories USING (chore_id)
        LEFT JOIN chore_periods_days USING (chore_id)
        WHERE due_date BETWEEN DATE(NOW()) AND DATE_ADD(DATE_ADD(DATE(NOW()), INTERVAL 1 DAY), INTERVAL -1 SECOND)" %>%
      fetch.query.results %>%
      subset(period_days < 7 & (is.na(category_id) | category_id != 1)) %>%
      chores.completed.and.remaining.chart("Chore progress today")
  })
}

if (interactive()) {
  main()
}
