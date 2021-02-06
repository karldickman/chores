library(dplyr)
library(plotly)
library(purrr)

source("avg_chore_duration.R")
source("database.R")
source("log_normal.R")

# Suppress summarise info
options(dplyr.summarise.inform = FALSE)

arrange.by.remaining.then.completed <- function (data) {
  if (any(is.na(data$order_hint))) {
    # Sort in descending order of remaining duration, then by completed
    chore.order <- with(data, ifelse(
      is.completed,
      completed,
      ifelse(
        remaining.median > 0,
        -remaining.median,
        0))) %>%
      order()
  }
  else {
    chore.order <- order(data$order_hint)
  }
  data %>%
    mutate(chore = factor(chore, levels = unique(chore)[chore.order])) %>%
    arrange(chore)
}

calculate.q.95 <- function (data) {
  # Add 0.95 quantile -- data from database is difference between quantile and completed, not the actual quantile
  mutate(data, q.95 = qlnorm(0.95, mean_log_duration_minutes, sd_log_duration_minutes))
}

calculate.remaining <- function (data) {
  remaining <- function (is.completed, total.count, completed, summary.metric) {
    ifelse(
      is.completed,
      0,
      ifelse(
        total.count == 1,
        summary.metric - completed,
        summary.metric))
  }
  summarize.sims <- function (is.completed, incomplete.count, summary.metric, sims, summarize) {
    ifelse(
      !is.completed & incomplete.count > 1,
      map(sims, summarize) %>%
        unlist(),
      summary.metric)
  }
  # Recalculate summary metrics for all chores with more than one incompletion
  data %>%
    mutate(
      mode_duration_minutes = summarize.sims(is.completed, incomplete.count, mode_duration_minutes, remaining.sims, mode.sims),
      median_duration_minutes = summarize.sims(is.completed, incomplete.count, median_duration_minutes, remaining.sims, median),
      mean_duration_minutes = summarize.sims(is.completed, incomplete.count, mean_duration_minutes, remaining.sims, mean),
      q.95 = summarize.sims(is.completed, incomplete.count, q.95, remaining.sims, q.95.sims)) %>%
    rename(mode = mode_duration_minutes, median = median_duration_minutes, mean = mean_duration_minutes) %>%
    # Calculate remaining duration according to each summary metric
    mutate(
      remaining.mode = remaining(is.completed, total.count, completed, mode),
      remaining.median = remaining(is.completed, total.count, completed, median),
      remaining.mean = remaining(is.completed, total.count, completed, mean),
      remaining.q.95 = remaining(is.completed, total.count, completed, q.95))
}

chores.completed.and.remaining.chart <- function (data) {
  data %>%
    plot_ly(x = ~chore) %>%
    add_bars(y = ~mode.diff, name = "mode", marker = list(color = "rgb(51.2, 51.2, 51.2)")) %>%
    add_bars(y = ~median.diff, name = "median", marker = list(color = "rgb(102.4, 102.4, 102.4)")) %>%
    add_bars(y = ~mean.diff, name = "mean", marker = list(color = "rgb(153.6, 153.6, 153.6)")) %>%
    add_bars(y = ~q.95.diff, name = "95 %ile", marker = list(color = "rgb(204.8, 204.8, 204.8)")) %>%
    add_bars(y = ~completed, name = "completed", marker = list(color = "rgb(0, 0, 0)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.mode / 60, name = "mode", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.median / 60, name = "median", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.mean / 60, name = "mean", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.q.95 / 60, name = "95 %ile", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.completed / 60, name = "completed", line = list(color = "rgb(128, 128, 128)")) %>%
    layout(
      barmode = "stack",
      yaxis = list(title = "Duration (minutes)"),
      yaxis2 = list(
        overlaying = "y",
        side = "right",
        title = "Cumulative duration (hours)",
        rangemode = "tozero",
        showgrid = FALSE),
      legend = list(
        orientation = "h",
        traceorder = "normal",
        y = -0.3
      )
    )
}

chores.completed.and.remaining.stack <- function (data) {
  # Truncated difference, 0 if subtrahend greater than minuend
  diff <- function (minuend, subtrahend) {
    ifelse(
      !is.na(minuend),
      ifelse(
        minuend > subtrahend,
        minuend - subtrahend,
        0),
      0)
  }
  mode.diff <- diff(data$remaining.mode, 0)
  median.diff <- diff(data$remaining.median, mode.diff)
  mean.diff <- diff(data$remaining.mean, mode.diff + median.diff)
  q.95.diff <- diff(data$remaining.q.95, mode.diff + median.diff + mean.diff)
  data %>%
    mutate(
      mode.diff,
      median.diff,
      mean.diff,
      q.95.diff)
}

cumulative.sims <- function (data) {
  cumulative.sims <- 0
  completed <- 0
  cumulative.mode <- c()
  cumulative.median <- c()
  cumulative.mean <- c()
  cumulative.q.95 <- c()
  cumulative.completed <- c()
  for (i in 1:nrow(data)) {
    # Remaining
    sims <- c(data$remaining.sims[[i]])
    cumulative.sims <- cumulative.sims + ifelse(sims >= 0, sims, 0)
    cumulative.mode <- c(cumulative.mode, mode.sims(cumulative.sims))
    cumulative.median <- c(cumulative.median, median(cumulative.sims))
    cumulative.mean <- c(cumulative.mean, mean(cumulative.sims))
    cumulative.q.95 <- c(cumulative.q.95, q.95.sims(cumulative.sims))
    # Completed
    completed <- completed + data$completed[[i]]
    cumulative.completed <- c(cumulative.completed, completed)
  }
  data.frame(
    chore = data$chore,
    cumulative.mode,
    cumulative.median,
    cumulative.mean,
    cumulative.q.95,
    cumulative.completed)
}

fallback.on.avg.chore.duration <- function (data, avg.chore.duration) {
  # If chore has been completed 1 or fewer times, fall back on average chore duration
  data %>%
    merge(avg.chore.duration, by = c(), suffixes = c("", ".y")) %>%
    mutate(
      mean_log_duration_minutes = ifelse(
        times_completed == 0,
        mean_log_duration_minutes.y,
        ifelse(
          times_completed == 1,
          log(arithmetic_mean_duration_minutes),
          mean_log_duration_minutes)),
      sd_log_duration_minutes = ifelse(
        times_completed <= 1,
        sd_log_duration_minutes.y,
        sd_log_duration_minutes)) %>%
    select(!c(mean_log_duration_minutes.y, sd_log_duration_minutes.y)) %>%
    mutate(
      mode_duration_minutes = ifelse(
        times_completed <= 1,
        log.normal.mode(mean_log_duration_minutes, sd_log_duration_minutes),
        mode_duration_minutes),
      median_duration_minutes = ifelse(
        times_completed <= 1,
        log.normal.median(mean_log_duration_minutes, sd_log_duration_minutes),
        median_duration_minutes),
      mean_duration_minutes = ifelse(
        times_completed <= 1,
        log.normal.mean(mean_log_duration_minutes, sd_log_duration_minutes),
        mean_duration_minutes))
}

group.by.chore <- function (data) {
  # Group by chore to sum up completed and remaining minutes
  completed.and.remaining <- data %>%
    group_by(chore) %>%
    summarise(
      is.completed = all(is_completed),
      total.count = n(),
      incomplete.count = sum(!is_completed),
      completed = sum(completed_minutes),
      remaining.sims = sum.remaining.sims(remaining.sims))
  # Get summary metrics for all chores
  data %>%
    select(chore, order_hint, mode_duration_minutes, median_duration_minutes, mean_duration_minutes, q.95) %>%
    unique() %>%
    merge(completed.and.remaining)
}

mode.sims <- function (sims) {
  if (length(sims) == 1) return(sims[[1]])
  # Negative remaining duration is really 0
  one.hundredth.of.a.second <- 0.01 / 60
  sims <- ifelse(sims >= one.hundredth.of.a.second, sims, one.hundredth.of.a.second)
  # Assume log normal distribution to estimate mode
  log.normal.mode(mean(log(sims)), sd(log(sims)))
}

q.95.sims <- function (sims) {
  quantile(sims, 0.95)[["95%"]]
}

query.time_remaining_by_chore <- function (fetch.query.results) {
  "SELECT chores.chore, time_remaining_by_chore.*, order_hint, period_days, category_id, frequency_category
      FROM time_remaining_by_chore
      JOIN chores USING (chore_id)
      LEFT JOIN chore_order USING (chore_id)
      LEFT JOIN chore_categories USING (chore_id)
      LEFT JOIN chore_periods_days USING (chore_id)
      LEFT JOIN frequency_category_ranges
          ON period_days > minimum_period_days AND period_days < maximum_period_days
          OR period_days = minimum_period_days AND minimum_period_inclusive
          OR period_days = maximum_period_days AND maximum_period_inclusive
      WHERE is_completed
              AND when_completed BETWEEN DATE(NOW()) AND DATE_ADD(DATE(NOW()), INTERVAL 1 DAY)
          OR NOT is_completed
              AND due_date < NOW()" %>%
    fetch.query.results()
}

rv.remaining <- function (is_completed, completed_minutes, mean_log_duration_minutes, sd_log_duration_minutes, ...) {
  if (is_completed) return(0)
  # Use RV to simulate distribution of remaining chore duration
  rvlnorm(mean = mean_log_duration_minutes, sd = sd_log_duration_minutes) - completed_minutes
}

simulate.remaining <- function (data) {
  mutate(data, remaining.sims = pmap(data, rv.remaining))
}

sum.remaining.sims <- function (remaining.sims) {
  remaining.sims %>%
    map(function (remaining.sims) {
      ifelse(remaining.sims >= 0, remaining.sims, 0) # Truncate remaining to 0, negative remaining is nonsensical
    }) %>%
    reduce(function (total, remaining.sims) {
      total + remaining.sims
    }) %>%
    list()
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
  # Clean up certain columns from the database
  completed.and.remaining <- completed.and.remaining %>%
    mutate(
      # Convert is_completed column from 0/1 Boolean to true Boolean
      is_completed = completed.and.remaining$is_completed == 1,
      frequency_category = ifelse(
        # Convert category_id = 1 (meals) to frequency category meals
        !is.na(category_id) & category_id == 1,
        "meals",
        ifelse(
          # Convert category_id = 2 (physical therapy) to daily
          !is.na(category_id) & category_id == 2,
          "daily",
          frequency_category)))
  # Fit average chore duration (fallback when chore has been completed 1 or fewer times)
  avg.chore.duration <- avg.chore.duration$duration_minutes %>%
    fitted.avg.chore.duration() # Fit log-normal distribution to observed durations
  # Calculate total remaining duration by chore
  completed.and.remaining <- completed.and.remaining %>%
    subset(frequency_category %in% charts) %>%
    fallback.on.avg.chore.duration(avg.chore.duration) %>%
    simulate.remaining() %>%
    calculate.q.95() %>%
    group.by.chore() %>%
    calculate.remaining() %>%
    arrange.by.remaining.then.completed()
  # Calculate cumulative summary values
  cumulative.completed.and.remaining <- cumulative.sims(completed.and.remaining)
  # Generate chart
  completed.and.remaining %>%
    merge(cumulative.completed.and.remaining) %>%
    chores.completed.and.remaining.stack() %>%
    chores.completed.and.remaining.chart()
}
