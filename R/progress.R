library(dplyr)
library(plotly)
library(purrr)

source("avg_chore_duration.R")
source("database.R")
source("log_normal.R")
source("rv_chore.R")

# Suppress summarise info
options(dplyr.summarise.inform = FALSE)

arrange.by.remaining.then.completed <- function (data) {
  data <- cbind(data)
  # Sort in descending order of remaining duration, then by completed
  chore.order <- ifelse(
    data$is_completed,
    data$completed,
    ifelse(
      data$remaining.median > 0,
      -data$remaining.median,
      0)) %>%
    order()
  data$chore <- factor(data$chore, levels = unique(data$chore)[chore.order])
  arrange(data, chore)
}

calculate.q.95 <- function (data) {
  data <- cbind(data)
  # Add 0.95 quantile -- data from database is difference between quantile and completed, not the actual quantile
  data$q.95 <- qlnorm(0.95, data$mean_log_duration_minutes, data$sd_log_duration_minutes)
  return(data)
}

chores.completed.and.remaining.chart <- function (data) {
  data %>%
    plot_ly(x = ~chore) %>%
    add_bars(y = ~mode.diff, name = "mode", marker = list(color = "rgb(51.2, 51.2, 51.2)")) %>%
    add_bars(y = ~median.diff, name = "median", marker = list(color = "rgb(102.4, 102.4, 102.4)")) %>%
    add_bars(y = ~mean.diff, name = "mean", marker = list(color = "rgb(153.6, 153.6, 153.6)")) %>%
    add_bars(y = ~q.95.diff, name = "95 %ile", marker = list(color = "rgb(204.8, 204.8, 204.8)")) %>%
    add_bars(y = ~completed, name = "completed", marker = list(color = "rgb(0, 0, 0)")) %>%
    layout(
      barmode = "stack",
      yaxis = list(title = "Duration (minutes)"),
      legend = list(
        orientation = "h",
        traceorder = "normal",
        y = -0.3
      )
    )
}

chores.completed.and.remaining.stack <- function (data) {
  # Calculate key values
  diff <- function (minuend, subtrahend) {
    ifelse(
      !is.na(minuend),
      ifelse(
        minuend > subtrahend,
        minuend - subtrahend,
        0),
      0)
  }
  completed <- data$completed
  mode.diff <- diff(data$remaining.mode, 0)
  median.diff <- diff(data$remaining.median, mode.diff)
  mean.diff <- diff(data$remaining.mean, mode.diff + median.diff)
  q.95.diff <- diff(data$remaining.q.95, mode.diff + median.diff + mean.diff)
  data.frame(
    chore = data$chore,
    completed,
    mode.diff,
    median.diff,
    mean.diff,
    q.95.diff)
}

cumulative.duration.remaining.sims <- function (completed.and.remaining) {
  completed.and.remaining %>%
    subset(!is.na(sd_log_duration_minutes)) %>%
    pmap(rv.chore)
}

cumulative.duration.remaining.summary.values <- function (cumulative.duration.remaining) {
  map_dfr(cumulative.duration.remaining, summarize.rv)
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

fallback.on.avg.chore.duration <- function (data, avg.chore.duration) {
  # If chore has been completed 1 or fewer times, fall back on average chore duration
  data <- cbind(data) %>%
    merge(avg.chore.duration, by = c(), suffixes = c("", ".y"))
  data$mean_log_duration_minutes <- ifelse(
    data$times_completed == 0,
    data$mean_log_duration_minutes.y,
    ifelse(
      data$times_completed == 1,
      log(data$arithmetic_mean_duration_minutes),
      data$mean_log_duration_minutes))
  data$sd_log_duration_minutes <- ifelse(
    data$times_completed <= 1,
    data$sd_log_duration_minutes.y,
    data$sd_log_duration_minutes)
  data$mean_log_duration_minutes.y <- NULL
  data$sd_log_duration_minutes.y <- NULL
  data$mode_duration_minutes <- ifelse(
    data$times_completed <= 1,
    log.normal.mode(data$mean_log_duration_minutes, data$sd_log_duration_minutes),
    data$mode_duration_minutes)
  data$median_duration_minutes <- ifelse(
    data$times_completed <= 1,
    log.normal.median(data$mean_log_duration_minutes, data$sd_log_duration_minutes),
    data$median_duration_minutes)
  data$mean_duration_minutes <- ifelse(
    data$times_completed <= 1,
    log.normal.mean(data$mean_log_duration_minutes, data$sd_log_duration_minutes),
    data$mean_duration_minutes)
  return(data)
}

group.by.chore <- function (data, avg.chore.duration) {
  # Split up completed and not completed
  complete <- subset(data, is_completed)
  incomplete <- subset(data, !is_completed)
  # Count occurrences of each chore, summarize completed minutes
  incomplete.summarized <- incomplete %>%
    group_by(chore) %>%
    summarise(
      count = n(),
      total_completed_minutes = sum(completed_minutes))
  incomplete <- merge(incomplete, incomplete.summarized)
  # Separate out chores with one repetition, drop irrelevant columns
  one <- subset(incomplete, count == 1)
  one <- one[c("chore", "is_completed", "completed_minutes", "mode_duration_minutes", "median_duration_minutes", "mean_duration_minutes", "q.95")]
  colnames(one) <- c("chore", "is_completed", "completed", "mode", "median", "mean", "q.95")
  # Separate out chores with multiple repetitions, simulate using rv
  many <- subset(incomplete, count > 1)
  if (nrow(many) > 0) {
    # Use RV to simulate distribution of remaining chore duration
    many <- many[c("chore", "count", "mean_log_duration_minutes", "sd_log_duration_minutes")] %>%
      unique() %>%
      pmap(rv.chore) %>%
      map_dfr(summarize.rv) %>%
      merge(incomplete.summarized[c("chore", "total_completed_minutes")]) %>%
      merge(data.frame(is_completed = FALSE))
    many <- many[c("chore", "is_completed", "total_completed_minutes", "mode", "median", "mean", "q.95")]
    colnames(many) <- colnames(one)
    # Recombine one and many
    incomplete <- rbind(one, many)
  }
  else {
    incomplete <- one
  }
  # Convert summary metrics to remaining duration
  incomplete$remaining.mode <- ifelse(!is.na(incomplete$mode), incomplete$mode - incomplete$completed, 0)
  incomplete$remaining.median <- incomplete$median - incomplete$completed
  incomplete$remaining.mean <- incomplete$mean - incomplete$completed
  incomplete$remaining.q.95 <- incomplete$q.95 - incomplete$completed
  # Summarize complete
  complete <- complete %>%
    group_by(chore) %>%
    summarise(
      is_completed = TRUE,
      completed = sum(completed_minutes),
      remaining.mode = 0,
      remaining.median = 0,
      remaining.mean = 0,
      remaining.q.95 = 0)
  # Summarize incomplete
  incomplete <- incomplete %>%
    group_by(chore) %>%
    summarise(
      is_completed = FALSE,
      completed = sum(completed),
      remaining.mode = sum(remaining.mode),
      remaining.median = sum(remaining.median),
      remaining.mean = sum(remaining.mean),
      remaining.q.95 = sum(remaining.q.95))
  # Recombine complete and incomplete, summarize, and return
  summary.metrics.by.chore <- data[c("chore", "mode_duration_minutes", "median_duration_minutes", "mean_duration_minutes", "q.95")] %>%
    unique()
  colnames(summary.metrics.by.chore) <- c("chore", "mode", "median", "mean", "q.95")
  rbind(complete, incomplete) %>%
    group_by(chore) %>%
    summarise(
      is_completed = all(is_completed),
      completed = sum(completed),
      remaining.mode = sum(remaining.mode),
      remaining.median = sum(remaining.median),
      remaining.mean = sum(remaining.mean),
      remaining.q.95 = sum(remaining.q.95)) %>%
    merge(summary.metrics.by.chore)
}

query.time_remaining_by_chore <- function (fetch.query.results) {
  "SELECT chores.chore, time_remaining_by_chore.*, period_days, category_id, frequency_category
      FROM time_remaining_by_chore
      JOIN chores USING (chore_id)
      LEFT JOIN chore_categories USING (chore_id)
      LEFT JOIN chore_periods_days USING (chore_id)
      LEFT JOIN frequency_category_ranges
          ON period_days > minimum_period_days AND period_days < maximum_period_days
          OR period_days = minimum_period_days AND minimum_period_inclusive
          OR period_days = maximum_period_days AND maximum_period_inclusive
      WHERE is_completed
              AND when_completed BETWEEN DATE(NOW()) AND DATE_ADD(DATE(NOW()), INTERVAL 1 DAY)
          OR NOT is_completed
              AND due_date < DATE_ADD(DATE(NOW()), INTERVAL 1 DAY)" %>%
    fetch.query.results()
}

summarize.rv <- function (chore.sims) {
  chore <- chore.sims$chore
  sims <- chore.sims$sims
  quantiles <- quantile(sims, c(0.5, 0.95))
  data.frame(
    chore,
    mode = log.normal.mode(mean(log(sims)), sd(log(sims))), # Assume log normal distribution to estimate mode
    median = quantiles[["50%"]],
    mean = mean(sims),
    q.95 = quantiles[["95%"]])
}

main <- function (charts = "daily") {
  # Load data
  database.results <- using.database(function (fetch.query.results) {
    completed.and.remaining <- query.time_remaining_by_chore(fetch.query.results)
    chore.durations <- query.chore_durations(fetch.query.results)
    list(completed.and.remaining, chore.durations)
  })
  completed.and.remaining <- database.results[[1]]
  avg.chore.duration <- database.results[[2]]
  # Convert is_completed column from 0/1 Boolean to true Boolean
  completed.and.remaining$is_completed <- completed.and.remaining$is_completed == 1
  # Convert category_id = 1 (meals) to frequency category meals
  completed.and.remaining$frequency_category <- ifelse(
    is.na(completed.and.remaining$category_id) | completed.and.remaining$category_id != 1,
    completed.and.remaining$frequency_category,
    "meals")
  # Fit average chore duration (fallback when chore has been completed 1 or fewer times)
  avg.chore.duration <- avg.chore.duration$duration_minutes %>%
    fitted.avg.chore.duration() # Fit log-normal distribution to observed durations
  # Calculate cumulative summary values
  completed.and.remaining %>%
    subset(frequency_category %in% charts) %>%
    fallback.on.avg.chore.duration(avg.chore.duration) %>%
    calculate.q.95() %>%
    group.by.chore() %>%
    arrange.by.remaining.then.completed() %>%
    chores.completed.and.remaining.stack() %>%
    chores.completed.and.remaining.chart()
  # Calculate cumulative summary values
  completed.and.remaining %>%
    arrange.by.remaining.then.completed() %>%
    cumulative.duration.remaining.sims() %>%
    cumulative.sims() %>%
    cumulative.duration.remaining.summary.values()
}
