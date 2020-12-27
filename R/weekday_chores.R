library(dplyr)

source("analysis.R")
source("database.R")

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
  cat(title, "
    Median:", quantiles[["50%"]], "
    Mean:", mean(sims), "
    95% CI UB:", quantiles[["95%"]], "\n")
  Filter(function (value) {
    value >= xmin & value <= xmax
  }, sims) %>%
    hist(breaks = 100, freq = FALSE, main = title, xlab = paste(title, "duration (minutes)"))
}

analyze.meals <- function (fitted.chore.durations, weekendity) {
  weekend.label <- ifelse(weekendity, "Weekend", "Weekday")
  all.meal.chores <- NULL
  for (meal in c("breakfast", "lunch", "dinner")) {
    meal.chores <- data.frame(chore = c(paste("make", meal), paste("eat", meal), paste(meal, "dishes"), "put away dishes"), aggregate_key = weekendity)
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
  using.database(function (fetch.query.results) {
    "SELECT chore_id
          , chore
          , completions_per_day
          , mean_log_duration_minutes
          , sd_log_duration_minutes
          , mode_duration_minutes
          , median_duration_minutes
          , mean_duration_minutes
          , daily
          , weekendity
          , chore_id IN (SELECT chore_id FROM chore_hierarchy) AS child_chore
        FROM chore_durations_per_day
        WHERE is_active" %>%
      fetch.query.results %>%
      subset(daily == 1 & weekendity == 0 & child_chore == 0) %>%
      expand.many.chore.completions.per.day %>%
      scale.less.than.one.chore.completion.per.day %>%
      sum.chores %>%
      sum.chores.histogram("Weekday chores")
  })
}

if (interactive()) {
  main()
}
