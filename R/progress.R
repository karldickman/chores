library(dplyr)
library(plotly)
library(purrr)

source("database.R")
source("log_normal.R")

arrange.by.remaining.then.completed <- function (completed.and.remaining) {
  # Sort in descending order of remaining duration, then by completed
  arrange(completed.and.remaining, completed_minutes - median_duration_minutes * (!is_completed))
}

chores.completed.and.remaining.stack <- function (completed.and.remaining) {
  completed.and.remaining %>%
    subset(is_completed | !is.na(sd_log_duration_minutes)) %>%
    arrange.by.remaining.then.completed() ->
    completed.and.remaining
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
  data.frame(chore = completed.and.remaining$chore, completed, mode.diff, median.diff, mean.diff, q.95.diff)
}

chores.completed.and.remaining.chart <- function (completed.and.remaining, title) {
  plot_ly(completed.and.remaining, x = ~chore, y = ~completed, type = "bar", name = "completed") %>%
    add_trace(y = ~mode.diff, name = "mode") %>%
    add_trace(y = ~median.diff, name = "median") %>%
    add_trace(y = ~mean.diff, name = "mean") %>%
    add_trace(y = ~q.95.diff, name = "95 %ile") %>%
    layout(yaxis = list(title = "Duration (minutes)"), barmode = "stack")
}

cumulative.duration.remaining.sims <- function (completed.and.remaining) {
  completed.and.remaining %>%
    subset(!is.na(sd_log_duration_minutes)) %>%
    pmap(function (chore, mean_log_duration_minutes, sd_log_duration_minutes, ...) {
      list(chore = chore, sims = rvlnorm(mean = mean_log_duration_minutes, sd = sd_log_duration_minutes))
    })
}

cumulative.duration.remaining.summary.values <- function (cumulative.duration.remaining) {
  map_dfr(cumulative.duration.remaining, function (chore.sims) {
    chore <- chore.sims$chore
    sims <- chore.sims$sims
    quantiles <- quantile(sims, c(0.5, 0.95))
    data.frame(chore, median = quantiles[["50%"]], mean = mean(sims), pcile.95 = quantiles[["95%"]])
  })
}

cumulative.sims <- function (chore.sims) {
  cumulative <- list()
  sims <- 0
  for (i in 1:length(chore.sims)) {
    chore <- chore.sims[[i]]$chore
    sims <- sims + chore.sims[[i]]$sims
    cumulative[[i]] <- list(chore = chore, sims = sims)
  }
  return(cumulative)
}

main <- function () {
  setnsims(1000000)
  # Load data
  completed.and.remaining <- using.database(function (fetch.query.results) {
    "SELECT time_remaining_by_chore.*, period_days, category_id
        FROM time_remaining_by_chore
        LEFT JOIN chore_categories USING (chore_id)
        LEFT JOIN chore_periods_days USING (chore_id)
        WHERE due_date BETWEEN DATE(NOW()) AND DATE_ADD(DATE_ADD(DATE(NOW()), INTERVAL 1 DAY), INTERVAL -1 SECOND)" %>%
      fetch.query.results %>%
      subset(period_days < 7 & (is.na(category_id) | category_id != 1))
  })
  # Calculate cumulative summary values
  completed.and.remaining %>%
    arrange.by.remaining.then.completed() %>%
    cumulative.duration.remaining.sims() %>%
    cumulative.sims() %>%
    cumulative.duration.remaining.summary.values() ->
    cumulative.summary.values
  completed.and.remaining %>%
    chores.completed.and.remaining.stack() %>%
    chores.completed.and.remaining.chart("Chore progress today")
}

if (interactive()) {
  main()
}
