#!/usr/bin/env r

suppressPackageStartupMessages(library(purrr))

source("database.R")
source("log_normal.R")

plot.completions.needed.one.tailed <- function (
    chore,
    mean.log,
    sd.log,
    times.completed,
    tail,
    relative.target = 0.05,
    absolute.target.seconds = 30,
    significance = 0.05
  ) {
  if (times.completed < 2) {
    stop("Need a minimum of two times completed to calculation completions needed")
  }
  cat(chore, "\n")
  cat("Times completed:", times.completed, "\n")
  title <- paste(chore, "completions needed for", 1 - significance, "confidence")
  ylab <- paste(1 - significance, paste("confidence interval", tail, "bound"))
  mean <- log.normal.mean(mean.log, sd.log)
  # Completions needed for relative target
  needed.for.relative.target <- sample.size.needed(mean.log, sd.log, times.completed, significance, relative.target, "relative", tail)
  cat("To ", relative.target, ": ", needed.for.relative.target - times.completed, "\n", sep = "")
  # Completions needed for absolute target
  absolute.target <- absolute.target.seconds / 60
  needed.for.absolute.target <- sample.size.needed(mean.log, sd.log, times.completed, significance, absolute.target, "absolute", tail)
  cat("To ", absolute.target.seconds, " seconds: ", needed.for.absolute.target - times.completed, "\n", sep = "")
  # Plot the curve!
  confidence.interval.upper.bound <- function (n) {
    log.normal.confidence.bound(mean.log, sd.log, n, significance, tail)
  }
  current.ci.ub <- confidence.interval.upper.bound(times.completed)
  padding <- 0.2
  sign <- ifelse(tail == "upper", 1, -1)
  plot(
    confidence.interval.upper.bound,
    xlim = c(
      2,
      max(times.completed, needed.for.relative.target, needed.for.absolute.target) * (padding + 1)),
    ylim = c(
      min(mean - absolute.target, mean * (1 - relative.target)),
      max(mean * 1.05, current.ci.ub * 1.05, mean + sign * absolute.target, mean * (1 + sign * relative.target * 1.5))),
    main = title,
    xlab = "Times completed",
    ylab = ylab)
  # Current mean
  abline(h = mean, col = "red")
  # Actual completions
  abline(v = times.completed, col = "blue")
  abline(h = current.ci.ub, col = "blue")
  # Completions needed for 5%
  abline(h = mean * (1 + sign * relative.target), col = "green")
  abline(v = needed.for.relative.target, col = "green")
  # Completions needed for 30 seconds
  abline(h = mean + sign * absolute.target, col = "purple")
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

plot.completions.needed.two.tailed <- function (
    chore,
    mean.log,
    sd.log,
    times.completed,
    relative.target = 0.05,
    absolute.target.seconds = 60,
    significance = 0.05
) {
  cat(chore, "\n")
  cat("Times completed:", times.completed, "\n")
  title <- paste(chore, "completions needed for", 1 - significance, "confidence")
  ylab <- paste(1 - significance, "confidence interval bound")
  mean <- log.normal.mean(mean.log, sd.log)
  # Completions needed for relative target
  needed.for.relative.target <- sample.size.needed(mean.log, sd.log, times.completed, significance, relative.target, "relative", "both")
  cat("To ", relative.target, ": ", needed.for.relative.target - times.completed, "\n", sep = "")
  # Completions needed for absolute target
  absolute.target <- absolute.target.seconds / 60
  needed.for.absolute.target <- sample.size.needed(mean.log, sd.log, times.completed, significance, absolute.target, "absolute", "both")
  cat("To ", absolute.target.seconds, " seconds: ", needed.for.absolute.target - times.completed, "\n", sep = "")
  # Plot the curve!
  confidence.interval.lower.bound <- function (n) {
    log.normal.confidence.bound(mean.log, sd.log, n, significance, "both")[[1]]
  }
  confidence.interval.upper.bound <- function (n) {
    log.normal.confidence.bound(mean.log, sd.log, n, significance, "both")[[2]]
  }
  current.ci.lb <- confidence.interval.lower.bound(times.completed)
  current.ci.ub <- confidence.interval.upper.bound(times.completed)
  padding <- 0.15
  plot(
    confidence.interval.upper.bound,
    xlim = c(
      2,
      max(times.completed, needed.for.relative.target, needed.for.absolute.target) * (1 + padding)),
    ylim = c(
      min(current.ci.lb * 0.85, mean - absolute.target, mean * (1 - relative.target)),
      max(current.ci.ub * 1.05, mean + absolute.target, mean * (1 + relative.target * 1.5))),
    main = title,
    xlab = "Times completed",
    ylab = ylab)
  plot(
    confidence.interval.lower.bound,
    xlim = c(2, max(needed.for.relative.target, needed.for.absolute.target) * (padding + 1)),
    add = TRUE)
  # Current mean
  abline(h = mean, col = "red")
  # Actual completions
  abline(v = times.completed, col = "blue")
  abline(h = current.ci.lb, col = "blue")
  abline(h = current.ci.ub, col = "blue")
  # Completions needed for 5%
  abline(h = mean * (1 - relative.target / 2), col = "green")
  abline(h = mean * (1 + relative.target / 2), col = "green")
  abline(v = needed.for.relative.target, col = "green")
  # Completions needed for 30 seconds
  abline(h = mean - absolute.target / 2, col = "purple")
  abline(h = mean + absolute.target / 2, col = "purple")
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

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat(error, "\n")
  }
  cat("Usage: completions-needed CHORE_NAME [...CHORE_NAME] [OPTIONS]\n")
  cat("    --tail lower, upper, or both; upper is default.\n")
}

parse.args <- function (argv) {
  argv <- c(argv, NA)
  chores <- c()
  tail <- "upper"
  parse.options <- TRUE
  i <- 0
  while (i < length(argv) - 1) {
    i <- i + 1
    arg <- argv[[i]]
    nextArg <- argv[[i + 1]]
    if (arg == "--") {
      parse.options <- FALSE
      next
    }
    if (startsWith(arg, "--")) {
      if (startsWith(arg, "--tail")) {
        if (arg == "--tail") {
          tail <- nextArg
          i <- i + 1
        } else {
          tail <- gsub("--tail=", "", arg)
        }
        if (is.na(tail)) {
          usage <- "Specify a value for --tail"
          return(list(usage = usage))
        } else if (!(tail %in% c("upper", "lower", "both"))) {
          usage <- paste("Invalid --tail", tail)
          return(list(usage = usage))
        }
      } else {
        usage <- paste("Unknown option", arg)
        return(list(usage = usage))
      }
    } else {
      chores <- c(chores, arg)
    }
  }
  list(
    arguments = chores,
    options = list(
      tail = tail
    )
  )
}

main <- function (argv) {
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
    return()
  }
  parsed.args <- parse.args(argv)
  if (!is.null(parsed.args$usage)) {
    usage(parsed.args$usage)
    return()
  }
  chore.names <- parsed.args$arguments
  options <- parsed.args$options
  if (length(chore.names) == 0) {
    cat("Provide at least one chore name.\n")
    usage()
    return()
  }
  database.results <- using.database(function (fetch.query.results) {
    param.list <- paste0(rep("?", length(chore.names)), collapse = ", ")
    paste0(
      "SELECT chore, aggregate_by, weekendity, mean_log_duration_minutes, sd_log_duration_minutes, times_completed
          FROM chore_duration_confidence_intervals
          JOIN aggregate_by USING (aggregate_by_id)
          JOIN aggregate_keys USING (aggregate_by_id, aggregate_key)
          LEFT JOIN weekendities USING (aggregate_key_id)
          JOIN chores USING (chore_id)
          WHERE chore IN (", param.list, ")
          ORDER BY chore, aggregate_key") %>%
      fetch.query.results(list(chore.names))
  })
  for (i in seq(1, nrow(database.results))) {
    row <- slice(database.results, i)
    chore <- row$chore
    if (!is.na(row$weekendity)) {
      chore = paste(row$weekendity, chore)
    }
    mean.log <- row$mean_log_duration_minutes
    sd.log <- row$sd_log_duration_minutes
    times.completed <- as.integer(row$times_completed)
    if (row$aggregate_by == "weekendity" | options$tail == "both") {
      plot.completions.needed.two.tailed(chore, mean.log, sd.log, times.completed)
    } else {
      plot.completions.needed.one.tailed(chore, mean.log, sd.log, times.completed, options$tail)
    }
  }
}

if (!interactive() & basename(sys.frame(1)$ofile) == "completions_needed.R") {
  main(argv)
}
