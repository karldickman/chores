library(dplyr)
library(plotly)
library(purrr)

source("database.R")
source("log_normal.R")

arrange.by.remaining.then.completed <- function (data) {
  data <- cbind(data)
  # Sort in descending order of remaining duration, then by completed
  chore.order <- order(ifelse(data$is_completed, data$completed, -data$remaining.median))
  data$chore <- factor(data$chore, levels = unique(data$chore)[chore.order])
  arrange(data, chore)
}

chores.completed.and.remaining.chart <- function (data) {
  data %>%
    plot_ly(type = "bar", x = ~chore, y = ~completed, name = "completed") %>%
    add_trace(y = ~mode.diff, name = "mode") %>%
    add_trace(y = ~median.diff, name = "median") %>%
    add_trace(y = ~mean.diff, name = "mean") %>%
    add_trace(y = ~q.95.diff, name = "95 %ile") %>%
    layout(
      barmode = "stack",
      yaxis = list(title = "Duration (minutes)"),
      legend = list(orientation = "h", y = -0.3))
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
  mode.diff <- data$remaining.mode
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

group.by.chore <- function (data) {
  final.colnames <- c("chore", "is_completed", "completed", "mode", "median", "mean", "q.95")
  data$is_completed <- data$is_completed == 1
  # Add 0.95 quantile -- data from database is difference between quantile and completed, not the actual quantile
  data$q.95 <- qlnorm(0.95, data$mean_log_duration_minutes, data$sd_log_duration_minutes)
  # Count occurrences of each chore, summarize completed minutes
  data.summarized <- data %>%
    group_by(chore, is_completed) %>%
    summarise(
      count = n(),
      total_completed_minutes = sum(completed_minutes)
    )
  data <- merge(data, data.summarized)
  # Separate out chores with one repetition, drop irrelevant columns
  one <- data %>%
    subset(count == 1)
  one <- one[c("chore", "is_completed", "completed_minutes", "mode_duration_minutes", "median_duration_minutes", "mean_duration_minutes", "q.95")]
  colnames(one) <- final.colnames
  # 0 for all metrics but completed if the chore is completed
  zero.if.completed <- function (x) { ifelse(!one$is_completed, x, 0) }
  one$mode <- zero.if.completed(one$mode)
  one$median <- zero.if.completed(one$median)
  one$mean <- zero.if.completed(one$mean)
  one$q.95 <- zero.if.completed(one$q.95)
  # Separate out chores with multiple repetitions, simulate using rv
  many <- subset(data, count > 1)
  if (nrow(many) > 0) {
    many <- many %>%
      unique() %>%
      pmap(rv.chore) %>%
      map_dfr(summarize.rv) %>%
      merge(data.summarized[c("chore", "total_completed_minutes")]) %>%
      merge(data.frame(is_completed = FALSE, mode = NA))
    many <- many[c("chore", "is_completed", "total_completed_minutes", "mode", "median", "mean", "q.95")]
    colnames(many) <- final.colnames
    # Recombine one and many
    data <- rbind(one, many)
  }
  else {
    data <- one
  }
  # Convert summary metrics to remaining duration
  data$remaining.mode <- ifelse(!is.na(data$mode), ifelse(!data$is_completed, data$mode - data$completed, 0), 0)
  data$remaining.median <- ifelse(!data$is_completed, data$median - data$completed, 0)
  data$remaining.mean <- ifelse(!data$is_completed, data$mean - data$completed, 0)
  data$remaining.q.95 <- ifelse(!data$is_completed, data$q.95 - data$completed, 0)
  data %>%
    group_by(chore) %>%
    summarise(
      is_completed = all(is_completed),
      completed = sum(completed),
      remaining.mode = sum(remaining.mode),
      remaining.median = sum(remaining.median),
      remaining.mean = sum(remaining.mean),
      remaining.q.95 = sum(remaining.q.95)) %>%
    as.data.frame()
}

rv.chore <- function (chore, mean_log_duration_minutes, sd_log_duration_minutes, count = 1, ...) {
  sims <- 0
  for (. in 1:count) {
    sims <- sims + rvlnorm(mean = mean_log_duration_minutes, sd = sd_log_duration_minutes)
  }
  list(chore = chore, sims = sims)
}

summarize.rv <- function (chore.sims) {
  chore <- chore.sims$chore
  sims <- chore.sims$sims
  quantiles <- quantile(sims, c(0.5, 0.95))
  data.frame(chore, median = quantiles[["50%"]], mean = mean(sims), q.95 = quantiles[["95%"]])
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
  #completed.and.remaining %>%
  #  arrange.by.remaining.then.completed() %>%
  #  cumulative.duration.remaining.sims() %>%
  #  cumulative.sims() %>%
  #  cumulative.duration.remaining.summary.values() ->
  #  cumulative.summary.values
  completed.and.remaining %>%
    group.by.chore() %>%
    arrange.by.remaining.then.completed() %>%
    chores.completed.and.remaining.stack() %>%
    chores.completed.and.remaining.chart()
}

if (interactive()) {
  main()
}
