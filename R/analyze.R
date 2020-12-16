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
    chore.durations <- fetch.query.results(database, "SELECT * FROM chore_durations")
    for(i in 1:nrow(chore.durations)) {
      chore <- chore.durations$chore[i]
      mean.log <- chore.durations$avg_log_duration_minutes[i]
      sd.log <- chore.durations$stdev_log_duration_minutes[i]
      if (is.na(sd.log)) {
        cat("Insufficient data for", chore, "\n")
        next
      }
      chore.simulation <- rvlnorm(mean=mean.log, sd=sd.log)
      hist(chore.simulation, main=chore, xlab=paste("Duration of ", chore))
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
