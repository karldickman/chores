#!/usr/bin/env r

source("database.R")
source("log_normal.R")

plot.completions.needed <- function (
    chore,
    mean.log,
    sd.log,
    times.completed,
    relative.target = 0.05,
    absolute.target.seconds = 30,
    significance = 0.05
  ) {
  cat("Times completed:", times.completed, "\n")
  title <- paste(chore, "completions needed for", 1 - significance, "confidence")
  ylab <- paste(1 - significance, "confidence interval upper bound")
  mean <- log.normal.mean(mean.log, sd.log)
  # Completions needed for 5%
  relative.target <- 0.05
  needed.for.relative.target <- sample.size.needed(mean.log, sd.log, times.completed, significance, relative.target, "relative")
  cat("To ", relative.target, ": ", needed.for.relative.target - times.completed, "\n", sep = "")
  # Completions needed for 30 seconds
  absolute.target.seconds <- 30
  absolute.target <- absolute.target.seconds / 60
  needed.for.absolute.target <- sample.size.needed(mean.log, sd.log, times.completed, significance, absolute.target, "absolute")
  cat("To ", absolute.target.seconds, " seconds: ", needed.for.absolute.target - times.completed, "\n", sep = "")
  # Plot the curve!
  confidence.interval.upper.bound <- function (n) {
    exp(log.normal.confidence.bound(mean.log, sd.log, n, significance, "upper"))
  }
  padding <- 0.2
  plot(
    confidence.interval.upper.bound,
    xlim = c(2, max(needed.for.relative.target, needed.for.absolute.target) * (padding + 1)),
    ylim = c(
      min(mean - absolute.target, mean * (1 - relative.target)),
      max(mean + absolute.target, mean * (1 + relative.target * 1.5))),
    main = title,
    xlab = "Times completed",
    ylab = ylab)
  # Current mean
  abline(h = mean, col = "red")
  # Actual completions
  abline(v = times.completed, col = "blue")
  abline(h = confidence.interval.upper.bound(times.completed), col = "blue")
  # Completions needed for 5%
  abline(h = mean * (1 + relative.target), col = "green")
  abline(v = needed.for.relative.target, col = "green")
  # Completions needed for 30 seconds
  abline(h = mean + absolute.target, col = "purple")
  abline(v = needed.for.absolute.target, col = "purple")
  # Add legend
  legend(
    x = "bottom",
    bg = rgb(1, 1, 1, 0.8),
    legend = c(
      ylab,
      "Mean",
      "Times completed",
      paste("To", relative.target),
      paste("To", absolute.target.seconds, "seconds")),
    lty = c(1, 1, 1, 1, 1),
    col = c("black", "red", "blue", "green", "purple"))
}

main <- function (argv) {
  chore.name <- argv
  if (length(chore.name) > 1) {
    stop("Too many arguments\nUsage: chore-completions-needed CHORE_NAME")
  }
  database.results <- using.database(function (fetch.query.results) {
    fetch.query.results(
      "SELECT chore, mean_log_duration_minutes, sd_log_duration_minutes, times_completed
          FROM chore_duration_confidence_intervals
          JOIN chores USING (chore_id)
          WHERE chore = ?",
      list(chore.name)
    )
  })
  plot.completions.needed(
    database.results$chore,
    database.results$mean_log_duration_minutes,
    database.results$sd_log_duration_minutes,
    as.integer(database.results$times_completed))
}

if (!interactive() & basename(sys.frame(1)$ofile) == "completions_needed.R") {
  main(argv)
}
