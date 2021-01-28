source("database.R")
source("log_normal.R")

fitted.avg.chore.duration <- function (chore.durations) {
  mean.log <- mean(log(chore.durations))
  sd.log <- sd(log(chore.durations))
  data.frame(mean_log_duration_minutes = mean.log, sd_log_duration_minutes = sd.log)
}

query.chore_durations <- function (fetch.query.results) {
  "SELECT *
      FROM hierarchical_chore_completion_durations
      JOIN chore_completions USING (chore_completion_id)
      WHERE chore_completion_status_id = 4 # Completed" %>%
    fetch.query.results()
}

main <- function () {
  setnsims(4000)
  # Read data from database
  chore.durations <- using.database(query.chore_durations)$duration_minutes
  # Fit log-normal distribution to rv simulation
  fitted.distribution <- fitted.avg.chore.duration(chore.durations)
  mean.log <- fitted.distribution$mean_log_duration_minutes
  sd.log <- fitted.distribution$sd_log_duration_minutes
  mode <- log.normal.mode(mean.log, sd.log)
  # Find boundaries of histogram plot
  histogram <- hist(chore.durations, plot = FALSE)
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
    chore.durations,
    probability = TRUE,
    add = TRUE)
}
