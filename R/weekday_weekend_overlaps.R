#!/usr/bin/env r

suppressPackageStartupMessages(library(dplyr))

source("chore_histograms.R")
source("database.R")
source("log_normal.R")

density.plots <- function (chore.name, duration.minutes, mean.logs, sd.logs, confidence.intervals, xlim, ylim) {
  title <- paste("Weekday versus weekend", chore.name, "duration")
  xlab <- paste(chore.name, "duration (minutes)")
  histogram <- hist(duration.minutes, breaks = "Freedman-Diaconis", plot = FALSE)
  breaks <- histogram$breaks
  xmin <- min(c(xlim, breaks))
  xmax <- max(c(xlim, breaks))
  ymax <- max(c(ylim, histogram$density))
  xlim <- c(xmin, xmax)
  ylim <- c(0, ymax)
  # Plot log-normal fit
  plot(
    function (x) {
      dlnorm(x, mean.logs[[1]], sd.logs[[1]])
    },
    xlim = xlim,
    ylim = ylim,
    main = title,
    xlab = xlab,
    ylab = "Density",
    col = "green")
  plot(
    function (x) {
      dlnorm(x, mean.logs[[2]], sd.logs[[2]])
    },
    xlim = xlim,
    ylim = ylim,
    add = TRUE,
    col = "purple")
  # Plot histogram
  hist(
    duration.minutes,
    breaks = "Freedman-Diaconis",
    freq = FALSE,
    add = TRUE,
    col = NULL)
  ## Reference lines
  abline(v = confidence.intervals[[1]], col = "green")
  abline(v = confidence.intervals[[2]], col = "purple")
}

chore.histograms <- function (fitted.chore.durations, chore.completion.durations, left.tail = 0.0001, right.tail = 0.995) {
  duration.minutes <- c()
  mean.logs <- c()
  sd.logs <- c()
  confidence.intervals <- list()
  xmin <- c()
  xmax <- c()
  ymax <- c()
  for(i in 1:nrow(fitted.chore.durations)) {
    # Current row of the fitted.chore.durations data frame
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    aggregate.by <- chore.data$aggregate_by_id
    relevant.chore.completion.durations <- subset(chore.completion.durations, chore == chore.name)
    aggregate.key <- chore.data$aggregate_key
    relevant.chore.completion.durations <- subset(relevant.chore.completion.durations, weekendity == aggregate.key)
    # Extract chore completion durations and check for data sufficiency
    duration.minutes <- relevant.chore.completion.durations$duration_minutes
    if (length(duration.minutes) == 0) {
      cat("Insufficient data to plot", chore.name, "\n")
      next()
    }
    # Use log-transformed mean and standard deviation to fit a distribution
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    mean.logs <- c(mean.logs, mean.log)
    sd.logs <- c(sd.logs, sd.log)
    fitted.density <- NULL
    if (is.na(sd.log)) {
      cat("Insufficient data to fit distribution for", chore.name, "\n")
    }
    else {
      duration.minutes <- c(duration.minutes, chore.data$mode_duration_minutes)
      mode <- chore.data$mode_duration_minutes
      fit.max.density <- dlnorm(mode, mean.log, sd.log)
      xmin <- min(xmin, qlnorm(left.tail, mean.log, sd.log))
      xmax <- max(xmax, qlnorm(right.tail, mean.log, sd.log))
      ymax <- max(ymax, fit.max.density)
      confidence.intervals[[i]] <- exp(log.normal.confidence.bound(mean.log, sd.log, chore.data$times_completed, 0.05))
    }
  }
  xlim <- c(xmin, xmax)
  ylim <- c(0, ymax)
  density.plots(chore.name, duration.minutes, mean.logs, sd.logs, confidence.intervals, xlim, ylim)
}

main <- function (chore.name = NULL) {
  if (length(chore.name) > 1) {
    stop("Too many arguments\nUsage: weekday-weekend-overlaps CHORE_NAME")
  }
  setnsims(10000)
  database.results <- using.database(function (fetch.query.results) {
    fitted.chore.durations <- query.fitted.chore.durations(fetch.query.results)
    chore.completion.durations <- query.chore.completion.durations(fetch.query.results)
    list(fitted.chore.durations, chore.completion.durations)
  })
  fitted.chore.durations <- database.results[[1]]
  chore.completion.durations <- database.results[[2]]
  if (!is.null(chore.name)) {
    fitted.chore.durations <- subset(fitted.chore.durations, chore == chore.name)
  }
  if (nrow(fitted.chore.durations) == 0) {
    stop("No matching chores found")
  }
  if (any(fitted.chore.durations$aggregate_by_id == 0)) {
    stop("Chore is not aggregated by weekendity")
  }
  chore.histograms(fitted.chore.durations, chore.completion.durations)
}

if (!interactive() & basename(sys.frame(1)$ofile) == "weekday_weekend_overlaps.R") {
  main(argv)
}
