source("log_normal.R")

expand.many.chore.completions.per.day <- function (fitted.chore.durations) {
  # Split up many per day and at most once per day because they need to be dealt with separately
  many.per.day <- subset(fitted.chore.durations, completions_per_day > 1)
  one.or.fewer.per.day <- subset(fitted.chore.durations, completions_per_day <= 1)
  # Repeat chores completed more than once per day
  repeated.chores <- c()
  for (i in 1:nrow(many.per.day)) {
    chore.data <- many.per.day[i,]
    chore.name <- chore.data$chore
    completions.per.day <- chore.data$completions_per_day
    for (. in 1:completions.per.day) {
      repeated.chores <- c(repeated.chores, chore.name)
    }
    if (abs(completions.per.day - round(completions.per.day)) > 0.1) {
      cat(chore.name, "has non-integer completions per day", completions.per.day, "\n")
    }
  }
  # Expand each instance by merging on repeated chores vector
  many.per.day <- merge(many.per.day, data.frame(chore = repeated.chores))
  # Update to once per day as this is now represented through repetition
  many.per.day$completions_per_day <- 1
  # Recombine with chores that have 1 or fewer completions per day
  rbind(many.per.day, one.or.fewer.per.day)
}

scale.less.than.one.chore.completion.per.day <- function (fitted.chore.durations) {
  # Split up less than and at least once per day because they need to be dealt with separately
  less.than.once.per.day <- subset(fitted.chore.durations, completions_per_day < 1)
  at.least.once.per.day <- subset(fitted.chore.durations, completions_per_day >= 1)
  # Scale at most once per day to completions per day
  less.than.once.per.day$mean_log_duration_minutes <- scale.log.normal.mean(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$completions_per_day)
  less.than.once.per.day$mode_duration_minutes <- log.normal.mode(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$sd_log_duration_minutes)
  less.than.once.per.day$median_duration_minutes <- log.normal.median(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$sd_log_duration_minutes)
  less.than.once.per.day$mean_duration_minutes <- log.normal.mean(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$sd_log_duration_minutes)
  # Recombine with chores that have 1 or more completions per day
  rbind(less.than.once.per.day, at.least.once.per.day)
}
