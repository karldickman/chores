library(dplyr)

source("database.R")
source("log_normal.R")
source("sum_chores.R")

subtract.chores <- function (minuend, subtrahend) {
  minuend.mean.log <- minuend$mean_log_duration_minutes
  minuend.sd.log <- minuend$sd_log_duration_minutes
  subtrahend.mean.log <- subtrahend$mean_log_duration_minutes
  subtrahend.sd.log <- subtrahend$sd_log_duration_minutes
  rv.minuend <- rvlnorm(mean = minuend.mean.log, sd = minuend.sd.log)
  rv.subtrahend <- rvlnorm(mean = subtrahend.mean.log, sd = subtrahend.sd.log)
  ifelse(
    rv.subtrahend < rv.minuend,
    rv.minuend - rv.subtrahend,
    0)
}

main <- function (minuend.chore, subtrahend.chore, aggregate.keys = 0) {
  setnsims(1000000)
  using.database(function (fetch.query.results) {
    query.fitted.chore.durations(fetch.query.results)
  }) %>%
    filter(aggregate_key %in% aggregate.keys) ->
    fitted.chore.durations
  minuend <- filter(fitted.chore.durations, chore == minuend.chore)
  subtrahend <- filter(fitted.chore.durations, chore == subtrahend.chore)
  subtract.chores(minuend, subtrahend) %>%
    sum.chores.histogram("Sum of chores")
}
