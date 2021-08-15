library(dplyr)
options(dplyr.summarise.inform = FALSE) # Suppress summarise info
library(plotly)
library(purrr)

source("avg_chore_duration.R")
source("database.R")
source("log_normal.R")

#' Convert string-valued chore column into a factor ordered first by remaining minutes, then by completed minutes.
#' @param data A tibble containing summary data for chore durations.
#'             Must have is.completed (boolean), completed (number), and remaining.mean (number) columns
#'             describing completed and remaining minutes and string chore column with chore name.
arrange.by.remaining.then.completed <- function (data) {
  if (any(is.na(data$order_hint))) {
    # Sort in descending order of remaining duration, then by completed
    chore.order <- with(data, ifelse(
      is.completed,
      completed,
      ifelse(
        remaining.mean > 0,
        -remaining.mean,
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

#' Add 95th percentile column to a tibble
#' @param data A tibble containing summary data for chore durations.
#'             Must have mean_log_duration_minutes and sd_log_duration_minutes columns describing the log-normal fit.
calculate.q.95 <- function (data) {
  # Add 0.95 quantile -- data from database is difference between quantile and completed, not the actual quantile
  mutate(data, q.95 = qlnorm(0.95, mean_log_duration_minutes, sd_log_duration_minutes))
}

#' Generate chart of completed and remaining chores.
#' @param data A tibble containing the data needed to generate the chart.
#'             Must have columns chore, {mode, median, mean, q.95}.diff, completed,
#'             and cumulative.{mode, median, mean, q.95, completed}
chores.completed.and.remaining.chart <- function (data) {
  data <- data %>% mutate(
    cumulative.mode = cumulative.mode / 60,
    cumulative.median = cumulative.median / 60,
    cumulative.mean = cumulative.mean / 60,
    cumulative.q.95 = cumulative.q.95 / 60,
    cumulative.completed = -cumulative.completed / 60)
  min.duration <- -max(data$completed)
  max.duration <- max(data$mode.diff + data$median.diff + data$mean.diff + data$q.95.diff)
  min.cumulative <- min(data$cumulative.completed)
  max.cumulative <- max(data$cumulative.q.95)
  range.length.duration <- max.duration - min.duration
  range.length.cumulative <- max.cumulative - min.cumulative
  range.length <- max(range.length.duration, range.length.cumulative)
  coeff.duration <- range.length / range.length.duration
  coeff.cumulative <- range.length / range.length.cumulative
  extrema <- c(c(min.duration, max.duration) * coeff.duration, c(min.cumulative, max.cumulative) * coeff.cumulative)
  common.range <- c(min(extrema), max(extrema)) * 1.01
  range.duration <- common.range / coeff.duration
  range.cumulative <- common.range / coeff.cumulative
  data %>%
    plot_ly(x = ~chore) %>%
    add_bars(y = ~-completed, name = "completed", marker = list(color = "rgb(0, 0, 0)"), showlegend = FALSE) %>%
    add_bars(y = ~completed, name = "completed", marker = list(color = "rgb(0, 0, 0)")) %>%
    add_bars(y = ~mode.diff, name = "mode", marker = list(color = "rgb(51.2, 51.2, 51.2)")) %>%
    add_bars(y = ~median.diff, name = "median", marker = list(color = "rgb(102.4, 102.4, 102.4)")) %>%
    add_bars(y = ~mean.diff, name = "mean", marker = list(color = "rgb(153.6, 153.6, 153.6)")) %>%
    add_bars(y = ~q.95.diff, name = "95 %ile", marker = list(color = "rgb(204.8, 204.8, 204.8)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.completed, name = "completed", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.mode, name = "mode", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.median, name = "median", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.mean, name = "mean", line = list(color = "rgb(128, 128, 128)")) %>%
    add_lines(yaxis = "y2", y = ~cumulative.q.95, name = "95 %ile", line = list(color = "rgb(128, 128, 128)")) %>%
    layout(
      barmode = "stack",
      yaxis = list(
        title = "Remaining duration (minutes)",
        autorange = FALSE,
        range = range.duration),
      yaxis2 = list(
        overlaying = "y",
        side = "right",
        title = "Cumulative duration (hours)",
        automargin = TRUE,
        autorange = FALSE,
        range = range.cumulative,
        showgrid = FALSE),
      legend = list(
        orientation = "h",
        traceorder = "normal",
        y = -0.3
      )
    )
}

#' Generate numerical data for a stacked chart.
#' Mode is represented unchanged.
#' Median is represented as difference between median and mode.
#' Mean is represented as difference between mean and median.
#' 95th percentile is represented as difference with mean.
#' @param data A tibble containing data to convert to a stacked format.
#'             Must have columns remaining.{mode, median, mean, q.95}.
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

#' Generate mode, median, mean, and 0.95th quantile summary values
#' for cumulative duration of each chore.
#' @param data A Tibble containing chore duration data from which to generate cumulative values.
cumulative.sims <- function (data) {
  if (nrow(data) == 0) {
    return(data.frame(
      chore = data$chore,
      cumulative.mode = double(),
      cumulative.median = double(),
      cumulative.mean = double(),
      cumulative.q.95 = double(),
      cumulative.completed = double()))
  }
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
    cumulative.mode <- c(cumulative.mode, fit.mode.to.data(cumulative.sims))
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

#' If chore has been completed 1 or fewer times, use average duration of all chores as fallback value.
#' @param data A Tibble containing chore progress data from database.
#' @param avg.chore.duration The average length of all chores ever completed.
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

#' Estimate the mode of some data by fitting a log-normal distribution to it.
#' @param data A vector of numbers whose mode to estimate.
fit.mode.to.data <- function (data) {
  if (length(data) == 1) return(data[[1]])
  # Negative remaining duration is really 0
  one.hundredth.of.a.second <- 0.01 / 60
  data <- ifelse(data >= one.hundredth.of.a.second, data, one.hundredth.of.a.second)
  # Assume log normal distribution to estimate mode
  log.normal.mode(mean(log(data)), sd(log(data)))
}

#' Get the 0.95th quantile.
#' @param data A vector of data whose 0.95th quantile to get.
q.95.sims <- function (data) {
  quantile(data, 0.95)[["95%"]]
}

#' Query the database for the data needed to generate the progress charts.
#' @param fetch.query.results Function that executes an SQL query and returns the results.
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

#' Summarize remaining duration in minutes for each chore using standard summary metrics.
#' @param data A tibble containing completed minutes and average duration for each chore.
remaining.simulations.to.summary.metrics <- function (data) {
  remaining <- function (is.completed, total.count, completed, summary.metric) {
    ifelse(
      is.completed,
      0,
      ifelse(
        total.count == 1,
        summary.metric - completed,
        summary.metric))
  }
  single.or.na <- function (values) {
    ifelse(length(values == 1), values, NA)
  }
  summarize.sims.or.use.specified.value <- function (is.completed, incomplete.count, summary.metric, sims, summarize) {
    ifelse(
      is.completed | incomplete.count <= 1,
      summary.metric,
      map(sims, summarize) %>%
        unlist())
  }
  # Recalculate summary metrics for all chores with more than one incompletion
  data %>%
    group_by(chore) %>%
    summarise(
      order_hint = min(order_hint), # Only one order hint per chore, take min to get single value
      is.completed = all(is.completed),
      total.count = sum(total.count),
      incomplete.count = sum(incomplete.count),
      completed = sum(completed),
      mode_duration_minutes = single.or.na(mode_duration_minutes),
      median_duration_minutes = single.or.na(median_duration_minutes),
      mean_duration_minutes = single.or.na(mean_duration_minutes),
      q.95 = single.or.na(q.95),
      remaining.sims = sum.remaining.sims(remaining.sims)) %>%
    mutate(
      mode = summarize.sims.or.use.specified.value(is.completed, incomplete.count, mode_duration_minutes, remaining.sims, fit.mode.to.data),
      median = summarize.sims.or.use.specified.value(is.completed, incomplete.count, median_duration_minutes, remaining.sims, median),
      mean = summarize.sims.or.use.specified.value(is.completed, incomplete.count, mean_duration_minutes, remaining.sims, mean),
      q.95 = summarize.sims.or.use.specified.value(is.completed, incomplete.count, q.95, remaining.sims, q.95.sims)) %>%
    # Calculate remaining duration according to each summary metric
    mutate(
      remaining.mode = remaining(is.completed, total.count, completed, mode),
      remaining.median = remaining(is.completed, total.count, completed, median),
      remaining.mean = remaining(is.completed, total.count, completed, mean),
      remaining.q.95 = remaining(is.completed, total.count, completed, q.95))
}

#' Use rv to simulate distribution of remaining chore duration.
#' @param is_completed Is the chore completed?
#' @param completed_minutes The number of minutes of the chore completed.
#' @param mean_log_duration_minutes The mean of log chore duration (minutes).
#' @param sd_log_duration_minutes The standard deviation of the log chore duration (minutes).
#' @param ... Needed so this function can be passed to pmap.
rv.remaining <- function (is_completed, completed_minutes, mean_log_duration_minutes, sd_log_duration_minutes, ...) {
  if (is_completed) return(0)
  # Use RV to simulate distribution of remaining chore duration
  rvlnorm(mean = mean_log_duration_minutes, sd = sd_log_duration_minutes) - completed_minutes
}

#' Use rv to simulate distribution of remaining chore durations.
#' @param data A Tibble containing data on the completed minutes and log normal fit.
simulate.remaining <- function (data) {
  mutate(data, remaining.sims = pmap(data, rv.remaining))
}

#' Sum simulations of remaining time by chore.
#' @param remaining.sims A Tibble containing simulations of remaining time by chore.
sum.remaining.sims <- function (remaining.sims) {
  remaining.sims %>%
    map(function (remaining.sims) {
      ifelse(remaining.sims >= 0, remaining.sims, 0) # Truncate remaining to 0, negative remaining is nonsensical
    }) %>%
    reduce(function (total, remaining.sims) {
      total + remaining.sims
    }, .init = 0) %>%
    list()
}

#' Group chore duration data by chore.
#' @param data A Tibble containing chore duration data to be grouped.
summarize.completed.and.remaining.by.chore <- function (data) {
  # Group by chore and aggregate_key to sum up completed and remaining minutes
  # Grouping by aggregate key first ensures that chores are merged with the correct summary metrics
  completed.and.remaining <- data %>%
    group_by(chore, aggregate_key) %>% # aggregate_key = weekendity if summarized by weekday/weekend or 0 if not
    summarise(
      is.completed = all(is_completed),
      total.count = n(),
      incomplete.count = sum(!is_completed),
      completed = sum(completed_minutes),
      remaining.sims = sum.remaining.sims(remaining.sims))
  # Merge on summary metrics for all chores
  data %>%
    select(chore, order_hint, aggregate_key, mode_duration_minutes, median_duration_minutes, mean_duration_minutes, q.95) %>%
    unique() %>%
    merge(completed.and.remaining)
}

#' The main entry point of the script.
#' @param charts A string vector.  The frequencies to add to the chart.
main <- function (charts = "daily") {
  setnsims(4000)
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
    # For chores completed once or fewer, use mean and sd of all chore completions as fallback
    fallback.on.avg.chore.duration(avg.chore.duration) %>%
    # Use rv to simulate remaining duration for each chore completion based on mean log and sd log
    simulate.remaining() %>%
    # Calculate 95%ile for each chore completion
    calculate.q.95() %>%
    # Group and sum by chore name and weekendity
    summarize.completed.and.remaining.by.chore() %>%
    remaining.simulations.to.summary.metrics() %>%
    # Sort
    arrange.by.remaining.then.completed()
  # Calculate cumulative summary values
  cumulative.completed.and.remaining <- cumulative.sims(completed.and.remaining)
  # Generate chart
  completed.and.remaining %>%
    merge(cumulative.completed.and.remaining) %>%
    chores.completed.and.remaining.stack() %>%
    chores.completed.and.remaining.chart()
}
