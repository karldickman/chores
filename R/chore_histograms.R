library(dplyr)

source("database.R")
source("log_normal.R")

chore.histogram <- function (chore.name, duration.minutes, summary.statistics, fitted.density, xlim, ylim) {
  title <- paste("Histogram of", chore.name, "duration")
  xlab <- paste(chore.name, "duration (minutes)")
  histogram <- hist(duration.minutes, breaks = "Freedman-Diaconis", plot = FALSE)
  breaks <- histogram$breaks
  xmin <- min(c(xlim, breaks))
  xmax <- max(c(xlim, breaks))
  ymax <- max(c(ylim, histogram$density))
  # Plot log-normal fit
  plot(
    fitted.density,
    xlim = c(xmin, xmax),
    ylim = c(0, ymax),
    main = title,
    xlab = xlab,
    ylab = "Density")
  # Plot histogram
  hist(
    duration.minutes,
    breaks = "Freedman-Diaconis",
    freq = FALSE,
    add = TRUE,
    col = NULL)
  # Reference lines
  abline(v = summary.statistics, col = "red")
}

chore.histograms <- function (fitted.chore.durations, chore.completion.durations, left.tail = 0.0001, right.tail = 0.995) {
  for(i in 1:nrow(fitted.chore.durations)) {
    # Current row of the fitted.chore.durations data frame
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    aggregate.by <- chore.data$aggregate_by_id
    relevant.chore.completion.durations <- subset(chore.completion.durations, chore == chore.name)
    # If chores are aggregated by weekendity, add "weekday/weekend" tags to each chore
    if (aggregate.by == 2) {
      aggregate.key <- chore.data$aggregate_key
      relevant.chore.completion.durations <- subset(relevant.chore.completion.durations, weekendity == aggregate.key)
      chore.name <- paste(ifelse(aggregate.key == 0, "weekday", "weekend"), chore.name)
    }
    # Extract chore completion durations and check for data sufficiency
    duration.minutes <- relevant.chore.completion.durations$duration_minutes
    if (length(duration.minutes) == 0) {
      cat("Insufficient data to plot", chore.name, "\n")
      next()
    }
    # Use log-transformed mean and standard deviation to fit a distribution
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    xlim <- c()
    ylim <- c()
    fitted.density <- NULL
    if (is.na(sd.log)) {
      cat("Insufficient data to fit distribution for", chore.name, "\n")
    }
    else if (chore.name != "put away dishes") {
      mode <- chore.data$mode_duration_minutes
      fit.max.density <- dlnorm(mode, mean.log, sd.log)
      xmin <- min(qlnorm(left.tail, mean.log, sd.log))
      xmax <- max(qlnorm(right.tail, mean.log, sd.log))
      xlim <- c(xmin, xmax)
      ymax <- max(fit.max.density)
      ylim <- c(0, ymax)
      fitted.density <- function (x) {
        dlnorm(x, mean.log, sd.log)
      }
    }
    quantiles <- quantile(duration.minutes, c(0.25, 0.75, 0.95))
    summary.statistics = c(log.normal.mode(mean.log, sd.log), mean(duration.minutes), quantiles[[3]])
    chore.histogram(chore.name, duration.minutes, summary.statistics, fitted.density, xlim, ylim)
    count <- length(duration.minutes)
    iqr <- quantiles[[2]] - quantiles[[1]]
    bin.width <- 2 * iqr / (count ^ (1/3))
    cat(
      chore.name,
      "\n    Count:", count,
      "\n    1st quartile:", quantiles[[1]],
      "\n    Mode:", summary.statistics[[1]],
      "\n    Mean:", summary.statistics[[2]],
      "\n    3rd quartile:", quantiles[[2]],
      "\n    95% CI UB:", summary.statistics[[3]],
      "\n    IQR:", iqr,
      "\n    Bin width:", bin.width,
      "\n")
    if (chore.name == "put away dishes") {
      cat("\"Put away dishes\" is a bimodal distribution for which a log normal fit is inappropriate.")
      put.away.dishes.histogram(fitted.chore.durations, chore.completion.durations)
    }
  }
}

put.away.dishes.histogram <- function (fitted.chore.durations, chore.completion.durations) {
  empty.dishwasher <- subset(fitted.chore.durations, chore == "empty dishwasher")
  empty.drainer <- subset(fitted.chore.durations, chore == "empty drainer")
  empty.dishwasher <- rvlnorm(mean = empty.dishwasher$mean_log_duration_minutes, sd = empty.dishwasher$sd_log_duration_minutes)
  empty.drainer <- rvlnorm(mean = empty.drainer$mean_log_duration_minutes, sd = empty.drainer$sd_log_duration_minutes)
  num.empty.dishwasher <- nrow(subset(chore.completion.durations, chore == "empty dishwasher"))
  num.empty.drainer <- nrow(subset(chore.completion.durations, chore == "empty drainer"))
  num.put.away.dishes <- nrow(subset(chore.completion.durations, chore == "put away dishes"))
  prob.empty.dishwasher <- num.empty.dishwasher / num.put.away.dishes
  prob.empty.drainer <- num.empty.drainer / num.put.away.dishes
  prob.both <- (prob.empty.dishwasher + prob.empty.drainer) - 1
  random.selections <- runif(getnsims())
  ifelse(
    random.selections <= prob.both,
    empty.dishwasher + empty.drainer,
    ifelse(
      random.selections <= prob.empty.dishwasher,
      empty.dishwasher,
      empty.drainer)) %>%
    hist(
      breaks = "Freedman-Diaconis",
      freq = FALSE,
      main = "Modelled duration of put away dishes",
      xlab = "put away dishes duration (minutes)")
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
      LEFT JOIN chore_durations USING (chore_id)" %>%
    fetch.query.results()
}

main <- function (chore.names = NULL) {
  setnsims(10000)
  database.results <- using.database(function (fetch.query.results) {
    fitted.chore.durations <- query.fitted.chore.durations(fetch.query.results)
    chore.completion.durations <- query.chore.completion.durations(fetch.query.results)
    list(fitted.chore.durations, chore.completion.durations)
  })
  fitted.chore.durations <- database.results[[1]]
  chore.completion.durations <- database.results[[2]]
  if (any(chore.names == "put away dishes")) {
    chore.names = c("empty dishwasher", "empty drainer", chore.names)
  }
  if (!is.null(chore.names)) {
    fitted.chore.durations <- subset(fitted.chore.durations, chore %in% chore.names)
  }
  if (nrow(fitted.chore.durations) == 0) {
    stop("No matching chores found")
  }
  chore.histograms(fitted.chore.durations, chore.completion.durations)
}
