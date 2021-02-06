source("database.R")

chore.histogram <- function (chore.name, duration.minutes, mean.log, sd.log, mode, left.tail = 0.0001, right.tail = 0.995) {
  if (length(duration.minutes) == 0) {
    cat("Insufficient data to plot", chore.name, "\n")
    return()
  }
  title <- paste("Histogram of", chore.name, "duration")
  xlab <- paste(chore.name, "duration (minutes)")
  if (is.na(sd.log)) {
    cat("Insufficient data to fit distribution for", chore.name, "\n")
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

chore.histograms <- function (fitted.chore.durations, chore.completion.durations) {
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    aggregate.by <- chore.data$aggregate_by_id
    chore.completions <- subset(chore.completion.durations, chore == chore.name)
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

query.chore.completion.durations <- function (fetch.query.results) {
  "SELECT chore_id
        , chore
        , duration_minutes
        , weekendity(due_date) AS weekendity
      FROM hierarchical_chore_completion_durations
      JOIN chore_completions USING (chore_completion_id)
      LEFT JOIN chore_schedule USING (chore_completion_id)
      JOIN chores USING (chore_id)
      WHERE chore_completion_status_id = 4" %>% # completed
    fetch.query.results()
}

query.fitted.chore.durations <- function (fetch.query.results) {
  "SELECT chore_id
        , chores.chore
        , chores.aggregate_by_id
        , aggregate_key
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , mode_duration_minutes
      FROM chores
      LEFT JOIN chore_durations USING (chore_id)
      WHERE chores.is_active" %>%
    fetch.query.results()
}

main <- function (chore.names = NULL) {
  database.results <- using.database(function (fetch.query.results) {
    fitted.chore.durations <- query.fitted.chore.durations(fetch.query.results)
    chore.completion.durations <- query.chore.completion.durations(fetch.query.results)
    list(fitted.chore.durations, chore.completion.durations)
  })
  fitted.chore.durations <- database.results[[1]]
  chore.completion.durations <- database.results[[2]]
  if (!is.null(chore.names)) {
    fitted.chore.durations <- subset(fitted.chore.durations, chore %in% chore.names)
  }
  chore.histograms(fitted.chore.durations, chore.completion.durations)
}
