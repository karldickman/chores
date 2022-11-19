library(rv)

log.normal.mean <- function (mean.log, sd.log) {
  exp(mean.log + (sd.log ** 2) / 2)
}

log.normal.median <- function (mean.log, .) {
  exp(mean.log)
}

log.normal.mode <- function (mean.log, sd.log) {
  exp(mean.log - sd.log ** 2)
}

scale.log.normal.mean <- function (mean, factor) {
  mean + log(factor)
}

rvlnorm <- function (n = 1, mean = 0, sd = 1, var = NULL, precision) {
  exp(sims(rvnorm(n, mean, sd, var, precision)))
}

log.normal.confidence.bound <- function (sample.mean, sample.sd, sample.size, significance, tail = "both") {
  sample.variance <- sample.sd ^ 2
  sample.size <- as.integer(sample.size)
  augend <- sample.mean + sample.variance / 2
  if (tail == "both") {
    significance <- significance / 2
  }
  critical.value <- qt(significance, df = sample.size - 1, lower.tail = FALSE)
  addend <- critical.value * sqrt(sample.variance / sample.size + sample.variance ^ 2 / (2 * (sample.size - 1)))
  lower <- augend - addend
  upper <- augend + addend
  if (tail == "lower") {
    return (lower)
  }
  if (tail == "upper") {
    return (upper)
  }
  c(lower, upper)
}
