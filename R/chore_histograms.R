source("database.R")

chore.histogram <- function (chore.name, duration.minutes, mean.log, sd.log, mode, left.tail = 0.0001, right.tail = 0.995) {
  title <- paste("Histogram of", chore.name, "duration")
  xlab <- paste(chore.name, "duration (minutes)")
  if (is.na(sd.log)) {
    cat("Insufficient data to fit distribution for", chore.name, "\n")
    tryCatch({
        hist(duration.minutes, main = title, xlab = xlab, freq = FALSE)
      },
      error = function (error) {
        cat("Cannot plot", chore.name, "\n")
      },
      warning = function (warning) {
        cat("Cannot plot", chore.name, "\n")
      }
    )
    return()
  }
  histogram <- hist(duration.minutes, plot = FALSE)
  breaks <- histogram$breaks
  xmin <- min(c(qlnorm(left.tail, mean.log, sd.log), breaks))
  xmax <- max(c(qlnorm(right.tail, mean.log, sd.log), breaks))
  x <- seq(0, xmax, 0.01)
  y <- dlnorm(x, mean.log, sd.log)
  fit.max.density <- dlnorm(mode, mean.log, sd.log)
  ymax <- max(c(fit.max.density, histogram$density))
  hist(duration.minutes, main = title, xlab = xlab, freq = FALSE, xlim = c(xmin, xmax), ylim = c(0, ymax))
  lines(x, y)
}

chore.histograms <- function (chore.durations, fitted.chore.durations) {
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    aggregate.by <- chore.data$aggregate_by_id
    chore.completions <- subset(chore.durations, chore == chore.name)
    if (aggregate.by == 2) {
      aggregate.key <- chore.data$aggregate_key
      chore.completions <- subset(chore.completions, weekendity == aggregate.key)
      chore.name <- paste(ifelse(aggregate.key == 0, "weekday", "weekend"), chore.name)
    }
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    mode <- chore.data$mode_duration_minutes
    chore.histogram(chore.name, chore.completions$duration_minutes, mean.log, sd.log, mode)
  }
}

main <- function () {
  using.database(function (fetch.query.results) {
    chore.durations.sql <- "SELECT chore_id
        , chore
        , duration_minutes
        , weekendity(due_date) AS weekendity
      FROM hierarchical_chore_completion_durations
      JOIN chore_completions USING (chore_completion_id)
      LEFT JOIN chore_schedule USING (chore_completion_id)
      JOIN chores USING (chore_id)
      WHERE chore_completion_status_id = 4"
    fitted.chore.durations.sql <- "SELECT chore_id
        , chores.chore
        , chores.aggregate_by_id
        , aggregate_key
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , mode_duration_minutes
      FROM chores
      LEFT JOIN chore_durations USING (chore_id)
      WHERE chores.is_active"
    chore.durations <- fetch.query.results(chore.durations.sql)
    fitted.chore.durations <- fetch.query.results(fitted.chore.durations.sql)
    chore.histograms(chore.durations, fitted.chore.durations)
  })
}

if (interactive()) {
  main()
}
