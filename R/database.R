library(RMariaDB)

connect <- function () {
  settings <- paste(Sys.getenv("HOME"), ".my.cnf", sep = "/")
  dbConnect(MariaDB(), default.file = settings, groups = "clientchores", timezone = Sys.timezone())
}

fetch.query.results <- function (database, query) {
  result <- NULL
  withCallingHandlers({
    result <- dbSendQuery(database, query)
    fetched <- dbFetch(result)
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    return(fetched)
  },
  error = function (message) {
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    stop(message)
  },
  warning = function (message) {
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    stop(message)
  })
  if (!is.null(result)) {
    dbClearResult(result)
  }
}

using.database <- function (operation) {
  database <- NULL
  result <- NULL
  withCallingHandlers({
    database <- connect()
    result <- operation(function (query) {
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
  return(result)
}
