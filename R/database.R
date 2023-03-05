suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(RMariaDB))

connect <- function () {
  settings <- paste(Sys.getenv("HOME"), ".my.cnf", sep = "/")
  dbConnect(MariaDB(), default.file = settings, groups = "clientchores", timezone = Sys.timezone())
}

using.database <- function (operation) {
  database <- NULL
  result <- NULL
  withCallingHandlers({
    database <- connect()
    result <- operation(function (query, params = NULL) {
      dbGetQuery(database, query, params = params) %>%
        as_tibble()
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
