library(RMariaDB)

connect <- function () {
  settings <- paste(Sys.getenv("HOME"), ".my.cnf", sep = "/")
  dbConnect(RMariaDB::MariaDB(), default.file = settings, groups = "clientchores")
}

fetch.query.results <- function (database, query) {
  result <- NULL
  tryCatch({
    result <- dbSendQuery(database, query)
    dbFetch(result)
  },
  error = stop.with.message,
  warning = stop.with.message,
  finally = {
    if (!is.null(result)) {
      dbClearResult(result)
    }
  })
}

using.database <- function (operation) {
  database <- NULL
  withCallingHandlers({
    database <- connect()
    operation(function (query) {
      fetch.query.results(database, query)
    })
    if (!is.null(database)) {
      dbDisconnect(database)
      database <- NULL
    }
  },
  error = function (message) {
    if (!is.null(database)) {
      dbDisconnect(database)
      database <- NULL
    }
    stop(message)
  },
  warning = function (message) {
    if (!is.null(database)) {
      dbDisconnect(database)
      database <- NULL
    }
    stop(message)
  })
  if (!is.null(database)) {
    dbDisconnect(database)
  }
}