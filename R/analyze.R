library(RMariaDB)
library(rv)

rvlnorm <- function (n = 1, mean = 0, sd = 1, var = NULL, precision) {
  exp(sims(rvnorm(n, mean, sd, var, precision)))
}

breakfast <- function () {
  make <- rvnorm(mean=1.8550730881360304, sd=0.660933384435345)
  eat <- rvnorm(mean=2.711979067072755, sd=0.3245818759815408)
  do.dishes <- rvnorm(mean=1.393016162442342, sd=0.5975510138167739)
  put.away.dishes <- rvnorm(mean=1.6883206019264831, sd=0.7991344612602828)
  breakfast <- exp(sims(make)) + exp(sims(eat)) + exp(sims(do.dishes)) + exp(sims(put.away.dishes))
  mean(breakfast)
  quantile(breakfast, c(0.5, 0.9, 0.95))
  hist(breakfast, xlim=c(0, 100), breaks=200)
}

connect <- function () {
  dbConnect(RMariaDB::MariaDB(), user="root", password, dbname="chores", host="localhost")
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

main <- function () {
  setnsims(1000000)
  database <- NULL
  tryCatch({
    database <- connect()
    chore.durations <- fetch.query.results(database, "SELECT *, weekendity(due_date) AS weekendity FROM hierarchical_chore_completion_durations JOIN chore_completions USING (chore_completion_id) JOIN chore_schedule USING (chore_completion_id) JOIN chores USING (chore_id)")
    fitted.chore.durations <- fetch.query.results(database, "SELECT * FROM chore_durations")
    for(i in 1:nrow(fitted.chore.durations)) {
      chore.name <- fitted.chore.durations$chore[i]
      aggregate.by <- fitted.chore.durations$aggregate_by_id[i]
      chore.completions <- subset(chore.durations, chore == chore.name)
      if (aggregate.by == 2) {
        aggregate.key <- fitted.chore.durations$aggregate_key[i]
        chore.completions <- subset(chore.completions, weekendity == aggregate.key)
        weekendity <- ifelse(aggregate.key == 0, "weekday", "weekend")
      } else {
        weekendity = ""
      }
      mean.log <- fitted.chore.durations$avg_log_duration_minutes[i]
      sd.log <- fitted.chore.durations$stdev_log_duration_minutes[i]
      if (is.na(sd.log)) {
        cat("Insufficient data for", chore.name, "\n")
        next
      }
      x <- seq(0, exp(mean.log + 4 * sd.log), 0.01)
      y <- dlnorm(x, mean.log, sd.log)
      #x.max <- ceiling(max(chore.completions$duration_minutes))
      #step <- max(ceiling(x.max / 50), 1)
      #breaks <- seq(0, x.max + step - 1, step)
      hist(chore.completions$duration_minutes, main=paste("Histogram of", weekendity, chore.name, "duration"), xlab=paste(weekendity, chore.name, "duration (minutes)"), freq = FALSE)
      lines(x, y)
    }
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
