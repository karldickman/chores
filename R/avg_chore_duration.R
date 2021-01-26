source("database.R")
source("rv_chore.R")

add.rv.chore <- function (total, mean_log_duration_minutes, sd_log_duration_minutes) {
  sims <- rv.chore(NA, mean_log_duration_minutes, sd_log_duration_minutes)[["sims"]]
  total + sims
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
  # Read data from database
  avg.chore.duration <- using.database(function (fetch.query.results) {
    "SELECT *
        FROM chore_durations
        WHERE times_completed > 1" %>%
      fetch.query.results()
  }) %>%
    rv.avg.chore.duration() # Use rv to simulate average chore duration
  # Fit log-normal distribution to rv simulation
  mean.log <- mean(log(avg.chore.duration))
  sd.log <- sd(log(avg.chore.duration))
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
