suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(RMariaDB))

connect <- function () {
  settings <- paste(Sys.getenv("HOME"), ".my.cnf", sep = "/")
  dbConnect(MariaDB(), default.file = settings, groups = "clientchores", timezone = Sys.timezone())
}

fetch.query.results <- function (database, query, params) {
  result <- NULL
  withCallingHandlers({
    result <- dbSendQuery(database, query, params)
    fetched <- dbFetch(result)
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    return(fetched %>% as_tibble())
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
    result <- operation(function (query, params = NULL) {
      fetch.query.results(database, query, params)
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
