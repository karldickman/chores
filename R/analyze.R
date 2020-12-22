library(dplyr)
library(RMariaDB)
library(rv)

scale.log.normal.mean <- function (mean, factor) {
  mean + log(factor)
}

rvlnorm <- function (n = 1, mean = 0, sd = 1, var = NULL, precision) {
  exp(sims(rvnorm(n, mean, sd, var, precision)))
}

chore.histogram <- function (chore.name, duration.minutes, mean.log, sd.log, mode) {
  xlim <- exp(mean.log + 4 * sd.log)
  x <- seq(0, xlim, 0.01)
  y <- dlnorm(x, mean.log, sd.log)
  fit.max.density <- dlnorm(mode, mean.log, sd.log)
  hist.max.density <- max(hist(duration.minutes, plot=FALSE)$density)
  ylim <- max(fit.max.density, hist.max.density)
  #x.max <- ceiling(max(duration.minutes))
  #step <- max(ceiling(x.max / 50), 1)
  #breaks <- seq(0, x.max + step - 1, step)
  hist(duration.minutes, main=paste("Histogram of", chore.name, "duration"), xlab=paste(chore.name, "duration (minutes)"), freq=FALSE, xlim=c(0, xlim), ylim=c(0, ylim))
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
    if (is.na(sd.log)) {
      cat("Insufficient data for", chore.name, "\n")
      next
    }
    chore.histogram(chore.name, chore.completions$duration_minutes, mean.log, sd.log, mode)
  }
}

connect <- function () {
  settings <- paste(Sys.getenv("HOME"), ".my.cnf", sep="/")
  dbConnect(RMariaDB::MariaDB(), default.file=settings, groups="clientchores")
}

fetch.query.results <- function (database, query) {
  result <- NULL
  tryCatch({
    result <- dbSendQuery(database, query)
    dbFetch(result)
  },
  error=function (message) {
    stop(message)
  },
  warning=function (message) {
    stop(message)
  },
  finally={
    if (!is.null(result)) {
      dbClearResult(result)
    }
  })
}

sum.chores <- function (fitted.chore.durations) {
  accumulator <- 0
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    completions.per.day <- chore.data$completions_per_day
    if (completions.per.day > 1 & completions.per.day < 2) {
      cat("Skipping", chore.name, "not configured to analyze", completions.per.day, "completions per day.\n")
      next
    }
    if (completions.per.day <= 1) {
      if (completions.per.day < 1) {
        mean.log <- scale.log.normal.mean(mean.log, completions.per.day)
      }
      accumulator <- accumulator + rvlnorm(mean=mean.log, sd=sd.log)
    }
    else {
      for (. in 1:completions.per.day) {
        accumulator <- accumulator + rvlnorm(mean=mean.log, sd=sd.log)
      }
      if (abs(completions.per.day - round(completions.per.day)) > 0.1) {
        cat(chore.name, "has non-integer completions per day", completions.per.day, "\n")
      }
    }
  }
  return(accumulator)
}

sum.chores.histogram <- function (sims, title) {
  quantiles <- quantile(sims, c(0.5, 0.95, 0.995))
  xlim <- quantiles[["99.5%"]]
  cat(title, "\n")
  cat("\tMedian:", quantiles[["50%"]], "\n")
  cat("\tMean:", mean(sims), "\n")
  cat("\t95% CI UB:", quantiles[["95%"]], "\n")
  hist(sims, breaks=xlim, freq=FALSE, xlim=c(0, xlim), main=title, xlab=paste(title, "duration (minutes)"))
}

analyze.meals <- function (fitted.chore.durations, weekendity) {
  weekend.label <- ifelse(weekendity, "Weekend", "Weekday")
  all.meal.chores <- NULL
  for (meal in c("breakfast", "lunch", "dinner")) {
    meal.chores <- data.frame(chore=c(paste("make", meal), paste("eat", meal), paste(meal, "dishes"), "put away dishes"), aggregate_key=weekendity)
    if (is.null(all.meal.chores)) {
      all.meal.chores <- meal.chores
    } else {
      all.meal.chores <- rbind(all.meal.chores, meal.chores)
    }
    merge(fitted.chore.durations, meal.chores) %>% sum.chores %>% sum.chores.histogram(paste(weekend.label, meal))
  }
  merge(fitted.chore.durations, all.meal.chores) %>% sum.chores %>% sum.chores.histogram(paste(weekend.label, "meals"))
}

main <- function () {
  setnsims(1000000)
  database <- NULL
  tryCatch({
    # Load data from database
    database <- connect()
    chore.durations.sql <- "SELECT *, weekendity(due_date) AS weekendity
      FROM hierarchical_chore_completion_durations
      JOIN chore_completions USING (chore_completion_id)
      JOIN chore_schedule USING (chore_completion_id)
      JOIN chores USING (chore_id)"
    fitted.chore.durations.sql <- "SELECT *
      FROM chore_durations_per_day
      WHERE chore_id NOT IN (SELECT chore_id
          FROM chore_hierarchy)
        AND is_active"
    chore.durations <- fetch.query.results(database, chore.durations.sql)
    fitted.chore.durations <- fetch.query.results(database, fitted.chore.durations.sql)
    chore.histograms(chore.durations, fitted.chore.durations)
    #subset(fitted.chore.durations, daily == 1 & weekendity == 0) %>% sum.chores %>% sum.chores.histogram("Weekday chores")
  },
  error=function (message) {
    stop(message)
  },
  warning=function (message) {
    stop(message)
  },
  finally={
    if (!is.null(database)) {
      dbDisconnect(database)
    }
  })
}
