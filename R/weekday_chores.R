library(dplyr)

source("analysis.R")
source("database.R")
source("sum_chores.R")

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
          , chore_durations_per_day.completions_per_day
          , mean_log_duration_minutes
          , sd_log_duration_minutes
          , mode_duration_minutes
          , median_duration_minutes
          , mean_duration_minutes
          , daily
          , weekendity
          , chore_id IN (SELECT chore_id FROM chore_hierarchy) AS child_chore
        FROM chore_durations_per_day
        JOIN chores USING (chore_id)
        WHERE is_active" %>%
      fetch.query.results %>%
      subset(daily == 1 & weekendity == 0 & child_chore == 0) %>%
      expand.many.chore.completions.per.day %>%
      scale.less.than.one.chore.completion.per.day %>%
      sum.chores %>%
      sum.chores.histogram("Weekday chores")
  })
}
