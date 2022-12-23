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
  lower <- exp(augend - addend)
  upper <- exp(augend + addend)
  if (tail == "lower") {
    return (lower)
  }
  if (tail == "upper") {
    return (upper)
  }
  list(lower, upper)
}

bisection <- function (lower, upper, error) {
  .bisection <- function (lower, upper, lower.error, upper.error) {
    if (upper - lower <= 1) {
      return(upper)
    }
    midpoint <- round((lower + upper) / 2)
    midpoint.error <- error(midpoint)
    if (midpoint.error > 0) {
      lower <- midpoint
      lower.error <- midpoint.error
    } else {
      upper <- midpoint
      upper.error <- midpoint.error
    }
    .bisection(lower, upper, lower.error, upper.error)
  }
  lower.error <- error(lower)
  upper.error <- error(upper)
  .bisection(lower, upper, lower.error, upper.error)
}

sample.size.needed <- function (mean.log, sd.log, sample.size, significance, target, target.type, tail = "upper") {
  if (!(tail %in% c("both", "lower", "upper"))) {
    stop(paste("tail", tail), " not supported")
  }
  mean <- log.normal.mean(mean.log, sd.log)
  if (target.type == "relative") {
    target <- target * mean
  } else if (target.type != "absolute") {
    stop(paste("target.type", target.type), " not supported")
  }
  if (tail == "both") {
    get.actual <- function (confidence.bounds) {
      confidence.bounds[[2]] - confidence.bounds[[1]]
    }
  } else {
    get.actual <- function (confidence.bound) {
      (confidence.bound - mean) * ifelse(tail == "upper", 1, -1)
    }
  }
  error <- function (sample.size) {
    confidence.bound <- log.normal.confidence.bound(mean.log, sd.log, sample.size, significance, tail)
    actual <- get.actual(confidence.bound)
    actual - target
  }
  lower.bound <- 3
  upper.bound <- 2147483647
  bisection(lower.bound, upper.bound, error)
}
