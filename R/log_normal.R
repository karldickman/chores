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
