source("log_normal.R")

rv.chore <- function (chore, mean_log_duration_minutes, sd_log_duration_minutes, count = 1, ...) {
  sims <- 0
  for (. in 1:count) {
    sims <- sims + rvlnorm(mean = mean_log_duration_minutes, sd = sd_log_duration_minutes)
  }
  list(chore = chore, sims = sims)
}
