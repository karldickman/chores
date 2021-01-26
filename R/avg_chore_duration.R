source("database.R")
source("rv_chore.R")

add.rv.chore <- function (total, mean_log_duration_minutes, sd_log_duration_minutes) {
  sims <- rv.chore(NA, mean_log_duration_minutes, sd_log_duration_minutes)[["sims"]]
  total + sims
}

fitted.avg.chore.duration <- function (avg.chore.duration) {
  mean.log <- mean(log(avg.chore.duration))
  sd.log <- sd(log(avg.chore.duration))
  data.frame(mean_log_duration_minutes = mean.log, sd_log_duration_minutes = sd.log)
}

query.chore_durations <- function (fetch.query.results) {
  "SELECT *
      FROM chore_durations
      WHERE times_completed > 1" %>%
    fetch.query.results()
}

rv.avg.chore.duration <- function (chore.durations) {
  total <- 0
  for (i in 1:nrow(chore.durations)) {
    mean_log_duration_minutes <- chore.durations$mean_log_duration_minutes[[i]]
    sd_log_duration_minutes <- chore.durations$sd_log_duration_minutes[[i]]
    total <- add.rv.chore(total, mean_log_duration_minutes, sd_log_duration_minutes)
  }
  total / nrow(chore.durations)
}

main <- function () {
  setnsims(4000)
  # Read data from database
  avg.chore.duration <- query.chore_durations %>%
    using.database() %>%
    rv.avg.chore.duration() # Use rv to simulate average chore duration
  # Fit log-normal distribution to rv simulation
  fitted.distribution <- fitted.avg.chore.duration(avg.chore.duration)
  mean.log <- fitted.distribution$mean_log_duration_minutes
  sd.log <- fitted.distribution$sd_log_duration_minutes
  mode <- exp(mean.log)
  # Find boundaries of histogram plot
  histogram <- hist(avg.chore.duration, plot = FALSE)
  breaks <- histogram$breaks
  xmin <- min(breaks)
  xmax <- max(breaks)
  fit.max.density <- dlnorm(mode, mean.log, sd.log)
  ymax <- max(c(fit.max.density, histogram$density))
  # Plot log-normal fit
  plot(
    function (x) { dlnorm(x, mean.log, sd.log) },
    xlim = c(xmin, xmax),
    ylim = c(0, ymax),
    main = "Average chore duration",
    xlab = "Chore duration (minutes)",
    ylab = "Proportion")
  # Plot histogram
  hist(
    avg.chore.duration,
    probability = TRUE,
    add = TRUE)
}

if (interactive()) {
  main()
}
