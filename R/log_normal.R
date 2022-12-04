suppressPackageStartupMessages(library(rv))

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

# http://jse.amstat.org/v13n1/olsson.html 3.4 Cox method: a modified version
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

sample.size.needed <- function (mean.log, sd.log, sample.size, significance, target, target.type, tail = "upper") {
  if (tail == "both") {
    stop("Two-tailed confidence intervals not supported")
  }
  if (tail == "lower") {
    stop("Lower-bound confidence intervals not supported")
  }
  mean <- log.normal.mean(mean.log, sd.log)
  if (target.type == "relative") {
    target <- 1 + target
  } else if (target.type == "absolute") {
    target <- 1 + target / mean
  } else {
    stop(paste("target.type", target.type), " not supported")
  }
  critical.value <- qt(significance, df = sample.size - 1, lower.tail = FALSE)
  log.target.over.critical.value <- (log(target) / (critical.value * sd.log)) ** 2
  a <- -2 * log.target.over.critical.value
  b <- sd.log ** 2 + 2 * log.target.over.critical.value + 2
  c <- -2
  ceiling((-b - sqrt(b ** 2) - 4 * a * c) / (2 * a))
}
