library(dplyr)

source("database.R")
source("log_normal.R")

sum.chores <- function (fitted.chore.durations) {
  accumulator <- 0
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    if (is.na(sd.log)) {
      cat("Insufficient data to fit distribution for", chore.name, "\n")
      next()
    }
    accumulator <- accumulator + rvlnorm(mean = mean.log, sd = sd.log)
  }
  return(accumulator)
}

sum.chores.histogram <- function (sims, title, left.tail = 0.0001, right.tail = 0.995) {
  quantiles <- quantile(sims, c(0.5, 0.95, left.tail, right.tail))
  xmin <- floor(quantiles[[3]])
  xmax <- ceiling(quantiles[[4]])
  mean.log <- mean(log(sims))
  sd.log <- sd(log(sims))
  cat(title, "
    Mode:", log.normal.mode(mean.log, sd.log), "
    Median:", quantiles[["50%"]], "
    Mean:", mean(sims), "
    95% CI UB:", quantiles[["95%"]], "\n")
  Filter(function (value) {
    value >= xmin & value <= xmax
  }, sims) %>%
    hist(breaks = 100, freq = FALSE, main = title, xlab = paste(title, "duration (minutes)"))
}

query.fitted.chore.durations <- function (fetch.query.results) {
  "SELECT chore_id
        , chores.chore
        , chores.aggregate_by_id
        , aggregate_key
        , mean_log_duration_minutes
        , sd_log_duration_minutes
        , mode_duration_minutes
      FROM chores
      LEFT JOIN chore_durations USING (chore_id)
      WHERE chores.is_active" %>%
    fetch.query.results()
}

main <- function (chore.names) {
  setnsims(1000000)
  using.database(function (fetch.query.results) {
    query.fitted.chore.durations(fetch.query.results)
  }) %>%
    subset(chore %in% chore.names) %>%
    sum.chores() %>%
    sum.chores.histogram("Sum of chores")
}
