library(dplyr)
library(RMariaDB)
library(rv)

rvlnorm <- function (n = 1, mean = 0, sd = 1, var = NULL, precision) {
  exp(sims(rvnorm(n, mean, sd, var, precision)))
}

chore.histogram <- function (chore.name, duration.minutes, mean.log, sd.log, mode) {
  x <- seq(0, exp(mean.log + 4 * sd.log), 0.01)
  y <- dlnorm(x, mean.log, sd.log)
  fit.max.density <- dlnorm(mode, mean.log, sd.log)
  hist.max.density <- max(hist(duration.minutes, plot=FALSE)$density)
  ylim <- max(fit.max.density, hist.max.density)
  #x.max <- ceiling(max(duration.minutes))
  #step <- max(ceiling(x.max / 50), 1)
  #breaks <- seq(0, x.max + step - 1, step)
  hist(duration.minutes, main=paste("Histogram of", chore.name, "duration"), xlab=paste(chore.name, "duration (minutes)"), freq=FALSE, ylim=c(0, ylim))
  lines(x, y)
}

chore.histograms <- function (chore.durations, fitted.chore.durations) {
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.name <- fitted.chore.durations$chore[i]
    aggregate.by <- fitted.chore.durations$aggregate_by_id[i]
    chore.completions <- subset(chore.durations, chore == chore.name)
    if (aggregate.by == 2) {
      aggregate.key <- fitted.chore.durations$aggregate_key[i]
      chore.completions <- subset(chore.completions, weekendity == aggregate.key)
      chore.name <- paste(ifelse(aggregate.key == 0, "weekday", "weekend"), chore.name)
    }
    mean.log <- fitted.chore.durations$avg_log_duration_minutes[i]
    sd.log <- fitted.chore.durations$stdev_log_duration_minutes[i]
    mode <- fitted.chore.durations$mode_duration_minutes[i]
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
    mean.log <- fitted.chore.durations$mean_log_duration_minutes[i]
    sd.log <- fitted.chore.durations$sd_log_duration_minutes[i]
    accumulator <- accumulator + rvlnorm(mean=mean.log, sd=sd.log)
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
    chore.durations <- fetch.query.results(database, "SELECT *, weekendity(due_date) AS weekendity FROM hierarchical_chore_completion_durations JOIN chore_completions USING (chore_completion_id) JOIN chore_schedule USING (chore_completion_id) JOIN chores USING (chore_id)")
    fitted.chore.durations <- fetch.query.results(database, "SELECT * FROM chore_durations_per_day")
    analyze.meals(fitted.chore.durations, 0)
    analyze.meals(fitted.chore.durations, 1)
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
